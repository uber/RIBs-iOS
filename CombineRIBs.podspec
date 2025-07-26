Pod::Spec.new do |s|
  s.name             = 'CombineRIBs'
  s.version          = '0.9.3'
  s.summary          = 'Combine-based cross-platform mobile architecture.'
  s.description      = <<-DESC
CombineRIBs is a Combine-based adaptation of Uber's RIBs architecture framework. This architecture framework is designed for mobile apps with a large number of engineers and nested states, using Combine for reactive programming.
                       DESC
  s.homepage         = 'https://github.com/shelteredsunfish/CombineRIBs'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE.txt' }
  s.author           = { 'uber' => 'mobile-open-source@uber.com' }
  s.source           = { :git => 'https://github.com/uber/CombineRIBs-iOS.git', :tag => 'v' + s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'CombineRIBs/Classes/**/*'
  
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'CombineRIBsTests/**/*.swift'
    test_spec.dependency 'CwlPreconditionTesting'
  end

end 