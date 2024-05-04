// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// and
  public static let and = L10n.tr("Localizable", "and", fallback: "and")
  /// Yes
  public static let yes = L10n.tr("Localizable", "yes", fallback: "Yes")
  public enum App {
    /// Localizable.strings
    ///   Gamoitsani
    /// 
    ///   Created by Daviti Khvedelidze on 23/04/2024.
    ///   Copyright © 2024 Daviti Khvedelidze. All rights reserved.
    public static let title = L10n.tr("Localizable", "app.title", fallback: "Gamoitsani")
  }
  public enum Screen {
    public enum GameSettings {
      /// Game Settings
      public static let title = L10n.tr("Localizable", "screen.game_settings.title", fallback: "Game Settings")
      public enum RoundsAmount {
        /// Rounds Amount: %@
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "screen.game_settings.rounds_amount.title", String(describing: p1), fallback: "Rounds Amount: %@")
        }
      }
      public enum RoundsLength {
        /// Round Length: %@ sec
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "screen.game_settings.rounds_length.title", String(describing: p1), fallback: "Round Length: %@ sec")
        }
      }
      public enum Teams {
        /// Teams
        public static let title = L10n.tr("Localizable", "screen.game_settings.teams.title", fallback: "Teams")
      }
    }
    public enum Home {
      public enum ChangeLanguage {
        /// Change language
        public static let title = L10n.tr("Localizable", "screen.home.change_language.title", fallback: "Change language")
      }
      public enum PlayButton {
        /// Start Game
        public static let title = L10n.tr("Localizable", "screen.home.play_button.title", fallback: "Start Game")
      }
      public enum RulesButton {
        /// Rules
        public static let title = L10n.tr("Localizable", "screen.home.rules_button.title", fallback: "Rules")
      }
      public enum SettingsButton {
        /// Settings
        public static let title = L10n.tr("Localizable", "screen.home.settings_button.title", fallback: "Settings")
      }
    }
    public enum Rules {
      /// ・When explaining the word, it is forbidden to use a single word 
      /// 
      ///  ・If a team member guesses the word, press the ✅ button (+1 point) 
      /// 
      ///  ・If you can't explain the word, or some rule was broken and you want to go to the next word, press the ❌ button (-1 point) 
      /// 
      ///  ・The team that collects more points before the time runs out, or the first to reach the set number of points in the round, wins. 
      /// 
      ///  Good luck :)
      public static let rules = L10n.tr("Localizable", "screen.rules.rules", fallback: "・When explaining the word, it is forbidden to use a single word \n\n ・If a team member guesses the word, press the ✅ button (+1 point) \n\n ・If you can't explain the word, or some rule was broken and you want to go to the next word, press the ❌ button (-1 point) \n\n ・The team that collects more points before the time runs out, or the first to reach the set number of points in the round, wins. \n\n Good luck :)")
      /// Rules
      public static let title = L10n.tr("Localizable", "screen.rules.title", fallback: "Rules")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
