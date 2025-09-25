//
//  CallConfig.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 19/9/25.
//

import Foundation


// MARK: - Call Configuration
public struct CallConfig {
    public let ext: String
    public let password: String
    public let domain: String
    public let sipProxy: String
    public let port: Int
    public let transport: String // udp, tcp, tls, wss
    public let didNumber: String?
    public init(ext: String, password: String, domain: String, sipProxy: String, port: Int,    transport: String = "wss",  didNumber: String? = nil) {
        self.ext = ext
        self.password = password
        self.domain = domain
        self.sipProxy = sipProxy
        self.port = port
        self.transport = transport
        self.didNumber = didNumber
    }
}

// MARK: - Call State Enum
public enum CallState: Equatable {
    case idle
    case calling
    case ringing
    case connected
    case ended
    case error
    case busy
    case noAnswer
    case unowned
   
}

// MARK: - Registration State (Public SDK enum, separate from Linphone's internal enum)
public enum RegistrationStateSDK: Equatable {
    case none
    case progress
    case ok
    case cleared
    case failed(String)
}


// MARK: - SDK Error Types
public enum MakeCallSDKError: Error {
    case notInitialized
    case notRegistered
    case invalidAddress(String)
    case callCreationFailed(String)
    case coreSetupFailed(String)
    case registrationFailed(String)
    case audioSessionFailed(String)
    case callTerminationFailed(String)
    
    public var localizedDescription: String {
        switch self {
        case .notInitialized:
            return "SDK not initialized"
            
        case .notRegistered:
            return "SIP account not registered"
            
        case .invalidAddress(let address):
            print("❌ Invalid address: \(address)") // log cho dev
            return "Invalid destination address"
            
        case .callCreationFailed(let reason):
            print("❌ Failed to create call: \(reason)")
            return "Failed to create call"
            
        case .coreSetupFailed(let reason):
            print("❌ Failed to setup Linphone core: \(reason)")
            return "Failed to setup Linphone core"
            
        case .registrationFailed(let reason):
            print("❌ SIP registration failed: \(reason)")
            return "SIP registration failed"
            
        case .audioSessionFailed(let reason):
            print("🎧 Audio session error: \(reason)")
            return "Audio session error"
            
        case .callTerminationFailed(let reason):
            print("📵 Failed to terminate call: \(reason)")
            return "Failed to terminate call"
        }
    }

}
