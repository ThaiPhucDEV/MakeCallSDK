//
//  MakeCallInitializer.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 19/9/25.
//

import Foundation
import AVFoundation
internal import linphonesw


// MARK: - Linphone Core Initializer
public class MakeCallInitializer {
    
    // MARK: - Properties
    private let eventManager = MakeCallEventManager.shared
    
    // MARK: - Public Methods
    
    /// Initialize Linphone Core with configuration
    internal func initializeCore(config: CallConfig) throws -> Core {
        
        // Setup audio session first
        try setupAudioSession()
        
        // Create Linphone core
        let core = try createLinphoneCore()
        
        // Configure core settings
        configureCore(core, with: config)
        
        // Configure audio settings
        configureAudioSettings(core)
        
        // Start core
        try core.start()
        
        print("✅ Linphone Core initialized successfully")
        return core
    }
    
    /// Register SIP account
    internal func registerAccount(core: Core, config: CallConfig) throws {
        print("🔧 Start SIP registration with config:")
        print("   - ext: \(config.ext)")
        print("   - domain: \(config.domain)")
        print("   - proxy: \(config.sipProxy):\(config.port)")

        // Tạo AuthInfo (username + password)
        let authInfo = try Factory.Instance.createAuthInfo(
            username: config.ext,
            userid: nil,
            passwd: config.password,
            ha1: nil,
            realm: nil,
            domain: config.domain
        )
        core.addAuthInfo(info: authInfo)
        print("✅ Auth info added")

        // 🔑 Identity (sip:<user>@<domain>)
        let identityAddr = try Factory.Instance.createAddress(addr: "sip:\(config.ext)@\(config.domain)")
        
      
        
        let proxyAddr = try Factory.Instance.createAddress(
            addr: "sip:\(config.sipProxy):\(config.port);transport=\(config.transport)"
        )

        // Tạo AccountParams từ core
        let accountParams = try core.createAccountParams()

        // ⚡️ Gán identity & server thông qua helper method
        try accountParams.setIdentityaddress(newValue: identityAddr)
        try accountParams.setServeraddress(newValue: proxyAddr)
        
        
        // Nếu bạn muốn luôn gửi qua proxy (tránh DNS SRV lookup fail)
        accountParams.outboundProxyEnabled = true

        // Bật auto register
        accountParams.registerEnabled = true
        accountParams.expires = 3600

        print("✅ Identity: \(identityAddr.asStringUriOnly())")
        print("✅ Server: \(proxyAddr.asStringUriOnly())")

        // Tạo account và add vào core
 
        let account = try core.createAccount(params: accountParams)
        try core.addAccount(account: account)
           core.defaultAccount = account
       

        print("✅ SIP Account registration initiated")
    }


    
    // MARK: - Private Methods
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord,
                                       mode: .voiceChat,
                                       options: [.allowBluetooth, .mixWithOthers])
            try audioSession.setActive(true)
            
            print("✅ Audio session configured")
        } catch {
            let sdkError = MakeCallSDKError.audioSessionFailed(error.localizedDescription)
            eventManager.postError(sdkError)
            throw sdkError
        }
    }
    
    private func createLinphoneCore() throws -> Core {
        do {
            let factory = Factory.Instance
            let core = try factory.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
            
            print("✅ Linphone Core created")
            return core
        } catch {
            let sdkError = MakeCallSDKError.coreSetupFailed(error.localizedDescription)
            eventManager.postError(sdkError)
            throw sdkError
        }
    }
    
    private func configureCore(_ core: Core, with config: CallConfig) {
        
        // Configure transports
        if let transports = core.transports {
            transports.udpPort = config.transport == "udp" ? config.port : 0
            transports.tcpPort = config.transport == "tcp" ? config.port : 0
            transports.tlsPort = config.transport == "tls" ? config.port : 0
            transports.dtlsPort = 0 // tắt DTLS nếu không dùng
        }

      
        
      //  core.pushNotificationEnabled = true
      //  core.callkitEnabled = true
     //   core.incTimeout = 60  // Incoming call timeout = 60s ⇒ hết thời gian nếu không bắt máy.
     //   core.nortpTimeout = 30 // Nếu 30s không có RTP ⇒ Linphone tự ngắt call (chống treo).
     //   core.audioJittcomp = 100 // 100ms jitter buffer.

        // Disable video completely
        core.videoDisplayEnabled = false
        core.videoCaptureEnabled = false
   //     core.videoEnabled = false
        
        // Enable echo cancellation
        core.echoCancellationEnabled = true
        
        // Set adaptive rate control
        core.adaptiveRateControlEnabled = true
        
        // Keep alive settings
        core.keepAliveEnabled = true
     //   core.keepAliveInterval = 25000 // 25 seconds
        core.setUserAgent(name: "MakeCallSDK", version: "1.0.0")

        print("✅ Core settings configured")
    }
    
    private func configureAudioSettings(_ core: Core) {
        
        let audioCodecs = core.audioPayloadTypes
        
        for codec in audioCodecs {
            let mimeType = codec.mimeType.lowercased()
            
            switch mimeType {
            case "opus":
                codec.enable(enabled: true)
                codec.normalBitrate = 64000 // 64 kbps
                print("✅ Opus codec enabled (64 kbps)")
                
            case "pcmu":
                codec.enable(enabled: true)
                print("✅ PCMU codec enabled")
                
            case "pcma":
                codec.enable(enabled: true)
                print("✅ PCMA codec enabled")
                
            case "g722":
                codec.enable(enabled: true)
                print("✅ G722 codec enabled")
                
            default:
                codec.enable(enabled: false)
             //   print("❌ Disabled codec: \(mimeType)")
            }
        }
        
        print("✅ Audio codecs configured")
    }
}

// MARK: - Core Extensions
internal extension Core {
    
    /// Get current registration status
    var isRegistered: Bool {
        guard let account = defaultAccount else { return false }
        return account.state == .Ok
    }
    
    /// Get audio codec information
    var enabledAudioCodecs: [String] {
        return audioPayloadTypes
            .filter { $0.enabled() }
            .map { $0.mimeType }
    }
    
    /// Clean shutdown
    func cleanShutdown() {
        do {
            // Stop core
            stop()
            
            // Clear accounts
            clearAllAuthInfo()
            clearAccounts()
            
            print("✅ Linphone Core shutdown completed")
        }
    }
}
