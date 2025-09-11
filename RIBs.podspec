Pod::Spec.new do |s|
  s.name             = 'RIBs'
  s.version          = '1.0.0'
  s.summary          = 'Uber\'s cross-platform mobile architecture.'
  s.description      = <<-DESC
RIBs is the cross-platform architecture behind many mobile apps at Uber. This architecture framework is designed for mobile apps with a large number of engineers and nested states.
                       DESC
  s.homepage         = 'https://github.com/uber/RIBs-iOS'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE.txt' }
  s.author           = { 'uber' => 'mobile-open-source@uber.com' }
  s.source           = { :git => 'https://github.com/uber/RIBs-iOS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.0'
  s.source_files = 'RIBs/Classes/**/*'
  s.dependency 'RxSwift', '~> 6.0'
  s.dependency 'RxRelay', '~> 6.0'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'RIBsTests/**/*.swift'
    test_spec.dependency 'CwlPreconditionTesting'
  end

end
