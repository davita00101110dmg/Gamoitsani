// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name
public enum L10n {
    /// Add
    public static var add: String { L10n.tr("Localizable", "add") }
    /// Add
    public static var addIt: String { L10n.tr("Localizable", "add_it") }
    /// and
    public static var and: String { L10n.tr("Localizable", "and") }
    /// Cancel
    public static var cancel: String { L10n.tr("Localizable", "cancel") }
    /// Change
    public static var change: String { L10n.tr("Localizable", "change") }
    /// Delete
    public static var delete: String { L10n.tr("Localizable", "delete") }
    /// Edit
    public static var edit: String { L10n.tr("Localizable", "edit") }
    /// No
    public static var no: String { L10n.tr("Localizable", "no") }
    /// OK
    public static var ok: String { L10n.tr("Localizable", "ok") }
    /// Point
    public static var point: String { L10n.tr("Localizable", "point") }
    /// Scoreboard
    public static var scoreboard: String { L10n.tr("Localizable", "scoreboard") }
    /// Start
    public static var start: String { L10n.tr("Localizable", "start") }
    /// Thanks
    public static var thanks: String { L10n.tr("Localizable", "thanks") }
    /// Yes
    public static var yesPolite: String { L10n.tr("Localizable", "yesPolite") }

    public enum App {
      /// Gamoitsani
      public static var title: String { L10n.tr("Localizable", "app.title") }
    }

    public enum Screen {

      public enum Game {

        public enum ConfirmationAlert {
          /// In this case, the teams' points will be lost
          public static var message: String { L10n.tr("Localizable", "screen.game.confirmation_alert.message") }
          /// Are you sure you want to go back?
          public static var title: String { L10n.tr("Localizable", "screen.game.confirmation_alert.title") }
        }

        public enum CurrentRound {
          /// Round: %@
          public static func message( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game.current_round.message", p1)
          }
        }

        public enum WinningAlert {
          /// You won with %@ points
          public static func message( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game.winning_alert.message", p1)
          }
          /// Congratulations %@
          public static func title( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game.winning_alert.title", p1)
          }
        }
      }

      public enum GameSettings {
        /// Game Settings
        public static var title: String { L10n.tr("Localizable", "screen.game_settings.title") }

        public enum AddTeamAlert {
          /// Enter team name
          public static var message: String { L10n.tr("Localizable", "screen.game_settings.add_team_alert.message") }
          /// Add team
          public static var title: String { L10n.tr("Localizable", "screen.game_settings.add_team_alert.title") }
        }

        public enum IncorrectGameSettingsNotEnoughTeams {
          /// Not enough teams, you need to add at least 2 teams to start the game!
          public static var message: String { L10n.tr("Localizable", "screen.game_settings.incorrect_game_settings_not_enough_teams.message") }
        }

        public enum IncorrectGameSettingsNotUniqueTeams {
          /// Team names must be unique!
          public static var message: String { L10n.tr("Localizable", "screen.game_settings.incorrect_game_settings_not_unique_teams.message") }
        }

        public enum IncorrectParameter {
          /// Incorrect parameter
          public static var title: String { L10n.tr("Localizable", "screen.game_settings.incorrect_parameter.title") }
        }

        public enum RoundsAmount {
          /// Rounds Amount: %@
          public static func title( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game_settings.rounds_amount.title", p1)
          }
        }

        public enum RoundsLength {
          /// Round Length: %@ sec
          public static func title( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game_settings.rounds_length.title", p1)
          }
        }

        public enum StartGame {
          /// Start Game
          public static var title: String { L10n.tr("Localizable", "screen.game_settings.start_game.title") }
        }

        public enum Teams {
          /// Teams
          public static var title: String { L10n.tr("Localizable", "screen.game_settings.teams.title") }
        }

        public enum UpdateTeamNameAlert {
          /// Update team name
          public static var title: String { L10n.tr("Localizable", "screen.game_settings.update_team_name_alert.title") }
        }
      }

      public enum Home {

        public enum ChangeLanguage {
          /// Change language
          public static var title: String { L10n.tr("Localizable", "screen.home.change_language.title") }
        }

        public enum PlayButton {
          /// Start Game
          public static var title: String { L10n.tr("Localizable", "screen.home.play_button.title") }
        }

        public enum RulesButton {
          /// Rules
          public static var title: String { L10n.tr("Localizable", "screen.home.rules_button.title") }
        }

        public enum SettingsButton {
          /// Settings
          public static var title: String { L10n.tr("Localizable", "screen.home.settings_button.title") }
        }
      }

      public enum Rules {
        /// ・When explaining the word, it is forbidden to use a single word \n\n ・If a team member guesses the word, press the ✅ button (+1 point) \n\n ・If you can't explain the word, or some rule was broken and you want to go to the next word, press the ❌ button (-1 point) \n\n ・The team that collects more points before the time runs out, or the first to reach the set number of points in the round, wins. \n\n Good luck :)
        public static var rules: String { L10n.tr("Localizable", "screen.rules.rules") }
        /// Rules
        public static var title: String { L10n.tr("Localizable", "screen.rules.title") }
      }
    }
}
// swiftlint:enable explicit_type_interface identifier_name line_length nesting type_body_length type_name

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    return String(format: key.localized(), locale: Locale.current, arguments: args)
  }
}

private final class BundleToken { }
