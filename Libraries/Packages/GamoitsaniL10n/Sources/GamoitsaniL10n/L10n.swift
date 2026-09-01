//
//  L10n.swift
//  GamoitsaniL10n
//

import Foundation

/// Type-safe string access.
///
/// v1's SwiftGen strings codegen silently produced `// No string found` — its parser does
/// not read `.xcstrings` — so the 425-line `L10n` tree became hand-maintained with no
/// compile-time key validation. Phase 7 moves the catalogue here and generates this from
/// it; keys resolve through the package bundle rather than by swapping `Bundle` on every
/// lookup as v1 did inside SwiftUI `body` re-evaluations.
public enum L10n {
    public static func string(_ key: String, table: String? = nil) -> String {
        String(localized: String.LocalizationValue(key), table: table, bundle: .module)
    }
}
