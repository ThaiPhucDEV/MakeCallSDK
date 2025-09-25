//
//  MakeCallSDK.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 19/9/25.
//

import Foundation
import UIKit
import AVFoundation
internal import linphonesw

import CallKit

// MARK: - Main SDK Class
public class MakeCallSDK {
    
    // MARK: - Properties
    private var core: Core?
    private var currentCall: Call?
    private var config: CallConfig?
    private var currentCallUUID: UUID?
    
    
    // Components
    private let initializer = MakeCallInitializer()
    private let coreListener = MakeCallCoreListener()
    private let audioListener = MakeCallAudioListener()
    private let networkListener = MakeCallNetworkListener()
    
    // UI
    private var callViewController: CallViewController?
    
    // State
    private var isSpeakerEnabled = false
    private var isMicrophoneEnabled = true
    
    // MARK: - Singleton
    public static let shared = MakeCallSDK()
    
    
    // UI Custom
    private var customCallUI: CallUIProtocol?
    
    private init() {
        setupListeners()
    }
    
    deinit {
        print("deinit SDK")
        cleanup()
    }
    
    
    /// Người dùng có thể truyền UI custom của họ
    public func setCustomCallUI(_ customUI: CallUIProtocol?) {
        self.customCallUI = customUI
    }
    
    
    
    // MARK: - Public API
    
    /// Initialize SDK with SIP configuration
    public func initialize(config: CallConfig) {
        self.config = config
        
        do {
            // Initialize Linphone core
            core = try initializer.initializeCore(config: config)
            
            core?.addDelegate(delegate: coreListener)
            
            // Register SIP account
            try initializer.registerAccount(core: core!, config: config)
            
            print("✅ MakeCallSDK initialized successfully")
            
        } catch let error as MakeCallSDKError {
            MakeCallEventManager.shared.postError(error)
        } catch {
            let sdkError = MakeCallSDKError.coreSetupFailed(error.localizedDescription)
            MakeCallEventManager.shared.postError(sdkError)
        }
    }
    func startSIPCall(to destination: String, uuid: UUID) {
        guard let core = core, let config = config else {
            MakeCallEventManager.shared.postError(.notInitialized)
            return
        }
        
        let address = "sip:\(destination)@\(config.domain)"
        
        do {
            guard let remoteAddress = try? Factory.Instance.createAddress(addr: address) else {
                MakeCallEventManager.shared.postError(.invalidAddress(address))
                return
            }
            
            let callParams = try core.createCallParams(call: nil)
            // Ví dụ thêm DID vào custom SIP header
            callParams.addCustomHeader(headerName: "X-DID", headerValue: config.didNumber)
            
            currentCall = core.inviteAddressWithParams(addr: remoteAddress, params: callParams)
            
            if currentCall != nil {
                print("📞 SIP call started to \(destination) with UUID \(uuid)")
            } else {
                MakeCallEventManager.shared.postError(.callCreationFailed("Failed to create call"))
            }
        } catch {
            MakeCallEventManager.shared.postError(.callCreationFailed(error.localizedDescription))
        }
    }
    /// Make outbound call
    public func makeCall(to destination: String) {
        guard let core = core, let config = config else {
            MakeCallEventManager.shared.postError(.notInitialized)
            return
        }
        
        guard core.isRegistered else {
            MakeCallEventManager.shared.postError(.notRegistered)
            return
        }
        
        showCallUI(destination: destination)
        
        
        //  Tạo UUID cho CallKit + SIP
        let uuid = UUID()
        currentCallUUID = uuid
        startSIPCall(to: destination, uuid: uuid)
      
         // Gọi CallKit UI
        //        CallKitManager.shared.startCall(to: destination, uuid: uuid)
        
        
        
    }
    
    
    
    /// Toggle speaker on/off
    public func toggleSpeaker() {
        isSpeakerEnabled.toggle()
        updateAudioRoute()
        MakeCallEventManager.shared.postAudioRouteChanged(isSpeakerEnabled: isSpeakerEnabled)
    }
    
    /// Toggle microphone mute/unmute
    public func toggleMicrophone() {
        isMicrophoneEnabled.toggle()
        currentCall?.microphoneMuted = !isMicrophoneEnabled
        MakeCallEventManager.shared.postMicrophoneStateChanged(isMuted: !isMicrophoneEnabled)
    }
    
