Pod::Spec.new do |s|
  s.name         = "Marionette"
  s.version      = %x(git describe --tags --abbrev=0).chomp
  s.summary      = "Swift library which provides a high-level API to control a WKWebView"
  s.description  = "Marionette is a Swift library which provides a high-level API to control a WKWebView. The goal is to have the API closely mirror that of Puppeteer."
  s.homepage     = "https://github.com/LinusU/Marionette"
  s.license      = "MIT"
  s.author       = { "Linus Unnebäck" => "linus@folkdatorn.se" }

  s.swift_version = "4.0"
  s.ios.deployment_target = "11.0"

  # FIXME: https://github.com/artman/Signals/issues/75
  # s.osx.deployment_target = "10.13"

  s.source       = { :git => "https://github.com/LinusU/Marionette.git", :tag => "#{s.version}" }
  s.source_files = "Sources"

  s.dependency "LinusU_JSBridge", "1.0.0-alpha.15"
  s.dependency "PromiseKit", "~> 6.0"
  s.dependency "Signals", "~> 6.0"
end
