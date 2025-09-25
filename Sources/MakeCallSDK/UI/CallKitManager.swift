//
//  CallKitManager.swift
//  MakeCallSDKFramework
//
//  Created by PHUC on 22/9/25.
//

//import CallKit
//
//class CallKitManager: NSObject {
//    static let shared = CallKitManager()
//    
//    private let provider: CXProvider
//    private let callController = CXCallController()
//    
//    override init() {
//        let config = CXProviderConfiguration(localizedName: "MakeCall")
//        config.supportsVideo = false
//        config.maximumCallsPerCallGroup = 1
//        config.supportedHandleTypes = [.phoneNumber]
//        config.iconTemplateImageData = UIImage(systemName: "phone")?.pngData()
//        
//        provider = CXProvider(configuration: config)
//        
//        super.init()
//        provider.setDelegate(self, queue: nil)
//    }
//    
//    func startCall(to destination: String) {
//        let handle = CXHandle(type: .phoneNumber, value: destination)
//        let startAction = CXStartCallAction(call: UUID(), handle: handle)
//        let transaction = CXTransaction(action: startAction)
//        
//        requestTransaction(transaction)
//    }
//    
//    func endCall(callUUID: UUID) {
//        let endAction = CXEndCallAction(call: callUUID)
//        let transaction = CXTransaction(action: endAction)
//        requestTransaction(transaction)
//    }
//    
//    private func requestTransaction(_ transaction: CXTransaction) {
//        callController.request(transaction) { error in
//            if let error = error {
//                print("❌ CallKit transaction failed: \(error.localizedDescription)")
//            } else {
//                print("✅ CallKit transaction successful")
//            }
//        }
//    }
//}
//
//extension CallKitManager: CXProviderDelegate {
//    func providerDidReset(_ provider: CXProvider) {
//        print("🔄 CallKit reset")
//    }
//    
//    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
//        print("📞 CallKit start call triggered for: \(action.handle.value)")
//        
//        // ✅ Khi CallKit UI báo "Start Call", mình sẽ gọi SIP
//        MakeCallSDK.shared.startSIPCall(to: action.handle.value, uuid: action.callUUID)
//        
//        action.fulfill()
//    }
//    
//    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
//        print("📵 CallKit end call triggered")
//        
//        MakeCallSDK.shared.hangup()
//        
//        action.fulfill()
//    }
//}
