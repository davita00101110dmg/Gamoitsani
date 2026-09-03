//
//  PlayerRoster.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniL10n

/// Everyone in the room, and the shuffle that turns them into teams.
///
/// Inline rather than behind a sheet: the drawn teams appear in the rows directly below,
/// so pushing the roster into a modal hid the result of the thing being done.
struct PlayerRoster: View {
    @Bindable var model: GameSetupModel

    @Environment(Localization.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SoundPlayer.self) private var sound

    @State private var entry = ""
    @FocusState private var entryFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                TextField(l10n("players.placeholder"), text: $entry)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Tokens.onSurface.color)
                    .textInputAutocapitalization(.words)
                    .focused($entryFocused)
                    .submitLabel(.next)
                    // Keeps focus, so a whole room goes in without reaching for the field
                    // between names.
                    .onSubmit(add)

                Button(action: add) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(entry.isEmpty ? Tokens.onSurfaceMuted.color.opacity(0.5) : Tokens.accent.color)
                }
                .disabled(entry.isEmpty)
                .accessibilityLabel(l10n("players.placeholder"))
            }
            .padding(.vertical, Spacing.sm)

            if !model.players.isEmpty {
                Divider().overlay(Tokens.cardEdge.color)

                FlowLayout(spacing: Spacing.xs) {
                    ForEach(model.players, id: \.self) { name in
                        PlayerChip(name: name) {
                            withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                                model.removePlayer(name)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.sm)
            }

            if model.canDraw {
                Divider().overlay(Tokens.cardEdge.color)
                StepperRow(
                    label: l10n("players.teamCount"),
                    value: "\(model.drawTeamCount)",
                    canDecrease: model.canDecreaseDrawTeams,
                    canIncrease: model.canIncreaseDrawTeams,
                    decrease: { model.adjustDrawTeamCount(by: -1) },
                    increase: { model.adjustDrawTeamCount(by: 1) }
                )
            }

            Divider().overlay(Tokens.cardEdge.color)

            Button(action: shuffle) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "shuffle")
                    Text(model.players.isEmpty || !hasDrawn ? l10n("players.draw") : l10n("players.redraw"))
                }
                .font(Typography.rowTitle)
                .foregroundStyle(model.canDraw ? Tokens.accent.color : Tokens.onSurfaceMuted.color.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.sm)
                .contentShape(Rectangle())
            }
            .disabled(!model.canDraw)

            if !model.canDraw {
                Text(l10n("players.needMore"))
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Spacing.sm)
            }
        }
    }

    private var hasDrawn: Bool { model.teams.contains { !$0.members.isEmpty } }

    private func add() {
        guard model.addPlayer(entry) else {
            // Blank or already listed. Clearing the field says so without an alert.
            entry = ""
            return
        }
        withAnimation(Motion.control(reduceMotion: reduceMotion)) { entry = "" }
        entryFocused = true
    }

    private func shuffle() {
        sound.play(.tick)
        withAnimation(Motion.card(reduceMotion: reduceMotion)) { model.shuffleTeams() }
    }
}

private struct PlayerChip: View {
    let name: String
    let remove: () -> Void

    var body: some View {
        Button(action: remove) {
            HStack(spacing: Spacing.xxs) {
                Text(name)
                    .font(Typography.label)
                    .foregroundStyle(Tokens.onSurface.color)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Tokens.surface.color)
            .clipShape(Capsule())
            .overlay { Capsule().strokeBorder(Tokens.cardEdge.color, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityHint(Text(verbatim: "Remove"))
    }
}

/// Wrapping row layout. `LazyVGrid` cannot do this — its columns are fixed widths, and
/// names are not.
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let rows = arrange(subviews: subviews, width: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if x + size.width > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

/// A team's line-up, editable in place.
///
/// Tapping someone opens the moves available to them. Making the chip a menu rather than a
/// delete button is what lets a player be swapped between teams without redoing the draw —
/// the case a drawn line-up runs into first.
struct TeamRoster: View {
    @Bindable var model: GameSetupModel
    let team: Team

    @Environment(Localization.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAdding = false
    @State private var newMember = ""

    var body: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(team.members, id: \.self) { name in
                Menu {
                    ForEach(model.teams.filter { $0.id != team.id }) { other in
                        Button {
                            withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                                model.moveMember(name, to: other.id)
                            }
                        } label: {
                            Label(other.name, systemImage: "arrow.right")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                            model.removeMember(name, from: team.id)
                        }
                    } label: {
                        Label(l10n("players.remove"), systemImage: "trash")
                    }
                } label: {
                    MemberChip(name: name, tint: TeamPalette.color(at: model.index(of: team)).color)
                }
            }

            Button { isAdding = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Tokens.accent.color)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .overlay { Capsule().strokeBorder(Tokens.cardEdge.color, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n("players.add"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert(l10n("players.add"), isPresented: $isAdding) {
            TextField(l10n("players.placeholder"), text: $newMember)
                .textInputAutocapitalization(.words)
            Button(l10n("common.cancel"), role: .cancel) { newMember = "" }
            Button(l10n("players.add")) {
                withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                    model.addMember(newMember, to: team.id)
                }
                newMember = ""
            }
        }
    }
}

private struct MemberChip: View {
    let name: String
    let tint: Color

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(name)
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurface.color)
            Image(systemName: "chevron.down")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Tokens.onSurfaceMuted.color)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(tint.opacity(0.14))
        .clipShape(Capsule())
    }
}
