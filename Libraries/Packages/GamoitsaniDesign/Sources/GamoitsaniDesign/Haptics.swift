//
//  Haptics.swift
//  GamoitsaniDesign
//
import Observation
import SwiftUI

/// Whether the app buzzes. The tactile sibling of `SoundPlayer`.
///
/// iOS has a system-wide switch, but it silences every app at once. A game that taps once
/// a second through the last five needs its own.
@MainActor
@Observable
public final class Haptics {
    public var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.key) }
    }

    private static let key = "haptics.enabled"

    public init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.key) as? Bool ?? true
    }
}

public extension View {
    /// `sensoryFeedback`, gated on the app's haptics setting.
    ///
    /// Every haptic goes through here rather than through `sensoryFeedback` directly, or
    /// the setting would silence some of the app and not the rest.
    func haptics<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        modifier(HapticModifier(trigger: trigger) { _, _ in feedback })
    }

    /// The conditional form: return nil to stay silent for this change.
    func haptics<T: Equatable>(
        trigger: T,
        _ feedback: @escaping (T, T) -> SensoryFeedback?
    ) -> some View {
        modifier(HapticModifier(trigger: trigger, feedback: feedback))
    }
}

private struct HapticModifier<T: Equatable>: ViewModifier {
    // Optional so a preview without the environment still renders rather than trapping.
    @Environment(Haptics.self) private var haptics: Haptics?

    let trigger: T
    let feedback: (T, T) -> SensoryFeedback?

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: trigger) { old, new in
            guard haptics?.isEnabled ?? true else { return nil }
            return feedback(old, new)
        }
    }
}
