//
//  GameSetupModel.swift
//  Gamoitsani
//
import Foundation
import Observation
import GamoitsaniCore
import GamoitsaniL10n

/// State for the setup screen.
@MainActor
@Observable
final class GameSetupModel {

    var settings: GameSettings
    private(set) var teams: [Team]

    /// Names being edited, keyed by team id. Kept separate from `teams` so a half-typed
    /// name never has to be a valid `Team`.
    private(set) var draftNames: [UUID: String] = [:]

    /// Teams still carrying a generated name the player has not touched.
    private var untouchedNames: Set<UUID> = []

    private var language: AppLanguage

    /// Which way the teams are being built.
    var buildMode: TeamBuildMode = .byHand

    /// The room, kept on the model rather than the view so switching modes back and forth
    /// does not lose the roster someone just typed in.
    private(set) var players: [String] = []
    var drawTeamCount = GameSettings.teamCountRange.lowerBound

    init(settings: GameSettings = GameSettings(), teams: [Team]? = nil,
         language: AppLanguage = Localization.storedLanguage) {
        self.settings = settings
        self.language = language
        self.teams = teams ?? Self.defaultTeams(language: language)
        for team in self.teams { draftNames[team.id] = team.name }
        // Only names this type generated are eligible for relabelling.
        if teams == nil { untouchedNames = Set(self.teams.map(\.id)) }
    }

    private static func defaultTeams(language: AppLanguage) -> [Team] {
        (1...GameSettings.teamCountRange.lowerBound).map {
            Team(name: defaultName(number: $0, language: language))
        }
    }

    /// Default names are formed in the app's language, so a Georgian player gets
    /// "გუნდი 1" rather than "Team 1".
    private static func defaultName(number: Int, language: AppLanguage) -> String {
        "\(L10n.string("setup.teamDefault", language: language)) \(number)"
    }

    // MARK: - Validation

    /// Teams with their current draft names applied, which is what actually gets played.
    var resolvedTeams: [Team] {
        teams.map { team in
            var copy = team
            copy.name = (draftNames[team.id] ?? team.name).trimmingCharacters(in: .whitespacesAndNewlines)
            return copy
        }
    }

    var validationErrors: [TeamValidationError] {
        TeamValidator.validate(resolvedTeams)
    }

    var canStart: Bool { validationErrors.isEmpty }

