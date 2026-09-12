# Gamoitsani — CLAUDE.md

> **Working on 2.0? Read `docs/2.0/HANDOFF.md` first.** It has current state, settled
> decisions, and the traps this codebase has already hit. `docs/2.0/PLAN.md` is the
> architecture behind it.

Georgian party word-guessing game (Taboo/Alias-style). iOS app in production on the App Store; Android port in progress (separate repo/target).

**v1 is deleted.** Its target, its 164 sources, its storyboards and its two test targets
were removed at cutover; the shipping 1.7 stays on the App Store until 2.0 replaces it,
but nothing in this repo builds it any more. Anything below describes 2.0. v1 is
recoverable from git history if a question about old behaviour comes up.

## Tech stack
- Swift 6, strict concurrency, iOS 18. SwiftUI only — no UIKit, no coordinators, no storyboards
- Eight local SPM packages under `Libraries/Packages/`
- Words ship as a bundled read-only SQLite file. **No Firestore, no Firebase, no Core Data**
- CocoaPods for the ad SDKs only — **always open `Gamoitsani.xcworkspace`, never the `.xcodeproj`**
- Custom font: Mersad (variable typeface), shipped inside `GamoitsaniDesign`
- Ad mediation: AdMob + Vungle + Meta. The other five networks left with v1

## Project structure
- `Gamoitsani.xcworkspace` — open this in Xcode, not the `.xcodeproj`
- `Gamoitsani2/` — the app: composition root, navigation, screens, AdMob adapter
- `Libraries/Packages/` — the eight SPM packages, where nearly all tests live
- `Pods/` — CocoaPods dependencies (do not hand-edit)
- `Podfile` / `Podfile.lock` — dependency manifest

## Architecture & conventions
- Pure value types over a reducer (`GameReducer`), with an `@Observable` `GameEngine` on top
- Phases: `INFO → CHALLENGE → COUNTDOWN → PLAY → GAME_OVER`
- Two game modes: **Classic** (one word at a time) and **Arcade** (five simultaneous words, swipe mechanics, skip penalty)
- Localization: String Catalogs (`.xcstrings`). `Localization` + the `l10n(_:)` environment
  callable — **do not use `String(localized:)`**, it reads the system locale rather than the
  app's own picker
- Supported languages: Georgian, English, Ukrainian, Turkish, Armenian, Azerbaijani, German, Spanish, French, Japanese, Russian
- Flat string keys, e.g. `setup.play`. `scripts/verify-localization-keys.py` fails CI on a key the catalogue lacks

## Build & verify
- Build: `xcodebuild build -workspace Gamoitsani.xcworkspace -scheme Gamoitsani2`
- Tests live in the packages, one scheme each: `cd Libraries/Packages/<name> && xcodebuild
  test -scheme <name> -destination "id=<sim udid>"`. `GamoitsaniMacros` needs `swift test`
  instead — it is a compiler plugin with no simulator destination
- There is no app-level test target, and the `Gamoitsani2` scheme has no test action
- After any edit, prefer building before declaring a task done

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
- **`core-data-expert` does not apply.** It was v1's, and v1 is gone. There is no Core Data
  in this repo.
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
