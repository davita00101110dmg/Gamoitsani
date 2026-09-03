//
//  PlayView.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniEngine
import GamoitsaniL10n

/// The clock is running.
struct PlayView: View {
    let engine: GameEngine

    /// Mirrors the clock's warning window, so answer haptics stand down while the timer
    /// is pulsing once a second.
    @State private var isUrgent = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            RoundClock(engine: engine, isUrgent: $isUrgent)

            switch engine.state.settings.mode {
            case .classic: ClassicPlayView(engine: engine, suppressHaptics: isUrgent)
            case .arcade: ArcadePlayView(engine: engine, suppressHaptics: isUrgent)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
    }
}

/// The round clock.
private struct RoundClock: View {
    let engine: GameEngine
    @Binding var isUrgent: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SoundPlayer.self) private var sound
    @Environment(Localization.self) private var l10n
    @State private var remaining: TimeInterval = 0

    private var secondsLeft: Int { Int(remaining.rounded(.up)) }
    private var urgentNow: Bool { secondsLeft <= 5 && secondsLeft > 0 }

    /// Changes on every second inside the warning window, so the haptic repeats. Bound to
    /// `isUrgent` it fired once, when the threshold was crossed.
    private var urgentTick: Int { urgentNow ? secondsLeft : -1 }

    var body: some View {
        // Colour and haptics carry the warning, not a shake. v1 shook the timer, and a
        Text("\(secondsLeft)")
            .font(Typography.numeral(64))
            .foregroundStyle(isUrgent ? Tokens.danger.color : Tokens.onSurface.color)
            .contentTransition(.numericText(countsDown: true))
            .monospacedDigit()
            .frame(maxWidth: .infinity)
            .animation(.linear(duration: 0.2), value: secondsLeft)
            // On its own the numeral is announced as a bare number with no idea what it
            // counts. As a value it also re-announces each second while focused, which is
            // the one place that is wanted.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(l10n("a11y.timeRemaining"))
            .accessibilityValue("\(secondsLeft)")
        // Once per second through the final five, not once when it crosses the threshold.
        .sensoryFeedback(.warning, trigger: urgentTick)
        .onChange(of: urgentTick) { _, tick in
            if tick > 0 { sound.play(.warning) }
        }
        // TimelineView drives the display; the engine owns when the round actually ends.
        .overlay {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                Color.clear
                    .onChange(of: context.date) { _, _ in
                        remaining = engine.remainingTime
                        if isUrgent != urgentNow { isUrgent = urgentNow }
                        engine.checkExpiry()
                    }
            }
        }
        .onAppear { remaining = engine.remainingTime }
    }
}

/// One word at a time.
struct ClassicPlayView: View {
    let engine: GameEngine
    /// Suppresses answer haptics while the clock is ticking one per second.
    var suppressHaptics: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Localization.self) private var l10n
    @Environment(SoundPlayer.self) private var sound
    @State private var lastOutcome: PlayOutcome?
    /// Increments on every answer. `sensoryFeedback` fires on a *change*, so triggering
    /// on the outcome alone missed two identical answers in a row.    /// *other* button, so repeating the same one produced no feedback at all.
    @State private var answerCount = 0

    private var word: DeckWord? { engine.wordsInPlay.first }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            if let word {
                WordCard(text: word.text, isSuperWord: word.isSuperWord)
                    .id(word.id)
                    .transition(cardTransition)
            } else {
                ExhaustedCard()
            }

            Spacer()

            HStack(spacing: Spacing.xl) {
                answerButton(.skipped, symbol: "xmark", color: Tokens.danger.color)
                answerButton(.correct, symbol: "checkmark", color: Tokens.success.color)
            }
            .padding(.bottom, Spacing.lg)
            .disabled(word == nil)
            .opacity(word == nil ? 0.4 : 1)
        }
    }

    /// Direction *is* the feedback: correct leaves upward, skipped drops. Reusing one
    /// direction for both would throw that away.
    private var cardTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let exit: AnyTransition = switch lastOutcome {
        case .correct: .offset(y: -420).combined(with: .opacity)
        case .skipped: .offset(y: 240).combined(with: .scale(scale: 0.88)).combined(with: .opacity)
        case nil: .opacity
        }
        return .asymmetric(
            insertion: .offset(y: 24).combined(with: .scale(scale: 0.92)).combined(with: .opacity),
            removal: exit
        )
    }

    /// What this answer is about to be worth, so the score is not a surprise.
    private func points(for outcome: PlayOutcome, isSuperWord: Bool) -> String {
        let value = isSuperWord ? Scoring.superWord : Scoring.regular
        return outcome == .correct ? "+\(value)" : "-\(value)"
    }

    private func answerButton(_ outcome: PlayOutcome, symbol: String, color: Color) -> some View {
        Button {
            guard let word else { return }
            lastOutcome = outcome
            answerCount += 1
            sound.play(outcome == .correct ? (word.isSuperWord ? .superWord : .correct) : .skip)
            withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                _ = engine.send(.answer(wordID: word.id, outcome: outcome))
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(Tokens.onAccent.color)
                .frame(width: 78, height: 78)
                .background(color)
                .clipShape(Circle())
        }
        .sensoryFeedback(outcome == .correct ? .success : .impact(weight: .heavy), trigger: answerCount) { _, _ in
            lastOutcome == outcome && !suppressHaptics
        }
        .accessibilityLabel(outcome == .correct ? l10n("game.correct") : l10n("game.skip"))
        .accessibilityValue(word.map { points(for: outcome, isSuperWord: $0.isSuperWord) } ?? "")
    }
}

