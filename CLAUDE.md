# Gamoitsani — CLAUDE.md

> **Working on 2.0? Read `docs/2.0/HANDOFF.md` first.** It has current state, settled
> decisions, and the traps this codebase has already hit. `docs/2.0/PLAN.md` is the
> architecture behind it.

Georgian party word-guessing game (Taboo/Alias-style). iOS app in production on the App Store; Android port in progress (separate repo/target).

## Tech stack
- Swift, SwiftUI + UIKit (coordinator pattern for UIKit screens)
- CoreData for local storage (model version 2.0)
- Firebase Firestore for word data backend
- CocoaPods for dependency management — **always open `Gamoitsani.xcworkspace`, never the `.xcodeproj`**
- Custom font: Mersad (variable typeface)
- Ad mediation: IronSource, Google Mobile Ads, Vungle, InMobi, Facebook Audience Network, Chartboost, Unity Ads, MTGSDK

## Project structure
- `Gamoitsani.xcworkspace` — open this in Xcode, not the `.xcodeproj`
- `Gamoitsani/` — app source
- `GamoitsaniTests/` — unit tests
- `GamoitsaniUITests/` — UI tests
- `Pods/` — CocoaPods dependencies (do not hand-edit)
- `Podfile` / `Podfile.lock` — dependency manifest

## Architecture & conventions
- MVVM-leaning; ViewModels follow a consistent state machine pattern: `INFO → CHALLENGE → COUNTDOWN → PLAY → GAME_OVER`
- `GameStory` acts as shared game state across the app
- Two game modes: **Classic** (one word at a time) and **Arcade** (five simultaneous words, swipe mechanics, skip penalty)
- Localization: String Catalogs (`.xcstrings`), NOT `.strings` files. Uses a custom `LanguageManager` + `LocaleEnvironment` modifier + `.localized()` helper — **do not use `String(localized:)` directly**, it reads system locale, not the app's in-app language switch. Force view reconstruction with `.id()` modifiers when language changes.
- Supported languages: Georgian, English, Ukrainian, Turkish, Armenian, Azerbaijani, German, Spanish, French, Japanese, Russian
- Localization keys organized as nested enums, e.g. `L10n.Screen.Settings.title`, in `Localizable.swift`

## CoreData
- Model is on version 2.0. Key metadata fields on word entities: `isGeorgianOrigin`, `formalityLevel`, `isProperNoun`, `wordType`, `isAbstract`, `ageAppropriateness`, `relatedWordsData`
- Migrations: always confirm `shouldMigrateStoreAutomatically` and `shouldInferMappingModelAutomatically` are set **before** `loadPersistentStores` for lightweight migrations
- `CoreDataManager` handles fetches/predicates — new filter features (category, difficulty, word type, Georgian origin, family mode, abstract round) build on `NSPredicate` logic here plus `GameStory` filter state

## Known gotchas
- Replacing a form with `LoadingView` inside a `UIHostingController` can silently break touch handling — verify view hierarchy swaps carefully
- Navigation pops inside `UIAlertController` action handlers can corrupt `UINavigationController` state — always wrap in `DispatchQueue.main.async` and guard against in-flight transitions
- Storage checks: use `volumeAvailableCapacityForImportantUsage`, not `systemFreeSize` ratio-based checks (unreliable on simulator, not production-safe)
- `ChallengesManager.swift` — guard against empty data before JSON decoding to avoid `dataCorrupted` errors

## Build & verify
- Build: standard `xcodebuild` against `Gamoitsani.xcworkspace` (fill in scheme name)
- Run unit tests: `GamoitsaniTests` target
- Run UI tests: `GamoitsaniUITests` target
- After any edit, prefer building the relevant target before declaring a task done

## Skills
Skills are discovered automatically from their descriptions — they do not need listing
here. This section exists only where a general-purpose skill would otherwise contradict a
decision this repo has already made.

- **`run-on-device`** (in `.claude/skills/`) — use it before any commit that changes
  something visible. The owner reviews UI on their paired iPhone, not in the simulator.
- **The SwiftData skills do not apply.** `swiftdata-pro`, `swiftdata-expert-skill` and
  `swiftdata-testing` are all live on this machine, and 2.0 contains no SwiftData at all —
  `WordSync`/`CachedWord`/`WordStore` were deleted once words moved to a bundled read-only
  SQLite file. Do not reintroduce it.
- **`core-data-expert` applies to v1 only**, which is deleted at cutover. 2.0 has no Core
  Data. See `docs/2.0/HANDOFF.md`.
- **`swift-architecture-skill` offers MVVM, TCA, VIPER and Clean.** 2.0's architecture is
  settled: pure value types over a reducer (`GameReducer`), with an `@Observable`
  `GameEngine` on top. Do not propose restructuring it.
- **SwiftUI skills should defer to the design system.** `GamoitsaniDesign` owns `Tokens`,
  `Typography`, `Spacing`, `Radius` and `Motion`; every `sensoryFeedback` goes through the
  `haptics` modifier so the setting can silence all of it. Prefer those over raw colours,
  fonts and animations.
- Skill installers sometimes drop copies into the repo root (`.agents/`,
  `skills-lock.json`, a cloned skill repo). These are duplicates of what is already in
  `~/.claude/skills` and are gitignored — do not commit them. The repo is public.

## Working conventions
- Keep changes scoped and reviewable — this is a shipped, live production app
- Don't touch `Pods/` directly; change the `Podfile` and re-run `pod install`
- Match existing code style (SwiftUI where the screen is SwiftUI-native, UIKit coordinator pattern where existing screens use it — don't silently convert one to the other without asking)
