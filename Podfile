# Uncomment the next line to define a global platform for your project
 platform :ios, '16.0'

# Shared by both apps during the 2.0 changeover. Gamoitsani2 is otherwise SPM-only; these
# are here because the mediation stack has no SPM equivalent that is worth re-solving, and
# the versions below are already proven in the shipping app.
#
# Trimmed from eight networks to three on the numbers. InMobi, Chartboost, ironSource and
# Mintegral each earned exactly $0.00 over the measured period — ironSource brings
# AdQuality with it, 10.8 MB that serves no ads at all. Unity earned $0.33 across twenty
# months while being the largest SDK here, and its waterfall entry took 2,428 impressions
# in ninety days for none of it. AdMob and Vungle are 96.4% of revenue.
#
# Removing an adapter here does not stop AdMob requesting from it: disable those networks
# in the mediation groups too, or the app keeps making requests nothing can fill.
# What 2.0 ships: the three networks that earn something.
def ad_sdks
  pod 'Google-Mobile-Ads-SDK'
  pod 'FBAudienceNetwork'

  pod 'GoogleUserMessagingPlatform'

  pod 'GoogleMobileAdsMediationVungle'    # Liftoff — $3.69, 41.9%
  pod 'GoogleMobileAdsMediationFacebook'  # Meta    — $0.28,  3.2%
end

# v1 keeps all eight. Not because they earn anything — they do not — but because
# AppConsentAdManager imports InMobiSDK and ChartboostSDK directly, and the shipping app
# has to keep building until 2.0 replaces it. These leave with v1 at cutover.
def legacy_ad_sdks
  ad_sdks
  pod 'GoogleMobileAdsMediationUnity'
  pod 'InMobiSDK'
  pod 'ChartboostMediationSDK'
  pod 'GoogleMobileAdsMediationInMobi'
  pod 'GoogleMobileAdsMediationChartboost'
  pod 'GoogleMobileAdsMediationIronSource'
  pod 'GoogleMobileAdsMediationMintegral'
end

target 'Gamoitsani' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Gamoitsani
  legacy_ad_sdks

  target 'GamoitsaniTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'GamoitsaniUITests' do
    # Pods for testing
  end

end

target 'Gamoitsani2' do
  use_frameworks!
  ad_sdks
end
