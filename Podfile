use_frameworks!
inhibit_all_warnings!

platform :ios, '17.0'

target 'DownForACross' do
    pod 'Socket.IO-Client-Swift'
    pod 'lottie-ios'
    pod 'ReachabilitySwift'
end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
                config.build_settings['CODE_SIGN_IDENTITY'] = ''
            end
        end
    end
end
