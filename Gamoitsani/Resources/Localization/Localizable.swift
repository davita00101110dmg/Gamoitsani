import Foundation

public enum L10n {
    /// Add
    public static var add: String { .localized("add") }
    /// Add
    public static var addIt: String { .localized("add_it") }
    /// and
    public static var and: String { .localized("and") }
    /// Back
    public static var back: String { .localized("back") }
    /// Cancel
    public static var cancel: String { .localized("cancel") }
    /// Change
    public static var change: String { .localized("change") }
    /// Close
    public static var close: String { .localized("close") }
    /// Delete
    public static var delete: String { .localized("delete") }
    /// Edit
    public static var edit: String { .localized("edit") }
    /// No
    public static var no: String { .localized("no") }
    /// OK
    public static var ok: String { .localized("ok") }
    /// Point
    public static var point: String { .localized("point") }
    /// Scoreboard
    public static var scoreboard: String { .localized("scoreboard") }
    /// Start
    public static var start: String { .localized("start") }
    /// Thanks
    public static var thanks: String { .localized("thanks") }
    /// Yes
    public static var yesPolite: String { .localized("yesPolite") }
    
    public enum App {
        /// Gamoitsani
        public static var title: String { .localized("app.title") }
    }
    
    public enum Screen {
        
        public enum AddWord {
            /// Word could not be sent
            public static var errorMessage: String { .localized("screen.add_word.error_message") }
            /// Remember to add valid word :)
            public static var hint: String { .localized("screen.add_word.hint") }
            /// In which language are you adding the word?
            public static var languagePickerTitle: String { .localized("screen.add_word.language_picker_title") }
            /// Send
            public static var send: String { .localized("screen.add_word.send") }
            /// Word sent successfully
            public static var successMessage: String { .localized("screen.add_word.success_message") }
            /// Enter the word
            public static var textfieldPlaceholder: String { .localized("screen.add_word.textfield_placeholder") }
            /// Add Word
            public static var title: String { .localized("screen.add_word.title") }
        }
        
        public enum Game {
            
            public enum Arcade {
                /// New words (-2 points)
                public static var skipButton: String { .localized("screen.game.arcade.skipButton") }
            }
            
            public enum ConfirmationAlert {
                /// Teams' points will be lost
                public static var message: String { .localized("screen.game.confirmation_alert.message") }
                /// Are you sure you want to go back?
                public static var title: String { .localized("screen.game.confirmation_alert.title") }
            }
            
            public enum CurrentExtraRound {
                /// (Extra: %@)
                public static func message(_ p1: String) -> String {
                    .localized("screen.game.current_extra_round.message", p1)
                }
            }
            
            public enum CurrentRound {
                /// Round: %@
                public static func message(_ p1: String) -> String {
                    .localized("screen.game.current_round.message", p1)
                }
            }
            
            public enum GameChallengeView {
                /// Random challenge for team
                public static var header: String { .localized("screen.game.game_challenge_view.header") }
            }
            
            public enum GameShareView {
                /// The winning team is %@ 🥳
                public static func title(_ p1: String) -> String {
                    .localized("screen.game.game_share_view.title", p1)
                }
            }
            
            public enum NoMoreWords {
                /// No more words
                public static var message: String { .localized("screen.game.no_more_words.message") }
            }
            
            public enum WinningView {
                /// You won with %@ points
                public static func description(_ p1: String) -> String {
                    .localized("screen.game.winning_view.description", p1)
                }
                /// Repeat
                public static var `repeat`: String { .localized("screen.game.winning_view.repeat") }
                /// Congrats!
                public static var title: String { .localized("screen.game.winning_view.title") }
                
                public enum GameDetails {
                    /// Go Back
                    public static var title: String { .localized("screen.game.winning_view.game_details.title") }
                }
            }
        }
        
        public enum GameDetails {
            /// Create teams
            public static var createTeams: String { .localized("screen.game_details.create_teams") }
            /// Game Details
            public static var title: String { .localized("screen.game_details.title") }
            
            public enum Alert {
                /// Name cannot be empty
                public static var emptyName: String { .localized("screen.game_details.alert.empty_name") }
                /// Invalid parameter
                public static var invalidParameter: String { .localized("screen.game_details.alert.invalid_parameter") }
                /// It is not possible to add more than 5 teams
                public static var maximumTeams: String { .localized("screen.game_details.alert.maximum_teams") }
                /// Add at least 2 teams to start!
                public static var notEnoughTeams: String { .localized("screen.game_details.alert.not_enough_teams") }
                /// Team names must be unique!
                public static var notUniqueTeams: String { .localized("screen.game_details.alert.not_unique_teams") }
                
                public enum NoInternet {
                    /// Internet connection is required to start the game
                    public static var message: String { .localized("screen.game_details.alert.no_internet.message") }
                    /// No internet connection!
                    public static var title: String { .localized("screen.game_details.alert.no_internet.title") }
                }
            }
            
