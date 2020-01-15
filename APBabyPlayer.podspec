Pod::Spec.new do |s|
  s.name             = "APBabyPlayer"
  s.version           = '6.0.0'
  s.summary          = "APBabyPlayer"
  s.description      = <<-DESC
                        APBabyPlayer container.
                       DESC
  s.homepage         = "https://github.com/applicaster-plugins/APBabyPlayer-iOS"
  s.license          = ''
  s.author           = { "cmps" => "a=roei.carmel@msapps.mobi" }
  s.source           = { :git => "git@github.com:applicaster-plugins/APBabyPlayer-iOS.git", :tag => s.version.to_s }

  s.platform                = :ios, '10.0'
  s.ios.deployment_target   = "10.0"
  s.requires_arc            = true
  s.static_framework        = true
  s.swift_version           = '5.1'



  s.public_header_files = 'APBaby/**/*.h'
  s.source_files = 'APBaby/**/*.{h,m,swift}'

  s.resources = [
                "APBaby/Resource/*.xcassets",
                "APBaby/Resource/*.storyboard",
                "APBaby/Resource/*.xib",
                "APBaby/Resource/*.png"]

  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'YES',
                  'SWIFT_VERSION' => '5.1'
              }


  s.dependency 'ZappPlugins'

end
