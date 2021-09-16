Pod::Spec.new do |spec|
  spec.name            = "Ext"
  spec.version         = "0.2.0"
  spec.summary      = "Some useful Swift extensions."
  spec.description  = <<-DESC
                    Some useful extensions for Swift.
                   DESC

  spec.homepage      = "https://github.com/naijoug/Ext"
  spec.license            = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "naijoug" => "naijoug@126.com" }

  spec.source           = { :git => "https://github.com/naijoug/Ext.git", :tag => spec.version.to_s }
  spec.ios.deployment_target = '11.0'
  spec.swift_version = "5.0"
  spec.requires_arc = true
  spec.source_files = "Sources"
  spec.default_subspecs = 'Core', 'Extension', 'UI', 'Router', 'Feature'
    
  spec.subspec 'Core' do |ss|
    ss.source_files = 'Sources/Core/*.swift'
  end
  
  spec.subspec 'Extension' do |ss|
    ss.source_files = 'Sources/*.swift', 'Sources/Extension/**/*'
    ss.frameworks = 'UIKit', 'AVKit'
    
    ss.dependency 'Ext/Core'
  end
  
  spec.subspec 'UI' do |ss|
    ss.source_files = 'Sources/UI/**/*'
    ss.frameworks = 'UIKit', 'WebKit'
    
    ss.dependency 'Ext/Extension'
  end
  
  spec.subspec 'Router' do |ss|
    ss.source_files = 'Sources/Router/**/*'
    ss.dependency 'Ext/UI'
  end
  
  spec.subspec 'Feature' do |ss|
    ss.source_files = 'Sources/Feature/**/*'
    
    ss.dependency 'Ext/UI'
  end
  
end