            public enum Arcade {
                /// Play with 5 words at once
                public static var description: String { .localized("screen.game_details.arcade.description") }
                /// Arcade
                public static var title: String { .localized("screen.game_details.arcade.title") }
            }
            
            public enum Classic {
                /// Play one word at a time
                public static var description: String { .localized("screen.game_details.classic.description") }
                /// Classic
                public static var title: String { .localized("screen.game_details.classic.title") }
            }
            
            public enum GameMode {
                /// Game mode
                public static var title: String { .localized("screen.game_details.game_mode.title") }
            }
            
            public enum LoadingWords {
                /// Downloading words in progress
                public static var message: String { .localized("screen.game_details.loading_words.message") }
            }
            
            public enum Players {
                /// Add Player
                public static var add: String { .localized("screen.game_details.players.add") }
                /// Add players to create teams
                public static var addPlaceholder: String { .localized("screen.game_details.players.add_placeholder") }
                /// Are you sure you want to delete this player?
                public static var deleteConfirmation: String { .localized("screen.game_details.players.delete_confirmation") }
                /// Edit Player
                public static var edit: String { .localized("screen.game_details.players.edit") }
                /// Generate Teams
                public static var generateTeams: String { .localized("screen.game_details.players.generate_teams") }
                /// Player with this name already exists
                public static var nameExists: String { .localized("screen.game_details.players.name_exists") }
                /// Player name
                public static var namePlaceholder: String { .localized("screen.game_details.players.name_placeholder") }
                /// Player name cannot be longer than %@ characters
                public static func nameTooLong(_ p1: String) -> String {
                    .localized("screen.game_details.players.name_too_long", p1)
                }
                /// Need at least 2 players to create teams
                public static var notEnough: String { .localized("screen.game_details.players.not_enough") }
                /// Need an even number of players to create teams
                public static var oddCount: String { .localized("screen.game_details.players.odd_count") }
            }
            
            public enum RandomChallenge {
                /// Random challenge for team
                public static var description: String { .localized("screen.game_details.random_challenge.description") }
            }
            
            public enum RoundsAmount {
                /// Amount: %@
                public static func title(_ p1: String) -> String {
                    .localized("screen.game_details.rounds_amount.title", p1)
                }
            }
            
            public enum RoundsLength {
                /// Length: %@ sec
                public static func title(_ p1: String) -> String {
                    .localized("screen.game_details.rounds_length.title", p1)
                }
            }
            
            public enum RoundsSettings {
                /// Round Settings
                public static var title: String { .localized("screen.game_details.rounds_settings.title") }
            }
            
            public enum Section {
                /// Players
                public static var players: String { .localized("screen.game_details.section.players") }
                /// Teams
                public static var teams: String { .localized("screen.game_details.section.teams") }
            }
            
            public enum StartGame {
                /// Start Game
                public static var title: String { .localized("screen.game_details.start_game.title") }
            }
            
            public enum StorageWarning {
                /// Failed to download words, please try again
                public static var message: String { .localized("screen.game_details.storage_warning.message") }
                /// Insufficient storage
                public static var title: String { .localized("screen.game_details.storage_warning.title") }
            }
            
            public enum SuperWord {
                /// Random super word (3 Points)
                public static var description: String { .localized("screen.game_details.super_word.description") }
            }
            
            public enum Teams {
                /// Add a team
                public static var add: String { .localized("screen.game_details.teams.add") }
                /// Add teams to start playing
                public static var addPlaceholder: String { .localized("screen.game_details.teams.add_placeholder") }
                /// Are you sure you want to delete this team?
                public static var deleteConfirmation: String { .localized("screen.game_details.teams.delete_confirmation") }
                /// Edit team's name
                public static var edit: String { .localized("screen.game_details.teams.edit") }
                /// Team with this name already exists
                public static var nameExists: String { .localized("screen.game_details.teams.name_exists") }
                /// Team name
                public static var namePlaceholder: String { .localized("screen.game_details.teams.name_placeholder") }
                /// Team name cannot be longer than %@ characters
                public static func nameTooLong(_ p1: String) -> String {
                    .localized("screen.game_details.teams.name_too_long", p1)
                }
            }
        }
        
        public enum GamePlay {
            
            public enum Alert {
                
                public enum StopRecording {
                    /// Are you sure you want to stop the current recording?
                    public static var message: String { .localized("screen.game_play.alert.stop_recording.message") }
                    /// Stop Recording?
                    public static var title: String { .localized("screen.game_play.alert.stop_recording.title") }
                }
            }
        }
        
        public enum GameScoreboard {
            /// Scoreboard
            public static var title: String { .localized("screen.game_scoreboard.title") }
            
            public enum PerformanceStatRow {
                /// Average Time
                public static var averageTime: String { .localized("screen.game_scoreboard.performance_stat_row.average_time") }
                /// Best Streak
                public static var bestStreak: String { .localized("screen.game_scoreboard.performance_stat_row.best_streak") }
                /// Sets Skipped
                public static var setsSkipped: String { .localized("screen.game_scoreboard.performance_stat_row.sets_skipped") }
            }
            
