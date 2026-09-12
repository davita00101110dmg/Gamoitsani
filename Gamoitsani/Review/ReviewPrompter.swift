//
//  ReviewPrompter.swift
//  Gamoitsani
//
import SwiftUI
import Observation
import GamoitsaniCore

/// Decides when to ask for an App Store review, and remembers that it asked.
///
/// The asking itself belongs to SwiftUI's `requestReview` action, which has to be called
/// from a view. This type owns the counting and the rules; the podium owns the moment.
@MainActor
@Observable
final class ReviewPrompter {

    private(set) var state: ReviewPromptState

    @ObservationIgnored private var policy: ReviewPromptPolicy {
        #if DEBUG
        UserDefaults.standard.bool(forKey: Self.instantKey) ? .unrestricted : ReviewPromptPolicy()
        #else
        ReviewPromptPolicy()
        #endif
    }

    init() {
        state = Self.load()
    }

    /// A game reached the podium.
    func gameFinished() {
        state.gamesFinished += 1
        Self.save(state)
    }

    var shouldPrompt: Bool {
        policy.allowsPrompt(state, at: .now)
    }

    /// Records that the sheet was requested. Called only when it actually was — iOS may
    /// decide to show nothing, but from here the ask has been spent.
    func prompted() {
        state = policy.prompted(state, at: .now)
        Self.save(state)
    }

    // MARK: - Storage

    private static let key = "review.prompt"

    private static func load() -> ReviewPromptState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(ReviewPromptState.self, from: data)
        else { return ReviewPromptState() }
        return stored
    }

    private static func save(_ state: ReviewPromptState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    #if DEBUG
    static let instantKey = "review.ignoreLimits"

    var debugSummary: [(String, String)] {
        [
            ("games", "\(state.gamesFinished)"),
            ("asked", "\(state.promptCount) / \(policy.maximumPrompts)"),
            ("would ask now", shouldPrompt ? "yes" : "no"),
        ]
    }

    func debugReset() {
        state = ReviewPromptState()
        Self.save(state)
    }
    #endif
}
