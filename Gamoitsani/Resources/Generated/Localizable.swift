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
    /// Back
    public static var back: String { L10n.tr("Localizable", "back") }
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

      public enum AddWord {
        /// Remember to add valid word :)
        public static var hint: String { L10n.tr("Localizable", "screen.add_word.hint") }
        /// Send
        public static var send: String { L10n.tr("Localizable", "screen.add_word.send") }
        /// Add Word
        public static var title: String { L10n.tr("Localizable", "screen.add_word.title") }
      }

      public enum Game {

        public enum ConfirmationAlert {
          /// Teams' points will be lost
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

        public enum NoMoreWords {
          /// No more words
          public static var message: String { L10n.tr("Localizable", "screen.game.no_more_words.message") }
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

      public enum GameDetails {
        /// Game Details
        public static var title: String { L10n.tr("Localizable", "screen.game_details.title") }

        public enum AddTeamAlert {
          /// Add a team
          public static var title: String { L10n.tr("Localizable", "screen.game_details.add_team_alert.title") }
        }

        public enum EditTeamNameAlert {
          /// Edit team's name
          public static var title: String { L10n.tr("Localizable", "screen.game_details.edit_team_name_alert.title") }
        }

        public enum InvalidGameDetailsEmptyTeamName {
          /// Team name cannot be empty
          public static var message: String { L10n.tr("Localizable", "screen.game_details.invalid_game_details_empty_team_name.message") }
        }

        public enum InvalidGameDetailsMaximumTeams {
          /// It is not possible to add more than 5 teams
          public static var message: String { L10n.tr("Localizable", "screen.game_details.invalid_game_details_maximum_teams.message") }
        }

        public enum InvalidGameDetailsNotEnoughTeams {
          /// Add at least 2 teams to start!
          public static var message: String { L10n.tr("Localizable", "screen.game_details.invalid_game_details_not_enough_teams.message") }
        }

        public enum InvalidGameDetailsNotUniqueTeams {
          /// Team names must be unique!
          public static var message: String { L10n.tr("Localizable", "screen.game_details.invalid_game_details_not_unique_teams.message") }
        }

        public enum InvalidParameter {
          /// Invalid parameter
          public static var title: String { L10n.tr("Localizable", "screen.game_details.invalid_parameter.title") }
        }

        public enum NoInternetConnectionAlert {
          /// Internet connection is required to start the game
          public static var message: String { L10n.tr("Localizable", "screen.game_details.no_internet_connection_alert.message") }
          /// No internet connection!
          public static var title: String { L10n.tr("Localizable", "screen.game_details.no_internet_connection_alert.title") }
        }

        public enum RoundsAmount {
          /// Rounds: %@
          public static func title( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game_details.rounds_amount.title", p1)
          }
        }

        public enum RoundsLength {
          /// Round Length: %@ sec
          public static func title( _ p1: String) -> String {
              return L10n.tr("Localizable", "screen.game_details.rounds_length.title", p1)
          }
        }

        public enum StartGame {
          /// Start Game
          public static var title: String { L10n.tr("Localizable", "screen.game_details.start_game.title") }
        }

        public enum Teams {
          /// Teams
          public static var title: String { L10n.tr("Localizable", "screen.game_details.teams.title") }
        }
      }

      public enum Home {

        public enum AddWordButton {
          /// Add word
          public static var title: String { L10n.tr("Localizable", "screen.home.add_word_button.title") }
        }

        public enum ChangeLanguage {
          /// Change language
          public static var title: String { L10n.tr("Localizable", "screen.home.change_language.title") }
        }

        public enum PlayButton {
          /// Game
          public static var title: String { L10n.tr("Localizable", "screen.home.play_button.title") }
        }

        public enum RulesButton {
          /// Rules
          public static var title: String { L10n.tr("Localizable", "screen.home.rules_button.title") }
        }
      }

      public enum Rules {
        /// Note that at this moment you can only play with Georgian words⚠️
        public static var rule1: String { L10n.tr("Localizable", "screen.rules.rule1") }
        /// When explaining the word, it is forbidden to use a single word
        public static var rule2: String { L10n.tr("Localizable", "screen.rules.rule2") }
        /// If a team member guesses the word, press the green button (+1 point)
        public static var rule3: String { L10n.tr("Localizable", "screen.rules.rule3") }
        /// If you can't explain the word, or some rule was broken and you want to go to the next word, press the red button (-1 point)
        public static var rule4: String { L10n.tr("Localizable", "screen.rules.rule4") }
        /// The team that collects more points before the time runs out, or the first to reach the set number of points in the round, wins
        public static var rule5: String { L10n.tr("Localizable", "screen.rules.rule5") }
        /// Good luck :)
        public static var rule6: String { L10n.tr("Localizable", "screen.rules.rule6") }
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
