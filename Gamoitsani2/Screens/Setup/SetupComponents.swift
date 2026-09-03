//
//  SetupComponents.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniL10n

/// The card fan, shrinking and fading as the screen scrolls under it.
struct CollapsingFanHeader: View {
    let height: CGFloat
    /// 0 fully shown, 1 fully scrolled away. Computed by the screen from the real scroll
    /// offset and passed in, so this view stays a pure function of its inputs.
    let collapse: CGFloat

    var body: some View {
        // Scales and fades away rather than being clipped. The first attempt shrank the
        let scale = 1 - collapse * 0.55

        AppMark()
            .frame(width: height, height: height)
            .scaleEffect(scale, anchor: .center)
            .opacity(pow(1 - collapse, 1.6))
            .frame(maxWidth: .infinity)
            .frame(height: max(0, height * scale))
            .accessibilityHidden(true)
    }
}

/// A titled group of rows.
struct SetupPanel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title.uppercased())
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
                .padding(.leading, Spacing.xs)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) { content }
                .padding(.horizontal, Spacing.md)
                .background(Tokens.surfaceRaised.color)
                .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                        .strokeBorder(Tokens.cardEdge.color.opacity(0.6), lineWidth: 1)
                }
        }
    }
}

/// A value with minus and plus, where the number itself reacts.
struct StepperRow: View {
    let label: String
    let value: String
    let canDecrease: Bool
    let canIncrease: Bool
    let decrease: () -> Void
    let increase: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.rowTitle)
                .foregroundStyle(Tokens.onSurface.color)

            Spacer()

            HStack(spacing: Spacing.sm) {
                stepButton("minus", enabled: canDecrease, action: decrease)

                Text(value)
                    .font(Typography.word(20))
                    .foregroundStyle(Tokens.onSurface.color)
                    .frame(minWidth: 54)
                    .contentTransition(.numericText())
                    .animation(Motion.control(reduceMotion: reduceMotion), value: value)

                stepButton("plus", enabled: canIncrease, action: increase)
            }
        }
        .padding(.vertical, Spacing.sm)
        // Fires on the value changing, not on the buttons' enabled state — which only
        .sensoryFeedback(trigger: value) { old, new in
            guard old != new else { return nil }
            return numeric(new) > numeric(old) ? .increase : .decrease
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(value)
    }

    /// Leading digits of the displayed value, so "45s" and "3" both compare numerically.
    private func numeric(_ text: String) -> Int {
        Int(text.prefix { $0.isNumber }) ?? 0
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.bold))
                .foregroundStyle(enabled ? Tokens.accent.color : Tokens.onSurfaceMuted.color.opacity(0.4))
                .frame(width: 34, height: 34)
                .background(Tokens.surface.color)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }
}

/// One of the two game modes, as a selectable card.
struct ModeCard: View {
    @Environment(Localization.self) private var l10n
    let mode: GameMode
    let isSelected: Bool
    let reduceMotion: Bool
    let select: () -> Void

    private var title: String {
        switch mode {
        case .classic: l10n("mode.classic")
        case .arcade: l10n("mode.arcade")
        }
    }

    private var detail: String {
        switch mode {
        case .classic: l10n("mode.classic.detail")
        case .arcade: l10n("mode.arcade.detail")
        }
    }

