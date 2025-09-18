Pod::Spec.new do |spec|
  spec.name         = "MakeCallSDK"
  spec.version      = "0.0.5"
  spec.summary      = "A simple SDK to make calls"
  spec.description  = "MakeCallSDK is a demo SDK to make call functionalities for iOS developers."

  spec.homepage     = "https://github.com/ThaiPhucDEV/MakeCallSDK.git"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Phuc" => "phucxh008@gmail.com" }

  spec.swift_version = '5.0'
  spec.ios.deployment_target = '12.0'

  spec.source       = { :git => "https://github.com/ThaiPhucDEV/MakeCallSDK.git", :tag => spec.version }
  spec.source_files = "MakeCallSDK/**/*.swift"

  # Dependencies
  spec.dependency 'GoogleWebRTC'
  
end
