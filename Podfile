# Uncomment the next line to define a global platform for your project
 platform :ios, '16.0'

# The app is otherwise SPM-only; these are here because the mediation stack has no SPM
# equivalent worth re-solving, and these versions are already proven in the shipping app.
#
# Trimmed from eight networks to three on the numbers. InMobi, Chartboost, ironSource and
# Mintegral each earned exactly $0.00 over the measured period — ironSource brings
# AdQuality with it, 10.8 MB that serves no ads at all. Unity earned $0.33 across twenty
# months while being the largest SDK here, and its waterfall entry took 2,428 impressions
# in ninety days for none of it. AdMob and Vungle are 96.4% of revenue.
#
# Removing an adapter here does not stop AdMob requesting from it: disable those networks
# in the mediation groups too, or the app keeps making requests nothing can fill.
# What ships: the three networks that earn something.
def ad_sdks
  pod 'Google-Mobile-Ads-SDK'
  pod 'FBAudienceNetwork'

  pod 'GoogleUserMessagingPlatform'

  pod 'GoogleMobileAdsMediationVungle'    # Liftoff — $3.69, 41.9%
  pod 'GoogleMobileAdsMediationFacebook'  # Meta    — $0.28,  3.2%
end

target 'Gamoitsani' do
  use_frameworks!
  ad_sdks
end

# The ad SDK podspecs still declare iOS 12.0, and CocoaPods takes them at their word.
# Xcode 27 refuses to build anything below 15.0, so pull every pod target up to the
# platform this Podfile already declares.
post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
