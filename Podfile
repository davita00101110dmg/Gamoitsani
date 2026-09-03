# Uncomment the next line to define a global platform for your project
 platform :ios, '16.0'

# Shared by both apps during the 2.0 changeover. Gamoitsani2 is otherwise SPM-only; these
# are here because the mediation stack has no SPM equivalent that is worth re-solving, and
# the versions below are already proven in the shipping app.
def ad_sdks
  pod 'Google-Mobile-Ads-SDK'
  pod 'InMobiSDK'
  pod 'ChartboostMediationSDK'
  pod 'FBAudienceNetwork'

  pod 'GoogleUserMessagingPlatform'

  pod 'GoogleMobileAdsMediationVungle'
  pod 'GoogleMobileAdsMediationInMobi'
  pod 'GoogleMobileAdsMediationFacebook'
  pod 'GoogleMobileAdsMediationChartboost'
  pod 'GoogleMobileAdsMediationUnity'
  pod 'GoogleMobileAdsMediationIronSource'
  pod 'GoogleMobileAdsMediationMintegral'
end

target 'Gamoitsani' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Gamoitsani
  ad_sdks

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
