////
////  MakeCallKitManager.swift
////  MakeCallSDKFramework
////
////  Created by PHUC on 22/9/25.
////
//
//import Foundation
//import CallKit
//import AVFoundation
//import UIKit
//
//// MARK: - CallKit Manager Protocol
//public protocol MakeCallKitDelegate: AnyObject {
//    func callKitDidStartCall(uuid: UUID)
//    func callKitDidEndCall(uuid: UUID)
//    func callKitDidAnswerCall(uuid: UUID)
//    func callKitDidMute(uuid: UUID, isMuted: Bool)
//    func callKitDidSetSpeaker(uuid: UUID, isEnabled: Bool)
//    func callKitDidFail(error: Error)
//}
//
//// MARK: - CallKit Manager
//public class MakeCallKit: NSObject {
//    
//    // MARK: - Properties
//    private let callProvider: CXProvider
//    private let callController: CXCallController
//    private var currentCallUUID: UUID?
//    
//    public weak var delegate: MakeCallKitDelegate?
//    
//    // MARK: - Initialization
//    public override init() {
//        // Configure CallKit provider
//        let configuration = CXProviderConfiguration()
//        configuration.supportsVideo = false
//        configuration.maximumCallGroups = 1
//        configuration.maximumCallsPerCallGroup = 1
//        configuration.supportedHandleTypes = [.generic]
//        
//        // Audio settings
//        configuration.ringtoneSound = "Ringtone.caf"
//        
//        // Optional: Set app icon for CallKit UI
//        if let image = UIImage(named: "app-icon") {
//            configuration.iconTemplateImageData = image.pngData()
//        }
//        
//        // Create provider and controller
//        callProvider = CXProvider(configuration: configuration)
//        callController = CXCallController()
//        
//        super.init()
//        
//        // Set provider delegate
//        callProvider.setDelegate(self, queue: .main)
//    }
//    
//    // MARK: - Public Methods
//    
//    /// Start outgoing call via CallKit
//    public func startCall(to destination: String, displayName: String? = nil) {
//        let callUUID = UUID()
//        currentCallUUID = callUUID
//        
//        let handle = CXHandle(type: .generic, value: destination)
//        let startCallAction = CXStartCallAction(call: callUUID, handle: handle)
//        
//        // Set display name if provided
//        if let displayName = displayName {
//            startCallAction.contactIdentifier = displayName
//        }
//        
//        let transaction = CXTransaction(action: startCallAction)
//        
//        callController.request(transaction) { [weak self] error in
//            if let error = error {
//                print("❌ CallKit startCall error: \(error)")
//                self?.delegate?.callKitDidFail(error: error)
//            } else {
//                print("✅ CallKit call started successfully")
//            }
//        }
//    }
//    
//    /// Report outgoing call as started
//    public func reportOutgoingCallStarted() {
//        guard let uuid = currentCallUUID else { return }
//        callProvider.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
//    }
//    
//    /// Report outgoing call as connected
//    public func reportOutgoingCallConnected() {
//        guard let uuid = currentCallUUID else { return }
//        callProvider.reportOutgoingCall(with: uuid, connectedAt: Date())
//    }
//    
//    /// Report incoming call
//    public func reportIncomingCall(from caller: String, displayName: String? = nil, completion: @escaping (Error?) -> Void) {
//        let callUUID = UUID()
//        currentCallUUID = callUUID
//        
//        let handle = CXHandle(type: .generic, value: caller)
//        let callUpdate = CXCallUpdate()
//        callUpdate.remoteHandle = handle
//        callUpdate.localizedCallerName = displayName ?? caller
//        callUpdate.hasVideo = false
//        
//        callProvider.reportNewIncomingCall(with: callUUID, update: callUpdate) { [weak self] error in
//            if let error = error {
//                print("❌ CallKit reportIncomingCall error: \(error)")
//                self?.delegate?.callKitDidFail(error: error)
//            } else {
//                print("✅ CallKit incoming call reported successfully")
//            }
//            completion(error)
//        }
//    }
//    
//    /// End call
//    public func endCall() {
//        guard let uuid = currentCallUUID else { return }
//        
//        let endCallAction = CXEndCallAction(call: uuid)
//        let transaction = CXTransaction(action: endCallAction)
//        
//        callController.request(transaction) { [weak self] error in
//            if let error = error {
//                print("❌ CallKit endCall error: \(error)")
//                self?.delegate?.callKitDidFail(error: error)
//            } else {
//                print("✅ CallKit call ended successfully")
//                self?.currentCallUUID = nil
//            }
//        }
//    }
//    
//    /// Report call ended by remote party
//    public func reportCallEnded(reason: CXCallEndedReason = .remoteEnded) {
//        guard let uuid = currentCallUUID else { return }
//        callProvider.reportCall(with: uuid, endedAt: Date(), reason: reason)
//        currentCallUUID = nil
//    }
//    
//    /// Update call with new information
//    public func updateCall(displayName: String? = nil, hasVideo: Bool = false) {
//        guard let uuid = currentCallUUID else { return }
//        
//        let update = CXCallUpdate()
//        if let displayName = displayName {
//            update.localizedCallerName = displayName
//        }
//        update.hasVideo = hasVideo
//        
//        callProvider.reportCall(with: uuid, updated: update)
//    }
//    
//    /// Configure audio session for VoIP
//    public func configureAudioSession() {
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [])
//            try audioSession.setActive(true)
//        } catch {
//            print("❌ Audio session configuration failed: \(error)")
//            delegate?.callKitDidFail(error: error)
//        }
//    }
//    
//    /// Get current call UUID
//    public var currentUUID: UUID? {
//        return currentCallUUID
//    }
//    
//    /// Check if there's an active call
//    public var hasActiveCall: Bool {
//        return currentCallUUID != nil
//    }
//}
//
//// MARK: - CXProviderDelegate
//extension MakeCallKit: CXProviderDelegate {
//    
//    public func providerDidReset(_ provider: CXProvider) {
//        print("🔄 CallKit provider did reset")
//        if let uuid = currentCallUUID {
//            delegate?.callKitDidEndCall(uuid: uuid)
//            currentCallUUID = nil
//        }
//    }
//    
//    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
//        print("📞 CallKit: Starting call")
//        
//        // Configure audio session
//        configureAudioSession()
//        
//        // Report call as started
//        reportOutgoingCallStarted()
//        
//        // Notify delegate
//        delegate?.callKitDidStartCall(uuid: action.callUUID)
//        
//        // Fulfill action
//        action.fulfill()
//    }
//    
//    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
//        print("✅ CallKit: Answering call")
//        
//        // Configure audio session
//        configureAudioSession()
//        
//        // Notify delegate
//        delegate?.callKitDidAnswerCall(uuid: action.callUUID)
//        
//        // Fulfill action
//        action.fulfill()
//    }
//    
//    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
//        print("📵 CallKit: Ending call")
//        
//        // Notify delegate
//        delegate?.callKitDidEndCall(uuid: action.callUUID)
//        
//        // Reset state
//        currentCallUUID = nil
//        
//        // Fulfill action
//        action.fulfill()
//    }
//    
//    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
//        print("🎤 CallKit: Setting mute to \(action.isMuted)")
//        
//        // Notify delegate
//        delegate?.callKitDidMute(uuid: action.callUUID, isMuted: action.isMuted)
//        
//        // Fulfill action
//        action.fulfill()
//    }
//    
//    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
//        print("⏸️ CallKit: Setting hold to \(action.isOnHold)")
//        
//        // Handle hold/unhold if needed
//        action.fulfill()
//    }
//    
//    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
//        print("⏰ CallKit action timed out: \(action)")
//        delegate?.callKitDidFail(error: NSError(domain: "CallKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Action timed out"]))
//        action.fail()
//    }
//    
//    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
//        print("🔊 CallKit: Audio session activated")
//        // Audio session is ready, start audio processing
//    }
//    
//    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
//        print("🔇 CallKit: Audio session deactivated")
//        // Clean up audio processing
//    }
//}
