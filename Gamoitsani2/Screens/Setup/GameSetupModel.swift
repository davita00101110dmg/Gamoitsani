//
//  GameSetupModel.swift
//  Gamoitsani2
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
