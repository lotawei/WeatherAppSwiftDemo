# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'WeatherAppSwiftDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'SkeletonView', '~> 1.30'
  pod 'DGCharts'
  # Pods for WeatherAppSwiftDemo

  target 'WeatherAppSwiftDemoTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WeatherAppSwiftDemoUITests' do
    # Pods for testing
  end
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
      end
    end
  end
end
