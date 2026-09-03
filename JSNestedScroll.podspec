Pod::Spec.new do |s|
  s.name = "JSNestedScroll"

  s.version = "2.0.0"
  s.platforms = { :ios => "15.0" }
  s.swift_versions = ["5.9"]
  s.requires_arc = true

  s.summary = "嵌套滚动组件"
  s.homepage = "https://github.com/CloudlessMoon/JSNestedScroll"
  s.license = "MIT"
  s.author = { "ruanmei" => "jiasong@ruanmei.com" }
  s.source = { :git => "https://github.com/CloudlessMoon/JSNestedScroll.git", :tag => s.version.to_s }

  s.dependency "JSCoreKit", "~> 2.0"

  s.source_files = "Sources/**/*.{swift,h,m}"
end