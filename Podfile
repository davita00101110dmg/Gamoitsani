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
