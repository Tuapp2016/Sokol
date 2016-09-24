# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'Sokol' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'Firebase' 
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'GoogleSignIn'
  pod 'Fabric'
  pod 'TwitterKit'
  pod 'TwitterCore'
  pod 'Polyline', '~> 3.3’
  pod 'ReachabilitySwift’, '~> 2.4'


  # Pods for Sokol

  target 'SokolTests' do
    inherit! :search_paths
    # Pods for testing
  pod 'Firebase' 
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'GoogleSignIn'
  pod 'Fabric'
  pod 'TwitterKit'
  pod 'TwitterCore'
  pod 'Polyline', '~> 3.3’
  
  end

end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = ‘2.3’
    end
  end
end
