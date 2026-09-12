//
//  AdUnits.swift
//  Gamoitsani
//
import Foundation

/// Ad unit identifiers, substituted into the Info.plist from `Config.xcconfig`.
///
/// Empty when the key is missing, which the adapter treats as "this format is switched
/// off" — a build without credentials still runs, it just never fills.
enum AdUnits {
    static let banner = value("BANNER_AD_ID")
    static let interstitial = value("INTERSTITIAL_AD_ID")
    static let appOpen = value("APP_OPEN_AD_ID")
    static let rewarded = value("REWARDED_AD_ID")
    static let testDevice = value("ADMOB_TEST_DEVICE_ID")
    static let umpTestDevice = value("UMP_TEST_DEVICE_ID")

    private static func value(_ key: String) -> String {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        // An unsubstituted "$(NAME)" means the xcconfig was not applied. Treat it as
        // absent rather than sending it to the network as an ad unit.
        return raw.hasPrefix("$(") ? "" : raw
    }
}