    /// End current call
    public func hangup() {
        
        guard let call = currentCall else { return }
        
        do {
            try call.terminate()
            currentCall = nil
            print("📵 Call terminated")
            
            // Đóng màn hình gọi (nếu đang present)
            //            if let topVC = UIApplication.shared.windows.first?.rootViewController?.presentedViewController {
            //                topVC.dismiss(animated: true, completion: nil)
            //            }
        } catch {
            let sdkError = MakeCallSDKError.callTerminationFailed(error.localizedDescription)
            MakeCallEventManager.shared.postError(sdkError)
        }
    }
    
    
    
    
    
    /// Get current registration status
    public var isRegistered: Bool {
        return core?.isRegistered ?? false
    }
    
    /// Get current call state
    public var currentCallState: CallState {
        guard let call = currentCall else { return .idle }
        
        switch call.state {
        case .OutgoingInit: return .calling
        case .OutgoingRinging: return .ringing
        case .Connected: return .connected
        case .End, .Released: return .ended
        case .Error: return .error
        default: return .idle
        }
    }
    
    /// Add event observer
    public func addObserver(_ observer: MakeCallEventObserver) {
        MakeCallEventManager.shared.addObserver(observer)
    }
    
    /// Remove event observer
    public func removeObserver(_ observer: MakeCallEventObserver) {
        MakeCallEventManager.shared.removeObserver(observer)
    }
    
    /// Legacy delegate support
    private var delegateBridge: MakeCallDelegateBridge?
    public var delegate: MakeCallSDKDelegate? {
        didSet {
            if let delegate = delegate {
                delegateBridge = MakeCallDelegateBridge(delegate: delegate)
            } else {
                delegateBridge = nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupListeners() {
        audioListener.startListening()
        networkListener.startNetworkMonitoring()
        
        // Listen to call state changes to handle UI
        MakeCallEventManager.shared.addObserver(self)
    }
    
    private func updateAudioRoute() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if isSpeakerEnabled {
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                try audioSession.overrideOutputAudioPort(.none)
            }
        } catch {
            let sdkError = MakeCallSDKError.audioSessionFailed(error.localizedDescription)
            MakeCallEventManager.shared.postError(sdkError)
        }
    }
    
    private func showCallUI(destination: String? = nil) {
        DispatchQueue.main.async {
            if let customUI = self.customCallUI {
                // Nếu người dùng đã truyền UI custom
                customUI.delegate = self
                if let dest = destination {
                    customUI.updateCallerInfo(name: dest, avatar: nil)
                }
                self.callViewController = nil // không dùng UI mặc định
            } else {
                // Nếu không có UI custom thì dùng UI mặc định
                if self.callViewController == nil {
                    self.callViewController = CallViewController()
                    self.callViewController?.delegate = self

                    if let dest = destination {
                        self.callViewController?.updateCallerInfo(name: dest, avatar: nil)
                    }

                    if #available(iOS 13.0, *) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            self.callViewController?.modalPresentationStyle = .fullScreen
                            window.rootViewController?.present(self.callViewController!, animated: true)
                        }
                    }
                }
            }
        }
    }

    private func cleanupCallUI() {
        currentCall = nil
        currentCallUUID = nil
        enableProximityMonitoring(false)
        
        DispatchQueue.main.async {
            if let customUI = self.customCallUI {
                customUI.dismiss()
            } else {
                self.hideCallUI()
            }
        }
    }

    private func hideCallUI() {
        DispatchQueue.main.async {
            self.callViewController?.dismiss(animated: true) {
                self.callViewController = nil
            }
        }
    }
    
    private func cleanup() {
        // Stop listeners
        audioListener.stopListening()
        networkListener.stopNetworkMonitoring()
        
        // Remove observers
        MakeCallEventManager.shared.removeObserver(self)
        MakeCallEventManager.shared.removeAllObservers()
        
        // Cleanup core
        core?.cleanShutdown()
        core = nil
        
        // Reset state
        currentCall = nil
        callViewController = nil
        isSpeakerEnabled = false
        isMicrophoneEnabled = true
        
        print("🧹 MakeCallSDK cleanup completed")
    }
    
    
}

// MARK: - Event Observer Implementation
extension MakeCallSDK: MakeCallEventObserver {
    
    public func handleEvent(_ event: MakeCallEvent) {
        switch event {
        case .callStateChanged(let state):
            handleCallStateChange(state)
        case .error(let error):
            print("❌ SDK Error: \(error.localizedDescription)")
        case .audioRouteChanged(let isSpeakerEnabled):
            callViewController?.updateSpeakerButton(enabled: isSpeakerEnabled)
        case .microphoneStateChanged(let isMuted):
            callViewController?.updateMicButton(enabled: !isMuted)
        default:
            break
        }
    }
    
