#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'send_log'
  s.version          = '1.0.0'
  s.summary          = 'Log support.'
  s.description      = <<-DESC
Allows send emails from flutter using native platform functionality.
                       DESC
  s.homepage         = 'https://tramontana.co.hu'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tramontana' => 'deakjahn@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
  s.swift_version = '5.0'
end

