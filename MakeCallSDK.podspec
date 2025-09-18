Pod::Spec.new do |spec|
spec.name = "MakeCallSDK"
spec.version = "1.1.0"
spec.summary = "MakeCallSDK to make call to MITEK Ecosystem easily"
spec.description = "It is a library only for learning purpose"
spec.homepage = "https://gitlab.mitek.vn/mitek-public/sdk/michat/live-chat-sdk-ios-12"
spec.license = { :type => "MIT", :file => "LICENSE" }
spec.author = { "Phuc" => "phucxh008@gmail.com" }
spec.swift_version = '6.1'
spec.source = { :git => "https://gitlab.mitek.vn/mitek-public/sdk/michat/live-chat-sdk-ios-12", :tag => spec.version }
spec.source_files = "LiveChatSDK/**/*.{swift}"
spec.dependency 'Socket.IO-Client-Swift'
spec.ios.deployment_target = '12.0'
end
