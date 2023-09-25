platform :ios, '11.0'

target 'activeTAN' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # ZXing QR code scanner, Objective C port
  # Podspec is currently outdated, see https://github.com/zxingify/zxingify-objc/issues/511
  # Thus, we have to install it from a custom podspec
  #    - Updated version number to 3.6.7
  #    - Updated iOS deployment target to 11.0 (for XCode 14)
  pod 'ZXingObjC/QRCode', :podspec => './ZXingObjC.podspec'

  # Crypto algorithms
  pod 'CryptoSwift', '1.7.1'
  
  target 'activeTANTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'activeTANUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
