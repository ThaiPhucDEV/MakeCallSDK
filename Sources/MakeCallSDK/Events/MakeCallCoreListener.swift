//
//  MakeCallCoreListener.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 19/9/25.
//

import Foundation

import AVFoundation
internal import linphonesw
  
import SystemConfiguration

 
// MARK: - Core Events Listener
internal class MakeCallCoreListener: CoreDelegate {
    
    // MARK: - Properties
    private let eventManager = MakeCallEventManager.shared
    
    // MARK: - Core Delegate Methods
    
    internal func onAccountRegistrationStateChanged(core: Core, account: Account,
                                                    state: RegistrationState, 
                                                    message: String) {
        print("RegistrationState: \(state)")
        let registrationState: RegistrationStateSDK
        
        switch state {
           case .Ok:
               registrationState = .ok
               print("✅ SIP Registration successful")
               
           case .Failed:
               registrationState = .failed(message)
               print("❌ SIP Registration failed: \(message)")
               
           case .Progress:
               registrationState = .progress
               print("🔄 SIP Registration in progress...")
               
           case .Cleared:
               registrationState = .cleared
               print("📤 SIP Registration cleared")
               
           default:
               registrationState = .none
               print("🔄 SIP Registration state: \(state)")
           }
        // Gửi event ra ngoài SDK
        eventManager.postRegistrationStateChanged(registrationState)
    }
    
    internal func onCallStateChanged(core: Core, call: Call, state: Call.State, message: String) {
        let callState: CallState
        print("📞 Call onCallStateChanged  : state:\(state) | message:\(message)")

        switch state {
        case   .OutgoingInit, .OutgoingProgress, .OutgoingEarlyMedia:
            callState = .calling
            print("📞 Call initiating/progress/early media…")

        case .OutgoingRinging:
            callState = .ringing
            print("📱 Call ringing...")

        case .Connected, .StreamsRunning:
                callState = .connected
                print("🟢 Call connected")

        case .End, .Released:
            callState = .ended
            print("📵 Call ended")

        case .Error:
            if message.contains("Busy")   {
                // Phân biệt busy
                callState = .busy
                print("🚫 Call busy: \(message)")
            }
            else if message.contains("Timeout") || message.contains("Request Timeout") {
                    callState = .noAnswer
                    print("⏰ Call no answer: \(message)")
                }
            else {
                callState = .error
                print("❌ Call error: \(message)")
                
                // chỉ post error. thật sự
                let error = MakeCallSDKError.callCreationFailed(message)
                eventManager.postError(error)
            }

        default:
            callState = .idle
            print("🔄 Call state: \(state)")
        }

       
        
        eventManager.postCallStateChanged(callState)

         
        
    }

    
    internal func onNetworkReachable(core: Core, reachable: Bool) {
        eventManager.postNetworkStateChanged(isReachable: reachable)
        
        if reachable {
            print("🌐 Network reachable")
        } else {
            print("🌐 Network unreachable")
            let error = MakeCallSDKError.callCreationFailed("Network unreachable")
            eventManager.postError(error)
        }
    }
    
    internal func onCallStatsUpdated(core: Core, call: Call, stats: CallStats) {
        // Optional: Monitor call quality
        logCallStats(stats)
    }
    
    internal func onGlobalStateChanged(core: Core, gstate: GlobalState, message: String) {
        print("🌍 Global state changed: \(gstate) - \(message)")
        
        if gstate == .Shutdown {
            print("🔄 Linphone core shutting down")
        }
    }
    
    // MARK: - Private Methods
    
    private func logCallStats(_ stats: CallStats) {
        #if DEBUG
        if let audioStats = stats as? CallStats {
            print("📊 Call Stats:")
            print("   - Download Bandwidth: \(audioStats.downloadBandwidth) kbps")
            print("   - Upload Bandwidth: \(audioStats.uploadBandwidth) kbps")
            print("   - Jitter: \(audioStats.jitterBufferSizeMs) ms")
            print("   - Late Packets: \(audioStats.latePacketsCumulativeNumber)")
        }
        #endif
    }
}

