Pod::Spec.new do |spec|
  spec.name             = "Ext"
  spec.version          = "0.5.0"
  spec.summary          = "Some useful Swift extensions."
  spec.homepage         = 'https://github.com/naijoug/Ext'
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  spec.author           = { "naijoug" => "naijoug@126.com" }
  spec.source           = { :git => "https://github.com/naijoug/Ext.git", :tag => spec.version.to_s }
  spec.description      = <<-DESC
                          Some useful extensions for Swift.
                        DESC
  
  spec.ios.deployment_target  = '11.0'
  spec.swift_version          = "5.0"
  spec.requires_arc           = true
  spec.default_subspecs       = 'UI', 'Feature'
  
  spec.subspec 'Core' do |ss|
    ss.source_files = 'Sources/Core/**/*'
  end
  
  spec.subspec 'Extension' do |ss|
    ss.source_files = 'Sources/Extension/**/*'
    ss.frameworks = 'UIKit', 'AVKit'
    
    ss.dependency 'Ext/Core'
  end
  
  spec.subspec 'UI' do |ss|
    ss.source_files = 'Sources/UI/**/*'
    ss.frameworks = 'UIKit', 'WebKit'
    
    ss.dependency 'Ext/Extension'
  end
  
  spec.subspec 'Feature' do |ss|
    ss.source_files = 'Sources/Feature/**/*'
    
    ss.dependency 'Ext/Extension'
  end
  
  spec.subspec 'Rx' do |ss|
    ss.source_files = 'Sources/Rx/**/*'
    
    ss.dependency 'Ext/Feature'
    ss.dependency 'RxSwift', '~> 6.2.0'
  end
end
