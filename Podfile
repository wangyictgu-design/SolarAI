platform :ios, '15.0'

target 'SolarAI' do
  use_frameworks!

  pod 'SnapKit', '~> 5.7'
  # Alamofire 5.10+ targets Swift 6; use 5.9.x with Xcode 15 / Swift 5.
  pod 'Alamofire', '>= 5.9', '< 5.10'
end

def normalize_pbxproj_at_path_for_xcode15!(pbxproj_path)
  return unless File.exist?(pbxproj_path)

  pbx = File.read(pbxproj_path)
  pbx.gsub!(/objectVersion = 77;/, 'objectVersion = 56;')
  # Xcode 15.4 crashes (IDEInspector / -[PBXProject preferredProjectFormat]) if Xcode 16-only keys remain.
    line.include?('minimizedProjectReferenceProxies =') || line.include?('preferredProjectObjectVersion =')
  end.join
  pbx.gsub!(/LastUpgradeCheck = 1600;/, 'LastUpgradeCheck = 1500;')
  pbx.gsub!(/LastSwiftUpdateCheck = 1600;/, 'LastSwiftUpdateCheck = 1500;')
  File.write(pbxproj_path, pbx)
end

def normalize_pods_pbxproj_for_xcode15!(installer)
  normalize_pbxproj_at_path_for_xcode15!(File.join(installer.pods_project.path.to_s, 'project.pbxproj'))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

# Run after integration so CocoaPods cannot overwrite the on-disk fix with a later save.
post_integrate do |installer|
  normalize_pods_pbxproj_for_xcode15!(installer)
  normalize_pbxproj_at_path_for_xcode15!(File.join(__dir__, 'SolarAI.xcodeproj', 'project.pbxproj'))
end
