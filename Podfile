platform :ios, '11.0'

target 'activeTAN' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # ZXing QR code scanner, Objective C port
  # Podfile is currently outdated,
  # see https://github.com/zxingify/zxingify-objc/issues/511
  # Thus, we have to install it from the upstream repo to get the current version
  pod 'ZXingObjC', :git => 'https://github.com/zxingify/zxingify-objc.git', :tag => '3.6.7'

  # Crypto algorithms
  pod 'CryptoSwift', '1.6.0'
  
  target 'activeTANTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'activeTANUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
