//
//  Typography.swift
//  GamoitsaniDesign
//
import SwiftUI
import CoreText

/// The type system: a bundled display face and the system face for everything else.
public enum Typography {

    /// The bundled display family.
    public static let displayFamily = "Noto Sans Georgian"

    // MARK: - Display (bundled face)

    /// Wordmark and the largest numerals.
    public static func display(_ size: CGFloat = 34) -> Font {
        .custom(displayFamily, size: size, relativeTo: .largeTitle).weight(.black)
    }

    /// The word on a card, and the round timer.
    public static func word(_ size: CGFloat = 32) -> Font {
        .custom(displayFamily, size: size, relativeTo: .title).weight(.black)
    }

    /// Large score numerals.
    public static func numeral(_ size: CGFloat = 76) -> Font {
        .custom(displayFamily, size: size, relativeTo: .largeTitle).weight(.black)
    }

    // MARK: - Body (system face)

    /// The label on a settings or setup row.
    public static let rowTitle = Font.body.weight(.semibold)

    /// Declared as text styles, never fixed points, so Dynamic Type works for free and
    /// all eleven languages are covered without bundling more files.
    public static let title = Font.title2.weight(.bold)
    public static let headline = Font.headline
    public static let body = Font.body
    public static let caption = Font.caption

    /// Small monospaced labels — point values, language codes, section headers.
    public static let label = Font.system(.caption, design: .monospaced).weight(.semibold)
}

/// Registers the bundled font.
public enum DesignSystem {

    private static let registration: Bool = {
        guard let url = Bundle.module.url(forResource: "NotoSansGeorgian", withExtension: "ttf") else {
            assertionFailure("NotoSansGeorgian.ttf missing from GamoitsaniDesign resources")
            return false
        }
        var error: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if !ok, let error {
            // Already-registered is benign; anything else is not.
            let code = CFErrorGetCode(error.takeUnretainedValue())
            return code == CTFontManagerError.alreadyRegistered.rawValue
        }
        return ok
    }()

    /// Call once at launch, before any view using `Typography.display` is built.
    @discardableResult
    public static func registerFonts() -> Bool {
        registration
    }

    /// Whether the bundled display family is actually resolvable. Asserted by the tests so
    /// a silent fallback to the system font fails the build rather than shipping.
    public static func isDisplayFontAvailable() -> Bool {
        registerFonts()
        #if canImport(UIKit)
        return UIFont(name: Typography.displayFamily, size: 17) != nil
        #else
        return false
        #endif
    }
}
