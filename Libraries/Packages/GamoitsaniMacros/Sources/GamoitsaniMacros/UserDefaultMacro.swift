//
//  UserDefaultMacro.swift
//  GamoitsaniMacros
//
//  Created by Daviti Khvedelidze on 15/03/2025.
//

/// A property wrapper that automatically stores and retrieves values from UserDefaults.
///
/// Usage:
/// ```swift
/// @UserDefault("username", defaultValue: "")
/// var username: String
/// ```
@attached(accessor)
public macro UserDefault(_ key: String, defaultValue: Any) = #externalMacro(module: "GamoitsaniMacrosImpl", type: "UserDefaultMacroImpl")
