#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint kiosk_payment.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'kiosk_payment'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for kiosk payment device integration.'
  s.description      = <<-DESC
A Flutter plugin for kiosk payment device integration. Provides a clean abstraction for payment device discovery, connection, and transaction processing.
                       DESC
  s.homepage         = 'https://github.com/baps/kiosk-payment'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BAPS' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.vendored_frameworks = 'BoltMobileSDK.xcframework'
end
