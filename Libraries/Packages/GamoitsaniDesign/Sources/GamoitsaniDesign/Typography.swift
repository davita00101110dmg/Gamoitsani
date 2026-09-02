//
//  Typography.swift
//  GamoitsaniDesign
//

import SwiftUI
import CoreText

/// The type system: a bundled display face and the system face for everything else.
///
/// v1 bundled Mersad, which is Latin-only. Every Georgian, Armenian, Cyrillic and Japanese
/// string therefore fell back to the system font without anyone declaring it — the app ran
/// on two type systems and only looked consistent in English.
///
/// **Actual coverage of the display face**, measured against the font binary rather than
/// taken from the handoff, which claims Cyrillic and Greek that the file does not contain:
///
///   carried  — ka, en, tr, az, de, es, fr
///   falls back — ru, uk, hy, ja
///
/// So this improves the gap from 10 of 11 languages to 4 of 11, rather than closing it.
/// The fallback is automatic and legible; only the display *voice* is inconsistent in
/// those four. Closing it entirely means bundling Noto Sans for Cyrillic/Greek plus Noto
/// Sans Armenian, and accepting that Japanese cannot be bundled at a sane size.
/// `DesignSystemTests` asserts both the coverage and the gaps, so neither can drift
/// silently.
///
/// Display sizes use `.custom(_:size:relativeTo:)` rather than a fixed point size, so the
/// wordmark and timer scale with Dynamic Type instead of pinning at 96pt.
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
    ///
    /// Semibold rather than regular, because a row's title sits beside a value set in the
    /// display face at Black. At regular weight the pairing looks unbalanced, and it is
    /// worst in scripts the system font does not carry: Georgian falls back to a
    /// substituted face that renders lighter still, so "რაუნდები" next to a Black "1" read
    /// as two different designs.
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
///
/// A font shipped inside an SPM package cannot be declared in the app's `UIAppFonts`,
/// because it is not in the app bundle. It has to be registered with Core Text at runtime
/// or every `.custom(...)` call silently falls back to the system face — which looks like
/// it works, which is exactly why it needs an explicit check rather than a hopeful call.
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
