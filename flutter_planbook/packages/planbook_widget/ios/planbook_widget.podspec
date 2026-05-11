#
# planbook_widget — Planbook 小组件事件桥接插件
#
Pod::Spec.new do |s|
  s.name             = 'planbook_widget'
  s.version          = '0.1.0'
  s.summary          = 'Planbook 小组件 ↔ App 事件桥接插件'
  s.description      = <<-DESC
Bridges Planbook widget intents (complete task etc.) to the host Flutter
application via MethodChannel, with built-in engine-ready handshake.
                       DESC
  s.homepage         = 'https://github.com/bapaws/planbook'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Planbook' => 'support@bapaws.com' }
  s.source           = { :path => '.' }
  s.source_files = 'planbook_widget/Sources/planbook_widget/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
  }

  # Xcode 26 workaround：与 widget extension 共用时关闭 explicit modules
  s.user_target_xcconfig = { 'SWIFT_ENABLE_EXPLICIT_MODULES' => 'NO' }
  s.swift_version = '5.0'
end
