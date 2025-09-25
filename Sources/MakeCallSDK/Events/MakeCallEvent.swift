//
//  MakeCallEvent.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 19/9/25.
//

import Foundation

// MARK: - Event Types
public enum MakeCallEvent {
    case registrationStateChanged(RegistrationStateSDK)
    case callStateChanged(CallState)
    case error(MakeCallSDKError)
    case audioRouteChanged(isSpeakerEnabled: Bool)
    case microphoneStateChanged(isMuted: Bool)
    case networkStateChanged(isReachable: Bool)
}

// MARK: - Observer Protocol
public protocol MakeCallEventObserver: AnyObject {
    func handleEvent(_ event: MakeCallEvent)
}

// MARK: - Event Manager
public class MakeCallEventManager {
    
    // MARK: - Properties
    private var observers: [WeakObserver] = []
    private let queue = DispatchQueue(label: "MakeCallEventManager", qos: .utility)
     private var lastNetworkState: Bool?
    // MARK: - Singleton
    public static let shared = MakeCallEventManager()
    
    private init() {}
    
    // MARK: - Observer Management
    
    /// Add observer to receive events
    public func addObserver(_ observer: MakeCallEventObserver) {
        queue.async {
            // Remove nil observers first
            self.observers = self.observers.compactMap { $0.observer != nil ? $0 : nil }
            
            // Add new observer if not already exists
            if !self.observers.contains(where: { $0.observer === observer }) {
                self.observers.append(WeakObserver(observer: observer))
                print("🎯 Added observer: \(type(of: observer))")
            }
        }
    }
    
    /// Remove observer
    public func removeObserver(_ observer: MakeCallEventObserver) {
        queue.async {
            self.observers = self.observers.filter { $0.observer !== observer }
            print("🎯 Removed observer: \(type(of: observer))")
        }
    }
    
    /// Remove all observers
    public func removeAllObservers() {
        queue.async {
            self.observers.removeAll()
            print("🎯 Removed all observers")
        }
    }
    
    // MARK: - Event Broadcasting
    
    /// Post event to all observers
    public func postEvent(_ event: MakeCallEvent) {
        queue.async {
            // Clean up nil observers
            self.observers = self.observers.compactMap { $0.observer != nil ? $0 : nil }
            
            // Notify all observers on main queue
            DispatchQueue.main.async {
                self.observers.forEach { weakObserver in
                    weakObserver.observer?.handleEvent(event)
                }
                
                self.logEvent(event)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Post registration state change
    public func postRegistrationStateChanged(_ state: RegistrationStateSDK) {
        postEvent(.registrationStateChanged(state))
    }
    
    /// Post call state change
    public func postCallStateChanged(_ state: CallState) {
        postEvent(.callStateChanged(state))
    }
    
    /// Post error
    public func postError(_ error: MakeCallSDKError) {
        postEvent(.error(error))
    }
    
    /// Post audio route change
    public func postAudioRouteChanged(isSpeakerEnabled: Bool) {
        postEvent(.audioRouteChanged(isSpeakerEnabled: isSpeakerEnabled))
    }
    
    /// Post microphone state change
    public func postMicrophoneStateChanged(isMuted: Bool) {
        postEvent(.microphoneStateChanged(isMuted: isMuted))
    }
    
    /// Post network state change
    public func postNetworkStateChanged(isReachable: Bool) {
      //  self.postEvent(.networkStateChanged(isReachable: isReachable))
        queue.async {
                   // Chỉ gửi event khi trạng thái thực sự thay đổi
                   if self.lastNetworkState != isReachable {
                       self.lastNetworkState = isReachable
                       self.postEvent(.networkStateChanged(isReachable: isReachable))
                   }
               }
       
    }
    
    // MARK: - Private Methods
    
    private func logEvent(_ event: MakeCallEvent) {
        #if DEBUG
        let eventDescription: String
        switch event {
        case .registrationStateChanged(let state):
            eventDescription = "📝 Registration: \(state)"
        case .callStateChanged(let state):
            eventDescription = "📞 Call: \(state)"
        case .error(let error):
            eventDescription = "❌ Error: \(error.localizedDescription)"
        case .audioRouteChanged(let isSpeakerEnabled):
            eventDescription = "🔊 Audio: Speaker \(isSpeakerEnabled ? "ON" : "OFF")"
        case .microphoneStateChanged(let isMuted):
            eventDescription = "🎤 Microphone: \(isMuted ? "MUTED" : "UNMUTED")"
        case .networkStateChanged(let isReachable):
            eventDescription = "🌐 Network: \(isReachable ? "REACHABLE" : "UNREACHABLE")"
        }
        
        print("🎯 Event: \(eventDescription) -> \(observers.count) observers")
        #endif
    }
}

// MARK: - Weak Observer Wrapper
private class WeakObserver {
    weak var observer: MakeCallEventObserver?
    
    init(observer: MakeCallEventObserver) {
        self.observer = observer
    }
}

// MARK: - Legacy Delegate Support (Optional)
public protocol MakeCallSDKDelegate: AnyObject {
    func onRegistered()
    func onCallStateChanged(state: CallState)
    func onError(error: String)
}

// MARK: - Delegate Bridge (converts new events to old delegate pattern)
public class MakeCallDelegateBridge: MakeCallEventObserver {
    
    public weak var delegate: MakeCallSDKDelegate?
    
    public init(delegate: MakeCallSDKDelegate) {
        self.delegate = delegate
        MakeCallEventManager.shared.addObserver(self)
    }
    
    deinit {
        MakeCallEventManager.shared.removeObserver(self)
    }
    
    public func handleEvent(_ event: MakeCallEvent) {
        switch event {
        case .registrationStateChanged(let state):
            if case .ok = state {
                delegate?.onRegistered()
            }
        case .callStateChanged(let callState):
            delegate?.onCallStateChanged(state: callState)
        case .error(let error):
            delegate?.onError(error: error.localizedDescription)
        default:
            break
        }
    }
}
