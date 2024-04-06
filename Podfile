plugin 'cocoapods-binary-cache'

config_cocoapods_binary_cache(
  cache_repo: {
    "default" => {
      "local" => "~/.cocoapods-binary-cache/prebuilt-frameworks"
    }
  },
  device_build_enabled: true,
  build_args: {
    :simulator => [
      "ARCHS='x86_64 arm64'"
    ]
  },
  xcframework: true
)

use_frameworks!
inhibit_all_warnings!

platform :ios, '17.0'

target 'DownForACross' do
    pod 'Socket.IO-Client-Swift', :binary => true
    pod 'lottie-ios', :binary => true
    pod 'ReachabilitySwift', :binary => true
    pod 'SwiftLint'
end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
                config.build_settings['CODE_SIGN_IDENTITY'] = ''
                config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
            end
        end
    end
end
