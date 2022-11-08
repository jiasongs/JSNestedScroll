Pod::Spec.new do |s|
  s.name                  = "JSNestedScroll"
  s.version               = "0.0.1"
  s.summary               = "嵌套滚动组件"
  s.homepage              = "https://github.com/jiasongs/JSNestedScroll"
  s.license               = "MIT"
  s.author                = { "ruanmei" => "jiasong@ruanmei.com" }
  s.source                = { :git => "https://github.com/jiasongs/JSNestedScroll", :tag => "#{s.version}" }
  s.platform              = :ios, "11.0"
  s.swift_versions        = ["4.2", "5.0"]
  s.static_framework      = true
  s.requires_arc          = true
  s.frameworks            = "UIKit"

  s.dependency "JSCoreKit", "~> 0.2.6"

  s.source_files          = "Sources/**/*.{swift,h,m}"
end