    /// Whether a specific row should be marked. v1 dropped invalid names silently with no
    /// alert at all, so nothing told the player which row was the problem.
    func problem(for team: Team) -> TeamValidationError? {
        let name = (draftNames[team.id] ?? team.name).trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return .emptyName }
        if name.count > GameSettings.maxTeamNameLength {
            return .nameTooLong(name, maximum: GameSettings.maxTeamNameLength)
        }
        let duplicates = resolvedTeams.filter { $0.name.lowercased() == name.lowercased() }
        return duplicates.count > 1 ? .duplicateName(name) : nil
    }

    // MARK: - Teams

    var canAddTeam: Bool { teams.count < GameSettings.teamCountRange.upperBound }
    var canRemoveTeam: Bool { teams.count > GameSettings.teamCountRange.lowerBound }

    /// Called whenever the player types in a team's field. The first edit opts that team
    /// out of language-driven relabelling.
    /// Still carrying the name this type generated. Drawn muted, the way an unfilled
    /// field is, which is what says it can be renamed without adding any chrome.
    func isUsingDefaultName(_ team: Team) -> Bool { untouchedNames.contains(team.id) }

    func setName(_ name: String, for team: Team) {
        draftNames[team.id] = name
        untouchedNames.remove(team.id)
    }

    /// Relabels generated names into the new language.
    func applyLanguage(_ language: AppLanguage) {
        guard language != self.language else { return }
        self.language = language

        // Renumber from scratch so the sequence stays 1, 2, 3 in the new language rather
        // than inheriting gaps from whatever the old names parsed to.
        var next = 1
        for index in teams.indices where untouchedNames.contains(teams[index].id) {
            let name = Self.defaultName(number: next, language: language)
            teams[index].name = name
            draftNames[teams[index].id] = name
            next += 1
        }
    }

    func addTeam() {
        guard canAddTeam else { return }
        // Smallest unused number, not teams.count + 1. The count stops matching the names
        let number = TeamNaming.nextNumber(afterNames: resolvedTeams.map(\.name))
        let team = Team(name: Self.defaultName(number: number, language: language))
        teams.append(team)
        draftNames[team.id] = team.name
        untouchedNames.insert(team.id)
    }

    func removeTeam(_ team: Team) {
        guard canRemoveTeam else { return }
        teams.removeAll { $0.id == team.id }
        draftNames[team.id] = nil
        untouchedNames.remove(team.id)
    }

    // MARK: - Drawing

    /// How many teams the current roster can fill, or nil if there are too few players.
    var drawRange: ClosedRange<Int>? { TeamDraw.teamCountRange(forPlayers: players.count) }

    var canDraw: Bool { drawRange != nil }

    /// Adds a player, reporting whether it took — a blank or repeated name does not.
    @discardableResult
    func addPlayer(_ name: String) -> Bool {
        let tidied = TeamDraw.tidy(players + [name])
        guard tidied.count > players.count else { return false }
        players = tidied
        clampDrawTeamCount()
        return true
    }

    func removePlayer(_ name: String) {
        players.removeAll { $0 == name }
        clampDrawTeamCount()
    }

    /// Redraws and replaces the teams outright. Merging with the existing ones would
    /// double people up, since the roster is the whole line-up.
    func shuffleTeams() {
        let draw = TeamDraw.draw(players: players, into: drawTeamCount)
        guard !draw.isEmpty else { return }

        teams.removeAll()
        draftNames.removeAll()
        untouchedNames.removeAll()

        for (index, members) in draw.enumerated() {
            let team = Team(
                name: Self.defaultName(number: index + 1, language: language),
                members: members
            )
            teams.append(team)
            draftNames[team.id] = team.name
            untouchedNames.insert(team.id)
        }
    }

    // MARK: - Editing a line-up

    /// A drawn line-up is a starting point, not a verdict. Someone leaves, someone swaps —
    /// redoing the whole roster to fix one slot is not a reasonable ask.
    ///
    /// `players` is kept in step throughout, so the roster and the teams never disagree
    /// and a later shuffle deals exactly the people now on teams.
    @discardableResult
    func addMember(_ name: String, to teamID: Team.ID) -> Bool {
        let tidied = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tidied.isEmpty,
              let index = teams.firstIndex(where: { $0.id == teamID }),
              !isPlaying(tidied)
        else { return false }

        teams[index].members.append(tidied)
        players = TeamDraw.tidy(players + [tidied])
        clampDrawTeamCount()
        return true
    }

    func removeMember(_ name: String, from teamID: Team.ID) {
        guard let index = teams.firstIndex(where: { $0.id == teamID }) else { return }
        teams[index].members.removeAll { $0 == name }
        // They left the room, so they should not reappear in the next shuffle.
        players.removeAll { $0 == name }
        clampDrawTeamCount()
    }

    /// Moves a player to another team, taking them off whichever one they were on.
    func moveMember(_ name: String, to teamID: Team.ID) {
        guard let destination = teams.firstIndex(where: { $0.id == teamID }) else { return }
        for index in teams.indices { teams[index].members.removeAll { $0 == name } }
        teams[destination].members.append(name)
    }

    /// Whether someone is already on a team, compared the way `TeamDraw` compares names.
    private func isPlaying(_ name: String) -> Bool {
        teams.contains { $0.members.contains { $0.lowercased() == name.lowercased() } }
    }

    func adjustDrawTeamCount(by delta: Int) {
        drawTeamCount += delta
        clampDrawTeamCount()
    }

    var canDecreaseDrawTeams: Bool { (drawRange?.lowerBound).map { drawTeamCount > $0 } ?? false }
    var canIncreaseDrawTeams: Bool { (drawRange?.upperBound).map { drawTeamCount < $0 } ?? false }

    /// Losing players can put the count above what the room can now fill.
    private func clampDrawTeamCount() {
        guard let range = drawRange else { return }
        drawTeamCount = min(max(drawTeamCount, range.lowerBound), range.upperBound)
    }

    func index(of team: Team) -> Int {
        teams.firstIndex(where: { $0.id == team.id }) ?? 0
    }

    // MARK: - Settings

    var roundLengthSeconds: Int { Int(settings.roundLength) }

    func adjustRounds(by delta: Int) {
        settings.setRounds(settings.rounds + delta)
    }

    func adjustRoundLength(by steps: Int) {
        settings.setRoundLength(settings.roundLength + Double(steps * GameSettings.roundLengthStep))
    }

    var canDecreaseRounds: Bool { settings.rounds > GameSettings.roundsRange.lowerBound }
    var canIncreaseRounds: Bool { settings.rounds < GameSettings.roundsRange.upperBound }
    var canDecreaseLength: Bool { roundLengthSeconds > GameSettings.roundLengthRange.lowerBound }
    var canIncreaseLength: Bool { roundLengthSeconds < GameSettings.roundLengthRange.upperBound }
}

/// The two ways to end up with teams.
enum TeamBuildMode: String, CaseIterable, Identifiable {
    case byHand
    case draw

    var id: String { rawValue }
    var titleKey: String { "teams.mode.\(rawValue)" }
}