    private func handleCallStateChange(_ state: CallState) {
        print("📞 Call state changed: \(state)")
        guard let uuid = currentCallUUID else { return }
        
        switch state {
        case .calling:
            enableProximityMonitoring(true)   //   bật khi đang gọi
        case .connected:
            CallKitManager.shared.reportConnected(uuid: uuid)
        case .ended:
            // cuộc gọi kết thúc bình thường (bên kia cúp hoặc mình cúp)
            CallKitManager.shared.reportEnded(uuid: uuid, reason: .remoteEnded)
            cleanupCallUI()
            
        case .error:
            // lỗi cuộc gọi (Busy Here, Timeout, Network fail...)
            CallKitManager.shared.reportEnded(uuid: uuid, reason: .failed)
            cleanupCallUI()
    
            
        default:
            break
        }
    }
    
    private func enableProximityMonitoring(_ enabled: Bool) {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = enabled
        
        if enabled {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(proximityStateChanged),
                name: UIDevice.proximityStateDidChangeNotification,
                object: device
            )
        } else {
            NotificationCenter.default.removeObserver(
                self,
                name: UIDevice.proximityStateDidChangeNotification,
                object: device
            )
        }
    }
    
    @objc private func proximityStateChanged(notification: Notification) {
        let device = UIDevice.current
        if device.proximityState {
        //    print("📱 Proximity detected: màn hình tắt")
        } else {
         //   print("📱 Proximity ended: màn hình bật lại")
        }
    }
    
    
    
}

public protocol CallUIProtocol: AnyObject {
    func updateCallerInfo(name: String, avatar: UIImage?)
    func updateSpeakerButton(enabled: Bool)
    func updateMicButton(enabled: Bool)
    func dismiss()
    var delegate: CallViewControllerDelegate? { get set }
}



// MARK: - Call View Controller Delegate
extension MakeCallSDK: CallViewControllerDelegate {
    /// Handle keypad button tap - Show DTMF keypad for sending tones during call
    public func didTapKeypad() {
        
        
        //  showDTMFKeypad()
    }
    
    public func didTapHangup() {
        hangup()
    }
    
    public func didTapSpeaker() {
        toggleSpeaker()
    }
    
    public func didTapMicrophone() {
        toggleMicrophone()
    }
}
// MARK: - CallKit Manager
class CallKitManager: NSObject {
    static let shared = CallKitManager()
    
    private let provider: CXProvider
    private let callController = CXCallController()
    
    override init() {
        let config = CXProviderConfiguration(localizedName: "MakeCall")
        config.includesCallsInRecents = true
        config.supportsVideo = false
        
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber]
        if #available(iOS 13.0, *) {
            config.iconTemplateImageData = UIImage(systemName: "phone")?.pngData()
        } else {
            // Fallback on earlier versions
            
            print("❌ Start call error:")
        }
        
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    func reportOutgoing(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
    }
    func reportConnected(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, connectedAt: Date())
    }
    
    func reportEnded(uuid: UUID, reason: CXCallEndedReason) {
        provider.reportCall(with: uuid, endedAt: Date(), reason: reason)
    }
    func startCall(to destination: String, uuid: UUID, displayName: String? = nil) {
        let handle: CXHandle
        if let name = displayName {
            handle = CXHandle(type: .generic, value: name) // hiển thị tên thay số
        } else {
            handle = CXHandle(type: .phoneNumber, value: destination) // hiển thị số
        }
        
        let startAction = CXStartCallAction(call: uuid, handle: handle)
        let transaction = CXTransaction(action: startAction)
        requestTransaction(transaction)
    }
    
    
    func endCall(callUUID: UUID) {
        let endAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endAction)
        requestTransaction(transaction)
    }
    
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("❌ CallKit transaction failed: \(error.localizedDescription)")
            } else {
                print("✅ CallKit transaction successful")
            }
        }
    }
}

extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("🔄 CallKit reset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("📞 CallKit start call for: \(action.handle.value)")
        
        // Gọi SIP call qua SDK
        MakeCallSDK.shared.startSIPCall(to: action.handle.value, uuid: action.callUUID)
        
        action.fulfill()
        reportOutgoing(uuid: action.callUUID)
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("📵 CallKit end call")
        
        MakeCallSDK.shared.hangup()
        action.fulfill()
    }
}
