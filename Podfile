
# @binary_cache_installed = Gem::Specification.find_all_by_name("cocoapods-binary-cache").length == 1

# if @binary_cache_installed
#     plugin 'cocoapods-binary-cache'

#     config_cocoapods_binary_cache(
#       cache_repo: {
#         "default" => {
#           "local" => "~/.cocoapods-binary-cache/prebuilt-frameworks"
#         }
#       },
#       device_build_enabled: true,
#       build_args: {
#         :simulator => [
#           "ARCHS='x86_64 arm64'"
#         ]
#       },
#       xcframework: true
#     )
# end

def binary_pod(pod_name)
  # if @binary_cache_installed
  #     pod pod_name, :binary => true
  # else
      pod pod_name
  # end
end

use_frameworks!
inhibit_all_warnings!

platform :ios, '17.0'

target 'DownForACross' do
    binary_pod 'Socket.IO-Client-Swift'
    binary_pod 'lottie-ios'
    binary_pod 'ReachabilitySwift'
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
