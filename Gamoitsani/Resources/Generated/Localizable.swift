// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name
public enum L10n {
    /// and
    public static var and: String { L10n.tr("Localizable", "and") }

    public enum App {
      /// Gamoitsani
      public static var title: String { L10n.tr("Localizable", "app.title") }
    }

    public enum Screen {

      public enum GameSettings {
        /// Game Settings
        public static var title: String { L10n.tr("Localizable", "screen.game_settings.title") }

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

        public enum Teams {
          /// Teams
          public static var title: String { L10n.tr("Localizable", "screen.game_settings.teams.title") }
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