// MARK: - Audio Events Listener
internal class MakeCallAudioListener {
    
    // MARK: - Properties
    private let eventManager = MakeCallEventManager.shared
    private var audioSessionObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    public init() {
        setupAudioSessionObserver()
    }
    
    deinit {
        removeAudioSessionObserver()
    }
    
    // MARK: - Public Methods
    
    /// Start listening to audio events
    internal func startListening() {
        setupAudioSessionObserver()
        print("🎧 Audio listener started")
    }
    
    /// Stop listening to audio events
    internal func stopListening() {
        removeAudioSessionObserver()
        print("🎧 Audio listener stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSessionObserver() {
        // Remove existing observer
        removeAudioSessionObserver()
        
        // Add new observer for route changes
        audioSessionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioRouteChange(notification)
        }
    }
    
    private func removeAudioSessionObserver() {
        if let observer = audioSessionObserver {
            NotificationCenter.default.removeObserver(observer)
            audioSessionObserver = nil
        }
    }
    
    private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let isSpeakerActive = currentRoute.outputs.contains { output in
            output.portType == .builtInSpeaker
        }
        
        switch reason {
        case .newDeviceAvailable:
            print("🎧 New audio device available")
        case .oldDeviceUnavailable:
            print("🎧 Audio device unavailable")
        case .categoryChange:
            print("🎧 Audio category changed")
        case .override:
            print("🎧 Audio route overridden")
            eventManager.postAudioRouteChanged(isSpeakerEnabled: isSpeakerActive)
        default:
            print("🎧 Audio route changed: \(reason)")
        }
    }
}

// MARK: - Network Events Listener
internal class MakeCallNetworkListener {
    
    // MARK: - Properties
    private let eventManager = MakeCallEventManager.shared
    private var reachability: NetworkReachability?
    
    // MARK: - Initialization
    public init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        stopNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start network monitoring
    internal func startNetworkMonitoring() {
        setupNetworkMonitoring()
        print("🌐 Network monitoring started")
    }
    
    /// Stop network monitoring
    internal func stopNetworkMonitoring() {
        reachability?.stopNotifier()
        reachability = nil
        print("🌐 Network monitoring stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        do {
            reachability = try NetworkReachability(hostname: "8.8.8.8")
            
            reachability?.whenReachable = { [weak self] reachability in
            //    print("🌐 Network became reachable via \(reachability.connection)")
                self?.eventManager.postNetworkStateChanged(isReachable: true)
            }
            
            reachability?.whenUnreachable = { [weak self] _ in
                print("🌐 Network became unreachable")
                self?.eventManager.postNetworkStateChanged(isReachable: false)
            }
            
            try reachability?.startNotifier()
            
        } catch {
            print("❌ Unable to start network reachability notifier: \(error)")
            eventManager.postError(.callCreationFailed("Failed to start network monitoring: \(error.localizedDescription)"))
        }
    }
}

// MARK: - Simple Network Reachability (Basic Implementation)
internal class NetworkReachability {
    
    internal enum Connection {
        case unavailable, wifi, cellular
    }
    
    internal var whenReachable: ((NetworkReachability) -> Void)?
    internal var whenUnreachable: ((NetworkReachability) -> Void)?
    
    internal var connection: Connection {
        return .wifi // Simplified - in real implementation use SystemConfiguration
    }
    
    private let hostname: String
    private var timer: Timer?
    
    internal init(hostname: String) throws {
        self.hostname = hostname
    }
    
    internal func startNotifier() throws {
        // Simplified implementation - check connectivity periodically
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkConnectivity()
        }
        
        // Initial check
        checkConnectivity()
    }
    
    internal func stopNotifier() {
        timer?.invalidate()
        timer = nil
    }
    
  

    private func checkConnectivity() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            whenUnreachable?(self)
            return
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            whenUnreachable?(self)
            return
        }
        
        let isReachable = flags.contains(.reachable) && !flags.contains(.connectionRequired)
        
        if isReachable {
            whenReachable?(self)
        } else {
            whenUnreachable?(self)
        }
    }

}