/// Five words at once.
struct ArcadePlayView: View {
    let engine: GameEngine
    /// See `ClassicPlayView.suppressHaptics`.
    var suppressHaptics: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Localization.self) private var l10n
    @Environment(SoundPlayer.self) private var sound

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(Array(engine.state.turnWords.enumerated()), id: \.element.id) { index, word in
                let played = engine.state.playedWordIDs.contains(word.id)

                Button {
                    withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                        // Tapping a played word takes it back. This is an undo, not v1's
                        if played {
                            _ = engine.send(.undoAnswer(wordID: word.id))
                            sound.play(.skip)
                        } else {
                            _ = engine.send(.answer(wordID: word.id, outcome: .correct))
                            sound.play(word.isSuperWord ? .superWord : .correct)
                        }
                    }
                } label: {
                    WordRow(text: word.text, isSuperWord: word.isSuperWord, isPlayed: played)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(word.text)
                .accessibilityValue(
                    played
                        ? l10n("a11y.guessed")
                        : (word.isSuperWord ? l10n("a11y.superWord") : l10n("a11y.regularWord"))
                )
                .accessibilityAddTraits(played ? [.isButton, .isSelected] : .isButton)
                .accessibilityHint(played ? l10n("a11y.undoHint") : l10n("a11y.guessHint"))
                .sensoryFeedback(played ? .success : .impact(weight: .light), trigger: played) { _, _ in
                    !suppressHaptics
                }
                .transition(
                    reduceMotion
                        ? .opacity
                        : .offset(y: 24).combined(with: .opacity)
                )
                .animation(
                    reduceMotion ? Motion.reduced : Motion.card.delay(Double(index) * 0.04),
                    value: engine.state.turnWords.map(\.id)
                )
            }

            Spacer()

            Button {
                withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                    _ = engine.send(.skipSet)
                }
                sound.play(.skip)
            } label: {
                Text("\(l10n("game.newWords"))  \(Scoring.setSkip)")
                    .font(Typography.headline)
                    .foregroundStyle(Tokens.danger.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                            .strokeBorder(Tokens.danger.color, lineWidth: 1.5)
                    }
            }
            .accessibilityLabel(l10n("game.newWords"))
            .accessibilityValue("\(Scoring.setSkip)")
            .sensoryFeedback(.impact(weight: .heavy), trigger: engine.state.setIndex)
        }
    }
}

// MARK: - Pieces

struct WordCard: View {
    let text: String
    let isSuperWord: Bool

    @Environment(Localization.self) private var l10n

    var body: some View {
        ZStack {
            // The word is the point of the screen, so it sits in the optical centre rather
            // than being pushed around by the labels.
            Text(text)
                .font(Typography.word(38))
                .foregroundStyle(Tokens.onSurface.color)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .lineLimit(3)
                // Gameplay text caps its Dynamic Type range: a size that pushes the word
                // off the card makes the game unplayable.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .padding(.horizontal, Spacing.md)

            VStack {
                Text(isSuperWord ? "3 PT · SUPER" : "1 PT")
                    .font(Typography.label)
                    .foregroundStyle(isSuperWord ? Tokens.accent.color : Tokens.onSurfaceMuted.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
        // A real card shape — 3:4, sized from the available width — instead of a fixed
        // 280pt height that read as a short panel.
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .padding(Spacing.md)
        .background(Tokens.cardFace.color)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(isSuperWord ? Tokens.accent.color : Tokens.cardEdge.color, lineWidth: 2)
        }
        .shadow(color: isSuperWord ? Tokens.accent.color.opacity(0.25) : .clear, radius: 12)
        // One element: the badge read out on its own as "3 PT · SUPER", which is a label
        // written for the eye, not the ear.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityValue(l10n(isSuperWord ? "a11y.superWord" : "a11y.regularWord"))
    }
}

struct WordRow: View {
    let text: String
    let isSuperWord: Bool
    let isPlayed: Bool

    var body: some View {
        Text(text)
            .font(Typography.word(20))
            .foregroundStyle(Tokens.onSurface.color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isPlayed ? Tokens.surfaceRaised.color : Tokens.cardFace.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .strokeBorder(
                        isSuperWord ? Tokens.accent.color : Tokens.cardEdge.color,
                        lineWidth: isSuperWord ? 2 : 1.5
                    )
            }
            .opacity(isPlayed ? 0.45 : 1)
            .overlay {
                if isPlayed {
                    // "arrow.uturn.backward" rather than a plain tick: the row is still
                    // tappable, and it should look like it does something.
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.black))
                            .foregroundStyle(Tokens.success.color)
                        Image(systemName: "arrow.uturn.backward")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Tokens.onSurfaceMuted.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, Spacing.md)
                }
            }
    }
}

/// The deck ran out mid-turn.
struct ExhaustedCard: View {
    @Environment(Localization.self) private var l10n

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
            Text(l10n("game.noWords"))
                .font(Typography.body)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .background(Tokens.surfaceRaised.color)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