            public enum PostGameScoreboard {
                /// Average Time
                public static var averageTime: String { .localized("screen.game_scoreboard.post_game_scoreboard.average_time") }
                /// Best Streak
                public static var bestStreak: String { .localized("screen.game_scoreboard.post_game_scoreboard.best_streak") }
                /// Final Score: %@
                public static func finalScore(_ p1: String) -> String {
                    .localized("screen.game_scoreboard.post_game_scoreboard.final_score", p1)
                }
                /// Sets Skipped
                public static var setsSkipped: String { .localized("screen.game_scoreboard.post_game_scoreboard.sets_skipped") }
                /// Words Guessed
                public static var wordsGuessed: String { .localized("screen.game_scoreboard.post_game_scoreboard.words_guessed") }
                /// Words Skipped
                public static var wordsSkipped: String { .localized("screen.game_scoreboard.post_game_scoreboard.words_skipped") }
            }
            
            public enum StatCard {
                /// Words Guessed
                public static var wordsGuessed: String { .localized("screen.game_scoreboard.stat_card.words_guessed") }
                /// Words Skipped
                public static var wordsSkipped: String { .localized("screen.game_scoreboard.stat_card.words_skipped") }
            }
        }
        
        public enum GameShare {
            /// Share to
            public static var shareTo: String { .localized("screen.game_share.share_to") }
            /// Share score!
            public static var title: String { .localized("screen.game_share.title") }
        }
        
        public enum Home {
            
            public enum AddWordButton {
                /// Add word
                public static var title: String { .localized("screen.home.add_word_button.title") }
            }
            
            public enum ChangeLanguage {
                /// Change language
                public static var title: String { .localized("screen.home.change_language.title") }
            }
            
            public enum PlayButton {
                /// Game
                public static var title: String { .localized("screen.home.play_button.title") }
            }
            
            public enum RulesButton {
                /// Rules
                public static var title: String { .localized("screen.home.rules_button.title") }
            }
        }
        
        public enum Rules {
            /// When explaining the word, it is forbidden to use a single word
            public static var rule2: String { .localized("screen.rules.rule2") }
            /// If a team member guesses the word, press the green button (+1 point)
            public static var rule3: String { .localized("screen.rules.rule3") }
            /// If you can't explain the word, or some rule was broken and you want to go to the next word, press the red button (-1 point)
            public static var rule4: String { .localized("screen.rules.rule4") }
            /// The team that collects more points before the time runs out, or the first to reach the set number of points in the round, wins
            public static var rule5: String { .localized("screen.rules.rule5") }
            /// Good luck :)
            public static var rule6: String { .localized("screen.rules.rule6") }
            /// Rules
            public static var title: String { .localized("screen.rules.title") }
        }
        
        public enum Settings {
            /// Help & feedback
            public static var feedback: String { .localized("screen.settings.feedback") }
            /// Language
            public static var language: String { .localized("screen.settings.language") }
            /// Privacy settings
            public static var privacySettings: String { .localized("screen.settings.privacy_settings") }
            /// Rate this app
            public static var rateApp: String { .localized("screen.settings.rate_app") }
            /// Remove ads
            public static var removeAds: String { .localized("screen.settings.remove_ads") }
            /// Restore purchase
            public static var restorePurchase: String { .localized("screen.settings.restore_purchase") }
            /// Share this app
            public static var shareApp: String { .localized("screen.settings.share_app") }
            /// Settings
            public static var title: String { .localized("screen.settings.title") }
            
            public enum CanNotWriteReview {
                /// Please select our app from the AppStore and write a review for us. Thanks!!
                public static var message: String { .localized("screen.settings.can_not_write_review.message") }
                /// Cannot open AppStore
                public static var title: String { .localized("screen.settings.can_not_write_review.title") }
            }
        }
    }
    
    public enum Tutorial {
        static let skip = "screen.tutorial.skip".localized()
        static let next = "screen.tutorial.next".localized()
        static let previous = "screen.tutorial.previous".localized()
        static let finish = "screen.tutorial.finish".localized()
        
        enum RoundsAmount {
            static let title = "screen.tutorial.rounds_amount.title".localized()
            static let message = "screen.tutorial.rounds_amount.message".localized()
        }
        
        enum RoundsLength {
            static let title = "screen.tutorial.rounds_length.title".localized()
            static let message = "screen.tutorial.rounds_length.message".localized()
        }
        
        enum GameMode {
            static let title = "screen.tutorial.game_mode.title".localized()
            static let message = "screen.tutorial.game_mode.message".localized()
        }
        
        enum SuperWord {
            static let title = "screen.tutorial.super_word.title".localized()
            static let message = "screen.tutorial.super_word.message".localized()
        }
        
        enum RandomChallenge {
            static let title = "screen.tutorial.random_challenge.title".localized()
            static let message = "screen.tutorial.random_challenge.message".localized()
        }
        
        enum AddTeams {
            static let title = "screen.tutorial.add_teams.title".localized()
            static let message = "screen.tutorial.add_teams.message".localized()
        }
    }
}
