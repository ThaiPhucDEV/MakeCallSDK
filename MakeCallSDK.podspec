Pod::Spec.new do |s|
  s.name         = "MakeCallSDK"
  s.version      = "1.1.7"
  s.summary      = "A simple SDK to make calls"
  s.description  = "MakeCallSDK is a demo SDK to make call functionalities for iOS developers."
  s.homepage     = "https://github.com/ThaiPhucDEV/MakeCallSDK"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Phuc" => "phucxh008@gmail.com" }
  s.swift_version = '5.7'
  s.ios.deployment_target = '12.0'

  s.source       = { :git => "https://github.com/ThaiPhucDEV/MakeCallSDK.git", :tag => s.version }

 
s.source_files = 'Sources/MakeCallSDK/**/*.{swift,h,m}'

  
 

 



    
   s.frameworks = 'UIKit', 'AVFoundation', 'CallKit'

  s.requires_arc = true

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }

  s.module_name = 'MakeCallSDK'
 
 
 

end
