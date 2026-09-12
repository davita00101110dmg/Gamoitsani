//
//  AdEnvironment.swift
//  Gamoitsani
//
import SwiftUI
import GamoitsaniAds

extension EnvironmentValues {
    /// Ads, as the app sees them. Defaults to none so previews never reach a network.
    @Entry var adService: any AdServing = NoAds()
}