    var body: some View {
        Button(action: select) {
            HStack(spacing: Spacing.sm) {
                // A miniature of what the mode actually looks like: one card, or five.
                ModeGlyph(mode: mode, isSelected: isSelected)
                    .frame(width: 34, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(Tokens.onSurface.color)
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Tokens.accent.color : Tokens.cardEdge.color)
                    .font(.title3)
            }
            .padding(Spacing.sm)
            .background(isSelected ? Tokens.accent.color.opacity(0.10) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .strokeBorder(
                        isSelected ? Tokens.accent.color : Tokens.cardEdge.color.opacity(0.7),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(Motion.control(reduceMotion: reduceMotion), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A miniature of what each mode actually looks like in play.
private struct ModeGlyph: View {
    let mode: GameMode
    let isSelected: Bool

    var body: some View {
        let tint = isSelected ? Tokens.accent.color : Tokens.cardEdge.color

        switch mode {
        case .classic:
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Tokens.cardFace.color)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(tint, lineWidth: 1.5)
                }

        case .arcade:
            VStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { row in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Tokens.cardFace.color)
                        .overlay {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .strokeBorder(tint, lineWidth: 1)
                        }
                        .frame(height: 6)
                        // Two dimmed rows read as a turn in progress; one looked like a
                        // mistake. Alternating keeps the rhythm even.
                        .opacity(row == 1 || row == 3 ? 0.45 : 1)
                }
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let reduceMotion: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Tokens.onSurface.color)
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
            }
        }
        .tint(Tokens.accent.color)
        .padding(.vertical, Spacing.sm)
        .sensoryFeedback(.selection, trigger: isOn)
        .animation(Motion.control(reduceMotion: reduceMotion), value: isOn)
    }
}

/// One team: its colour, its editable name, and whatever is wrong with it.
struct TeamRow<Roster: View>: View {
    @Environment(Localization.self) private var l10n
    let index: Int
    let team: Team
    @Binding var name: String
    let problem: TeamValidationError?
    let canRemove: Bool
    let remove: () -> Void
    let isUsingDefaultName: Bool
    /// Who is on this team, editable. Passed in so this row stays a dumb view.
    private let roster: Roster

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isEditingName: Bool

    init(
        index: Int,
        team: Team,
        name: Binding<String>,
        problem: TeamValidationError?,
        canRemove: Bool,
        remove: @escaping () -> Void,
        isUsingDefaultName: Bool,
        @ViewBuilder roster: () -> Roster
    ) {
        self.index = index
        self.team = team
        self._name = name
        self.problem = problem
        self.canRemove = canRemove
        self.remove = remove
        self.isUsingDefaultName = isUsingDefaultName
        self.roster = roster()
    }

    private var color: Color { TeamPalette.color(at: index).color }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)

                // A generated name is drawn like an unfilled field: muted until it is
                // really the team's name. No well — a bordered field inside an already
                // bordered panel was heavier than the hint is worth.
                TextField(l10n("setup.teamName"), text: $name)
                    .font(Typography.rowTitle)
                    .foregroundStyle(
                        isUsingDefaultName && !isEditingName
                            ? Tokens.onSurfaceMuted.color
                            : Tokens.onSurface.color
                    )
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isEditingName)

                // Steps aside once the caret is there to say it instead.
                if !isEditingName {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }

                if canRemove {
                    Button(action: remove) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Tokens.danger.color)
                    }
                    .accessibilityLabel(l10n("setup.removeTeam"))
                }
            }

            roster
                .padding(.leading, Spacing.lg)
                .padding(.top, Spacing.xxs)

            if let problem {
                Text(message(for: problem))
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.danger.color)
                    .padding(.leading, Spacing.lg)
                    .transition(.opacity)
            }
        }
        .animation(Motion.control(reduceMotion: reduceMotion), value: isEditingName)
        .padding(.vertical, Spacing.sm)
    }

    /// v1 computed a validation error and then discarded it, so an invalid name was
    /// dropped with no alert and nothing marked the offending row.
    private func message(for problem: TeamValidationError) -> String {
        switch problem {
        case .emptyName: l10n("setup.error.empty")
        case .duplicateName: l10n("setup.error.duplicate")
        case .nameTooLong: l10n("setup.error.tooLong")
        case .tooFewTeams, .tooManyTeams: l10n("setup.error.count")
        }
    }
}

/// The quieter sibling of `PrimaryButtonStyle`, for the second action on a screen.
struct SecondaryButtonStyle: ButtonStyle {
    var reduceMotion: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Tokens.onSurface.color)
            .background(Tokens.surfaceRaised.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .strokeBorder(Tokens.cardEdge.color, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(Motion.control(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var reduceMotion: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Tokens.onAccent.color)
            .background(Tokens.accent.color)
            // Matches the mode cards and step controls rather than being a capsule. The
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(Motion.control(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
