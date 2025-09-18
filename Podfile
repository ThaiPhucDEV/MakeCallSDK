# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'MakeCallSDKFramework' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

    # Linphone SDK từ GitLab
  pod 'linphone-sdk-swift-ios',
      :git => 'https://gitlab.linphone.org/BC/public/linphone-sdk.git',
      :tag => '5.4.44'  # Hoặc branch cụ thể bạn muốn
 

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
