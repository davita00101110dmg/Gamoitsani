//
//  ShareCard.swift
//  Gamoitsani2
//
import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniL10n

/// The image a finished game produces.
///
/// Not a scoreboard. Nobody screenshots a table of numbers — what gets sent to the group
/// chat is who won and which title someone can be teased about, so the awards carry as
/// much of the card as the scores do.
///
/// Fixed dark field in both appearances: this leaves the app and lands in someone else's
/// feed, where it should look the way it was designed rather than the way the sender's
/// phone was set.
struct ShareCard: View {
    let standings: [Team]
    let teams: [Team]
    let awards: [Award]
    let mode: GameMode
    let rounds: Int

    @Environment(Localization.self) private var l10n

    /// Portrait, close to 4:5 — the shape that survives Instagram and Messages without
    /// being cropped.
    static let size = CGSize(width: 360, height: 450)

    private var winner: Team? { standings.first }

    var body: some View {
        VStack(spacing: 0) {
            // The mark reads at this size. In the footer at 22pt it was a blob — field,
            // three cards and a glyph with no room to be any of them.
            VStack(spacing: Spacing.xxs) {
                AppMark()
                    .frame(width: 38, height: 38)

                Text(l10n("home.title"))
                    .font(Typography.label)
                    .tracking(2)
                    .foregroundStyle(Brand.markCardFace.color.opacity(CardInk.quiet))
            }
            .padding(.top, Spacing.md)

            Spacer(minLength: 0)

            if let winner {
                VStack(spacing: Spacing.xxs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(color(for: winner))

                    Text(winner.name)
                        .font(Typography.display(30))
                        .foregroundStyle(color(for: winner))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text("\(winner.score)")
                        .font(Typography.numeral(44))
                        .foregroundStyle(Brand.markCardFace.color)
                }
            }

            Spacer(minLength: 0)

            // Everyone else, so the card is a result and not a boast.
            if standings.count > 1 {
                VStack(spacing: Spacing.xxs) {
                    ForEach(Array(standings.dropFirst().prefix(4).enumerated()), id: \.element.id) { index, team in
                        HStack(spacing: Spacing.xs) {
                            Text("\(index + 2)")
                                .font(Typography.label)
                                .foregroundStyle(Brand.markCardFace.color.opacity(CardInk.faint))
                                .frame(width: 14, alignment: .leading)

                            Circle()
                                .fill(color(for: team))
                                .frame(width: 7, height: 7)

                            Text(team.name)
                                .font(Typography.label)
                                .foregroundStyle(Brand.markCardFace.color.opacity(CardInk.strong))
                                .lineLimit(1)

                            Spacer(minLength: Spacing.xs)

                            Text("\(team.score)")
                                .font(Typography.numeral(15))
                                .foregroundStyle(Brand.markCardFace.color.opacity(CardInk.strong))
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }

            Spacer(minLength: 0)

            if !awards.isEmpty {
                VStack(spacing: Spacing.xxs) {
                    ForEach(awards) { award in
                        AwardChip(award: award, tint: color(forTeam: award.teamID))
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            Spacer(minLength: 0)

            Text(footer)
                .font(Typography.caption)
                .foregroundStyle(Brand.markCardFace.color.opacity(CardInk.quiet))
                .padding(.bottom, Spacing.md)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Brand.markField.color)
    }

    private var footer: String {
        let modeName = mode == .arcade ? l10n("mode.arcade") : l10n("mode.classic")
        return "\(modeName) · \(rounds) \(l10n("setup.rounds").lowercased())"
    }

    private func color(for team: Team) -> Color {
        color(forTeam: team.id)
    }

    private func color(forTeam id: Team.ID) -> Color {
        let index = teams.firstIndex { $0.id == id } ?? 0
        return TeamPalette.color(at: index).color
    }
}

/// The card's own ink levels.
///
/// It sits on a fixed dark field in both appearances — it leaves the app and lands in
/// someone else's feed — so it cannot use the surface tokens, which follow the phone's
/// appearance. Named rather than written inline so the hierarchy is a decision, and the
/// next value added has somewhere to belong.
private enum CardInk {
    /// Runner-up names and scores. Headline figures take the colour undimmed.
    static let strong: Double = 0.85
    /// Award titles.
    static let regular: Double = 0.75
    /// Wordmark and footer chrome.
    static let quiet: Double = 0.5
    /// Rank numbers beside the runners-up.
    static let faint: Double = 0.4
    /// The tint behind an award chip.
    static let fill: Double = 0.07
}

/// One earned title.
private struct AwardChip: View {
    let award: Award
    let tint: Color

    @Environment(Localization.self) private var l10n
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: award.kind.symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 14)

            Text(l10n(award.kind.titleKey))
                .font(Typography.caption)
                .foregroundStyle(Brand.markCardFace.color.opacity(CardInk.regular))

            Spacer(minLength: Spacing.xxs)

            Text(award.formattedValue(in: locale))
                .font(Typography.numeral(13))
                .foregroundStyle(Brand.markCardFace.color)

            Text(award.teamName)
                .font(Typography.caption)
                .foregroundStyle(tint)
                .lineLimit(1)
                .frame(maxWidth: 96, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Brand.markCardFace.color.opacity(CardInk.fill))
        .clipShape(Capsule())
    }
}

extension Award.Kind {
    var symbol: String {
        switch self {
        case .streak: "flame.fill"
        case .words: "checkmark.seal.fill"
        case .speed: "bolt.fill"
        case .superWords: "star.fill"
        case .skips: "xmark.circle.fill"
        }
    }

    var titleKey: String { "award.\(rawValue)" }
}

extension Award {
    /// Seconds read as "2.1s"; everything else is a plain count.
    ///
    /// Formatted against the locale it is given rather than `String(format:)`, which is
    /// always English — a card in Georgian on a French phone had an English decimal point
    /// in the middle of it, and large counts never grouped their digits.
    func formattedValue(in locale: Locale) -> String {
        kind == .speed
            ? "\(value.formatted(.number.precision(.fractionLength(1)).locale(locale)))s"
            : Int(value).formatted(.number.locale(locale))
    }
}

/// Wraps the rendered card so the share sheet gets real PNG data and a sensible filename.
struct ShareableCard: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            card.image.pngData() ?? Data()
        }
        .suggestedFileName("gamoitsani.png")
    }
}
