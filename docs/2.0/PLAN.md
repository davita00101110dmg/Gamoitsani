# Gamoitsani 2.0 — Assessment & Roadmap

> **Status:** planning complete, no code written yet.
> **Produced by:** a Claude Code web session on a Linux container with **no Xcode
> toolchain** — every finding below was read from source, none was compiled or run.
> **Next step:** resume on a Mac with Xcode. See "Resuming this work" at the bottom.

---


## Context

Gamoitsani is a Georgian word-guessing party game (Alias / Heads-Up style) shipping on
the App Store at v1.7. It was Daviti's first app, started ~Feb 2025 on UIKit and
partially migrated to SwiftUI. The goal is a "2.0": a full SwiftUI rewrite including
navigation, a genuinely better UI on the existing brand colors, and a modern codebase.

The load-bearing finding from this audit: **the app's real architecture is not the
coordinator layer — it is `GameStory.shared`.** Navigation carries almost no data; the
only payloads on the entire graph are one `UIImage` and one argument that is ignored.
Every screen transition is "mutate the global singleton, then push something that reads
it back." Rewriting screens in SwiftUI without replacing that just moves the problem.
So 2.0 goes **state model → navigation → screens → visuals**, not screen-by-screen.

### Decisions locked with the owner

| Decision | Choice |
|---|---|
| Minimum iOS | **18.0** (from 16.0) |
| Migration | **Fresh app target + local SPM packages, same repo** (see below) |
| Visual | **Keep the palette, all-new layout language** |
| In scope | Fix verified bugs · Unlock the 8 hidden languages · Lock down Firestore |
| Out of scope | New gameplay features, word-DB content work — **deferred to dedicated sessions** |

### Why a fresh target beats a big-bang branch

The owner asked which is better and said shipping delay is acceptable. Fresh target, for
three reasons:

1. **It always compiles.** The new target builds and runs from day one and grows screen
   by screen. A big-bang branch is broken for weeks, and breakage compounds invisibly.
2. **I cannot compile anything in this environment** (Linux, no Xcode toolchain). The
   only safety net is that *you* can build frequently. A target that always builds gives
   you that; a broken branch does not.
3. **Side-by-side comparison.** Both targets install on the same device, so you can
   diff old vs. new behaviour directly while porting game rules.

It is not "two codebases to maintain" — v1 is frozen (hotfixes only) and all new work
goes to the new target. At cutover the new target takes over the bundle ID and the old
sources are deleted. The App Store record is unaffected; a target is an implementation
detail. Work happens on a long-lived `v2` branch so `main` stays clean for v1 hotfixes.

### Environment constraint

No Swift/Xcode toolchain here — nothing can be compiled, run, or screenshotted. Every
increment must be small, self-contained, and independently buildable, and **you are the
build/verify step**. This is why the roadmap is many small phases, not four big ones.

---

## Baseline facts (verified)

| Fact | Value |
|---|---|
| Swift files / LOC | 163 / ~12,300 |
| Deployment target | iOS 16.0 · Swift language mode 5 |
| Devices | iPhone + iPad, `UIRequiresFullScreen` · iPhone portrait+landscape, iPad portrait only |
| Dependencies | **Both** CocoaPods (13 ad SDKs) *and* SPM (Firebase 10.25, swift-collections, facebook-ios-sdk) |
| Storyboards / XIBs | 2 storyboards + 5 XIBs |
| Tests | 6 files / 39 cases — but **at least 3 files do not compile** (below) |
| CI | none |
| `@MainActor` in `Source/` | **0** (vs. 30 `DispatchQueue.main` hops) |
| `@Observable` | **0** — all legacy `ObservableObject` + 37 `@Published` |
| Singletons | 15 defined, `.shared` referenced 116× (`GameStory.shared` alone 24×) |
| Accessibility calls | **1** in the entire codebase |
| Hardcoded font sizes | 37 |
| `TODO`/`FIXME` · `try!` · `print(` | 0 · 0 · 1 — line-level hygiene is genuinely good |

---

## What's actually wrong

### A. The state model (root cause of most of the rest)

`Source/Common/Models/Game/GameStory.swift` — a mutable singleton holding mode, rounds,
teams, the word queue, current indices and every feature flag.

- **Not observable.** SwiftUI views read `GameStory.shared` directly inside `body`
  (`GameScoreboardView.swift:23,41`, `PostGameScoreboardView.swift:95`,
  `TransitionViewModifier.swift:17`) with no invalidation path. Every view model
  hand-mirrors its fields into `@Published` copies to compensate.
- **A View mutates it.** `GameInfoView.swift:61` does
  `GameStory.shared.playingSessionCount += 1`, and all round/team arithmetic hangs off
  that view-incremented counter (`GameViewModel.swift:250-251`).
- **Parallel arrays keyed by index.** `teamChallenges` and `teamSuperWordEncountered`
  must be manually kept in sync with `teams`; `reset()` is asymmetric (`removeAll()`s
  one, resizes the other) and partial (leaves `teams`, `words`, `isGameInProgress`, all
  settings). `Team` already has a `UUID` — this data belongs on `Team`.
- **Destructive consumption.** `GameModeFactory` drains the shared queue via
  `words.removeFirstNItems(50)`; `resetViewModels()` never returns unused words.
- **It is why the tests are fragile** — every test file calls `GameStory.shared.reset()`
  in `setUp()`, and since `reset()` is partial, state leaks between cases.

`Team` (`Models/Team/Team.swift`) is by contrast a clean `struct` with `private(set)`
fields and `mutating` methods. It is the one model worth carrying over nearly as-is.

### B. The UIKit↔SwiftUI seam is the bug source

Commit `1f52343 "Fix freezing in game screen"` is three defensive band-aids in one
diff — `DispatchQueue.main.async` around a `pop()`, a guard against double-pushing a
coordinator, and a `hasAppeared` flag because `.onAppear` fires repeatedly inside a
`UIHostingController`. These are textbook symptoms of the seam, not of the screens.

- **The `UIHostingController` boilerplate is copy-pasted 6 times.** No helper.
- **The `Coordinator` protocol defines a guaranteed retain cycle** — `parentCoordinator`
  is a *strong* `var`, and `coordinate(to:)` sets both directions
  (`BaseCoordinator.swift:12,20-21`).
- **5 of 8 coordinators leak by construction.** The only cleanup hook is
  `BaseViewController.viewDidDisappear`, which exists only for the two UIKit screens.
  `HomeCoordinator.childCoordinators` grows unbounded for the process lifetime.
- **All three `dismiss()` methods have zero call sites** (verified).
- **Second cycle:** coordinator → `navigationController` → hostingController → rootView
  → `.environmentObject(coordinator)`. Every SwiftUI screen closes this loop.
- **Five different view-model patterns coexist** — empty placeholder classes, plain
  classes, structs-as-view-models, `ObservableObject`s, and one non-observable class —
  plus three ownership idioms (`@StateObject`, `@ObservedObject` with inline defaults,
  `@StateObject` wrapping a *singleton* at `DraggableCameraPreview.swift:14`).

### C. Data layer

- 🔴 **Background-context `NSManagedObject`s are used on the main thread.**
  `CoreDataManager.fetchWordsFromCoreData` fetches on `newBackgroundContext()`, then
  `FirebaseManager.swift:68` hands them to `MainActor`, into `GameStory.shared.words`,
  where `BaseGamePlayViewModel.getTranslation` fires the `wordTranslations` **fault on
  the main thread** during gameplay. This is a thread-confinement violation and the most
  likely true cause of the freezes.
- 🔴 **Only the newest 1500 words are ever playable.** `fetchLimit = 1500` sorted by
  `last_updated` descending, then `.shuffle()` — so it shuffles *within* a fixed window;
  older words are permanently unreachable no matter how big the DB grows.
- 🔴 **A failed sync marks itself successful.** `fetchWordsFromFirebase` returns `[]`
  after retries; `saveWordsFromFirebase([])` trivially succeeds; `lastWordSyncDate` is
  stamped anyway → **no retry for 7 days** (`FirebaseManager.swift:63-66`).
- **First sync is an unbounded full-collection download** — no `.limit()`, no
  pagination, no checkpoint. Dies at 90% → everything lost.
- **Dedupe is one fetch per incoming word against an unindexed `baseWord`**, inside a
  loop, and every sync deletes and recreates *every* translation for every touched word.
  No `NSBatchInsertRequest`, no uniqueness constraint, no indexes in either model.
- **No language/difficulty/category filter at query time.** Pick Japanese and a word
  without a `ja` translation silently shows the raw Georgian base word.
- **`fatalError` on persistent-store load failure** for a store that is a pure
  disposable cache — one non-inferrable model change bricks the installed base.
- **All 7 attributes added in the "Word 2.0" model version are written and never read**,
  as is `Translation.difficulty`. The migration bought nothing.

### D. Security — the most serious findings

- 🔴 **The client deletes documents from the shared production words collection.**
  `FirebaseManager+WordReview.swift:283` — `transaction.deleteDocument(wordRef)` after
  3 negative votes. Writes are **unauthenticated** (`FirebaseAuthHelper.ensureAnonymousAuth`
  has zero call sites), the reviewer identity is a client-controlled `UserDefaults`
  string, and **there is no `firestore.rules` in the repo**. Anyone with the app bundle
  can wipe the word database. The feature is hidden behind 5 taps on a title — obscurity,
  not security.
- 🔴 **A double-`completion` crash.** `updateWordReview` calls `completion(false)` inside
  the transaction block *and* returns `nil`, so the outer handler fires too. Its caller
  pairs that completion with `dispatchGroup.leave()` → "left more times than entered" →
  `EXC_BAD_INSTRUCTION`. Firestore also *retries* transaction blocks, multiplying it.
- 🔴 **A hardcoded IAB TCF consent string** `"BOEFEAy…"` is sent to InMobi at
  `AppConsentAdManager.swift:171,191` regardless of the user's actual UMP choice. That
  is a GDPR problem, not a code smell.
- **Location permission is requested purely for ad targeting**, from `private init()` —
  merely touching the singleton prompts the user (`:73-74`).
- **InMobi debug logging is enabled unconditionally**, including release builds (`:92-93`).
- **Unauthenticated, unvalidated, unrate-limited word-suggestion writes** with a
  client-side read-then-write dedupe (obvious TOCTOU).

### E. Monetization — a live revenue bug

`SettingsViewModel` uses **StoreKit 1** and registers itself as the `SKPaymentQueue`
observer in `init`, removing it in `deinit`. The app therefore only listens for
transactions **while the Settings screen is alive.** A purchase completing after the user
leaves Settings — deferred, Ask-to-Buy, interrupted network — is never recorded: the user
pays and keeps seeing ads.

And separately: `InterstitialAdManager.loadAd` guards with
`if isLoadingAd, !AppConstants.shouldShowAdsToUser` — a comma (AND) where the sibling
`AppOpenAdManager` correctly uses `||`. **Interstitials load for users who paid to
remove ads.**

### F. Localization — 8 languages built and hidden

- `Localizable.xcstrings` holds **11 fully-translated languages** (az, de, en, es, fr,
  hy, ja, ka, ru, tr, uk) and `LanguageManager.Language` offers all 11 — but
  `Info.plist`'s `CFBundleLocalizations` declares only **`en, ka, uk`**. The App Store
  advertises 3 languages instead of 11.
- **SwiftGen's string codegen is silently broken.** `Generated/Localizable.swift` is
  literally `// No string found` — SwiftGen's strings parser doesn't read `.xcstrings`.
  The 425-line `L10n` tree is now hand-maintained with no compile-time key validation.
- **`L10n.Tutorial` freezes the language permanently.** 16 entries use `static let`
  (lazily initialized once, cached for the process) while the other 105 correctly use
  computed `var`. Those strings never update on language change.
- **Bundle-swapping on every string lookup** — `Bundle.main.path(forResource:ofType:)`
  + `Bundle(path:)` per string, uncached, inside SwiftUI `body` re-evaluations.
- **Hardcoded English** in notification copy (`AppConstants.swift:232-244`), word-review
  strings, challenge fallbacks, and `RecordingError` descriptions.
- Junk catalog keys: `""`, `"     "`, `"%lld"`, `"Checked"`, `"Quick Game Mode (Debug)"`.

### G. Design system

The palette is **not** trash — this is the good news. The 10 "Animation Colors" are a
coherent pink→violet→blue→cyan ramp (`#F72585 #B5179E #7209B7 #560BAD #480CA8 #3A0CA3
#3F37C9 #4361EE #4895EF #4CC9F0`), and the background gradient
(`#4D2E8D → #23176C → #001242`) matches the app icon's deep-indigo identity exactly.
That's real brand equity, and the icon already ships light/dark/tinted variants.

What's broken is the *system* around it:

- **Names carry no meaning** — `Color 1`…`Color 14`, `GMSecondary`, `TintColor`. There is
  no semantic layer (surface / onSurface / success / danger / accent / cardFace).
- **No light mode, and it's never declared.** Every brand color hardcodes the same value
  for `light` and `dark`, but `UIUserInterfaceStyle` is absent and nothing calls
  `overrideUserInterfaceStyle` / `preferredColorScheme`. So on a light-mode device the
  app's own surfaces stay dark while system chrome — alerts, sheets, keyboards, context
  menus, text fields — renders light. The app is dark-only by accident, not by decision.
- **Duplicates:** `Color 2` == `Color 14` (#B5179E) · `Color 12` == `GMGreen` (#198A24) ·
  `AccentColor` == `TintColor` · `GMRed` (#DC3444) vs `Color 13` (#DC5454).
- **Low contrast:** `GMSecondary` #4756A6 — the default button fill — on the #23176C
  background is a weak pairing for text.
- **No type or spacing scale.** 37 hardcoded font sizes; sizing branches on
  `UIDevice.current.userInterfaceIdiom` inside components rather than on size classes.
- **Accessibility is absent** — 1 accessibility call total, no Dynamic Type, no VoiceOver.
- **Components are duplicated across paradigms** — parallel `GM*` families in
  `Components/SwiftUI/` and `Components/UIKit/` with different APIs.
- **The Home screen is a title and three buttons in a XIB.** It is the app's face and
  the single biggest visual opportunity in 2.0.

### H. Project hygiene

- **The repo cannot be built by anyone, including on a fresh clone of your own machine.**
  Two required inputs are missing: `Config.xcconfig` (gitignored, no committed template)
  and the local **`GamoitsaniMacros` Swift package**, which is referenced by the project
  but was never committed and isn't ignored — it simply isn't there. `AppSettings.swift`
  imports it. For a public repo whose README asks for stars, this matters.
- **`.gitignore` does not describe the repo.** It lists `Pods/`, `*.xcodeproj` and
  `*.xcworkspace`, yet 300 `Pods/` files and 6 `xcodeproj` files are tracked (they
  predate the rules). `.git` is 29 MB.
- **The test target almost certainly doesn't build**, which is why nobody noticed:
  `CoreDataManagerTests` calls a 4-argument `WordFirebase.init` on an 11-property struct
  with no defaults; `LanguageManagerTests` references `UserDefaults.Keys`, which doesn't
  exist; `FirebaseManagerTests`' mock doesn't satisfy `CoreDataManaging`'s
  `async`/`throws` signatures. `ChallengesManagerTests` compiles but injects via a
  `Mirror` cast that always fails, so it silently tests real `UserDefaults`.
- **Duplicate/stale files:** two `LaunchScreen.storyboard`s (one orphaned), a stale
  `Gamoitsani/Info.plist` that isn't the build's `INFOPLIST_FILE`, a dangling pbxproj
  reference to `../Gamoitsani/SupportingFiles/Info/Info.plist`.
- **`AppConstants` is a god-enum** — config accessors, colors, SF Symbol strings,
  notification copy, regex and a 50-item fruit list, with identical `do/catch` boilerplate
  repeated 15×. Several members (`randomWords`, `helperColors`, `maxWordsToSaveInCoreData`)
  are never referenced.
- **`NSAllowsArbitraryLoads = true`**, 334 SKAdNetwork entries, 8 mediation SDKs
  initialized synchronously on the main thread with no failure isolation.
- **No crash reporting at all** — Firebase is present but Crashlytics is not used.
- Dead code inventory: `HomeViewModel`, five empty `*Models` enums,
  `GameModeFactory.ViewModelType`, `BaseCoordinator.addChildCoordinator`,
  `BaseViewController.subscribers`/`.bannerView`, `AppDelegate.window`,
  `FirebaseManager.fetchWords`, `FirebaseAuthHelper.ensureAnonymousAuth`,
  `BundleExtensions.swift` (entire file), `GameDetailsViewModel`'s `NWPathMonitor`
  (written, never read), `GameStory.finishedGamesCountInSession` (read, never written —
  so the App Store review prompt is unreachable).

---

## Target architecture

```
Gamoitsani.xcworkspace
├── Gamoitsani            (v1 target — frozen, hotfixes only, deleted at cutover)
├── Gamoitsani2           (new app target: @main App, DI composition root, ~thin)
└── Packages/             (local SPM — real module boundaries, fast previews, testable)
    ├── GamoitsaniCore        domain: Team, GameState, GameRules, scoring. No UIKit/SwiftUI.
    ├── GamoitsaniEngine      @Observable @MainActor GameEngine + deadline-based RoundTimer
    ├── GamoitsaniDesign      tokens, type scale, spacing, components, motion
    ├── GamoitsaniData        WordStore protocol + Core Data impl + Firestore sync
    └── GamoitsaniL10n        string catalog + a type-safe accessor that actually generates
```

**State.** One `@Observable @MainActor final class GameEngine` owning a `GameState`
value type. `GameStory.shared` is deleted. Per-team data (challenge, super-word seen)
moves onto `Team`, keyed by `id` — the parallel arrays go away. Scoring rules live in
exactly one place in `GamoitsaniCore` (today they're in three: `WordItem.Constants`,
`ClassicGamePlayViewModel.wordButtonAction`, and `GameMode.skipPenalty`).

**Timing.** Store an `endDate` and derive remaining time; never decrement a tick counter.
This removes the two-unsynchronised-timers bug, the missing re-entrancy guard, and makes
backgrounding correct via `scenePhase`. All the `asyncAfter(0.2/0.3/0.5/1.5)` sequencing
becomes explicit state transitions.

**Navigation.** `NavigationStack` + a typed `Route` enum + an `@Observable Router`.
All 8 coordinators, `BaseCoordinator`, `BaseViewController` and the 6 copies of hosting
boilerplate are deleted — and with them the entire leak class, since there is no
parent/child object graph to retain.

**Concurrency.** Swift 6 language mode with strict concurrency from the first commit.
`@MainActor` on the engine and view models; `WordStore` as an `actor`; managed objects
never cross a context boundary — the data layer vends `Sendable` value types
(`WordItem`), not `NSManagedObject`s. Doing this later means doing the rewrite twice.

**Dependencies.** One composition root in the app target. Managers become injected
protocol-backed services; `.shared` survives only where a platform API forces it. Drop
CocoaPods entirely — Google Mobile Ads and every mediation adapter ship SPM now — so
there's one dependency system, and untrack `Pods/`.

---

## Design direction

Keep the palette; rebuild everything around it.

1. **A semantic token layer** in `GamoitsaniDesign`, defined once and referenced
   everywhere: `surface`, `surfaceRaised`, `onSurface`, `onSurfaceMuted`, `accent`,
   `success`, `danger`, `cardFace`, `cardEdge`. The existing hexes become the *values*
   behind the tokens; `Color 11`-style names disappear from call sites.
2. **Decide dark-only explicitly** — set `UIUserInterfaceStyle = Dark` so system chrome
   stops disagreeing with the app — or build a genuine light palette. Not the current
   accidental middle.
3. **A type scale and a spacing scale.** Size classes, not `UIDevice.userInterfaceIdiom`.
   Dynamic Type support with capped upper bounds on gameplay text.
4. **A card-first layout language.** The icon already tells the story — a fanned stack of
   word cards. That metaphor should drive gameplay, the home screen and transitions,
   instead of the current full-bleed gradient behind stacked rectangles.
5. **A motion and haptics vocabulary** — `.sensoryFeedback`, matched-geometry card
   transitions, one timing curve family. Today: confetti, rainbow borders, pulse, float
   and shake with no shared grammar.
6. **Accessibility as a build rule, not a phase** — labels on every control, VoiceOver
   for the game flow, Reduce Motion respected.

---

## Roadmap

Each phase ends with a build you run in Xcode before we move on.

**Phase 0 — Make the repo buildable and honest**
Commit `Config.xcconfig.template` + setup docs; commit or vendor `GamoitsaniMacros`;
untrack `Pods/` and the stale `Info.plist`/`LaunchScreen`; fix `.gitignore`; add a CI
workflow that builds and runs tests. *This comes first because without it no one — and
no CI — can build the project.*

**Phase 1 — Repair the test suite**
Fix the three non-compiling files so the 39 existing cases actually run and gate CI. They
are the only regression net the rewrite will have.

**Phase 2 — Ship the v1 hotfixes** *(on `main`, released as 1.8 before 2.0 work)*
The StoreKit observer bug, the interstitial `,`→`||` guard, the double-`completion`
crash, the sync-failure stamp, and `CFBundleLocalizations` → all 11 languages. These are
live-user problems; they shouldn't wait for a months-long rewrite.

**Phase 3 — Firestore lockdown**
Wire up anonymous auth, commit `firestore.rules`, remove client-side document deletion
(move it behind a Cloud Function or an admin flag), rate-limit and validate suggestions,
drop the hardcoded TCF consent string, stop requesting location for ad targeting.

**Phase 4 — Skeleton of the new target**
`Gamoitsani2` + the five local packages, SwiftUI `App`, `NavigationStack` + `Router`,
Swift 6 mode, design tokens, and a working Home screen. Nothing else. First runnable 2.0.

**Phase 5 — `GamoitsaniCore` + `GamoitsaniEngine`**
Port `Team`, build `GameState` and `GameEngine`, deadline-based `RoundTimer`, one scoring
authority. Ported unit tests, now isolated because there's no singleton to reset.

**Phase 6 — `GamoitsaniData`**
`WordStore` actor vending `Sendable` value types. Uniqueness constraint + indexes,
batch insert, language/difficulty filtering at query time, real pagination and
checkpointed sync, a store-rebuild fallback instead of `fatalError`.

**Phase 7 — Screens, in dependency order**
Home → GameDetails → Game flow (info/challenge/countdown/play/gameover) → Scoreboard →
Settings → AddWord → Rules → Share. Each on the new design system.

**Phase 8 — Peripheral services**
Ads, analytics, recording, notifications, StoreKit 2 — as injected services behind
protocols. Add Crashlytics.

**Phase 9 — Cutover**
Flip bundle ID, delete v1 sources and CocoaPods, ship 2.0.

**Deferred to separate sessions (owner's call):** the Georgian word database — content,
schema and quality — and any new gameplay features that depend on it.

---

## Docs to create

| File | Purpose |
|---|---|
| `CLAUDE.md` | Repo conventions: architecture rules, naming, Swift 6 expectations, the "I can't compile, you verify" contract, commit/branch conventions |
| `docs/2.0/ROADMAP.md` | The phase list above, with checkboxes, kept current |
| `docs/2.0/ARCHITECTURE.md` | Target module layout, state ownership, navigation, concurrency rules |
| `docs/2.0/DESIGN-SYSTEM.md` | Tokens with hex values, type/spacing scales, component inventory, motion + haptics rules |
| `docs/2.0/AUDIT.md` | This assessment, as the durable record of *why* |
| `docs/SETUP.md` | How to build from a fresh clone (xcconfig template, macros package) |

---

## Working pattern

1. One phase at a time; within a phase, one reviewable commit per coherent change.
2. I write code, you build in Xcode and report back — I can't compile here, so anything
   I claim about behaviour is reasoning, not verification, and I'll say which it is.
3. Every phase updates `ROADMAP.md` so state survives across sessions.
4. Branch `claude/test-to25li` for the immediate work; a long-lived `v2` branch once
   Phase 4 starts, leaving `main` free for v1 hotfixes.

## Verification

- **Phases 0–1:** a fresh clone builds; `xcodebuild test` runs green in CI.
- **Phase 2:** confirm on device — buy the IAP with Settings closed and check ads stop;
  confirm all 11 languages appear in App Store Connect.
- **Phase 3:** with the app's own credentials, confirm an unauthenticated client can no
  longer write or delete in the words collection.
- **Phases 4–8:** each screen runs in the simulator; unit tests for engine and data
  layer; `-com.apple.CoreData.ConcurrencyDebug 1` must stay silent during a full game.
- **Phase 9:** full playthrough in all 11 languages, iPhone + iPad, VoiceOver on.

---

## Resuming this work (on a Mac with Xcode)

This plan was produced in a sandbox with no Swift toolchain, so nothing here has been
compiled. Phases 0–1 exist precisely to restore a working build + CI before any rewrite
begins.

### Before the first session

Two files are required to build and are **not** in this repository:

1. **`Config.xcconfig`** — gitignored, no template committed. It must define at minimum:
   `WORDS_COLLECTION_NAME`, `SUGGESTED_WORDS_COLLECTION_NAME`, `BANNER_AD_ID`,
   `INTERSTITIAL_AD_ID`, `APP_OPEN_AD_ID`, `ADMOB_TEST_DEVICE_ID`, `UMP_TEST_DEVICE_ID`,
   `REMOVE_ADS_IN_APP_PURCHASE_PRODUCT_ID`, `META_APP_ID`, `META_CLIENT_TOKEN`,
   `VUNGLE_APP_ID`, `INMOBI_APP_ID`, `CHARTBOOST_APP_ID`, `CHARTBOOST_APP_SIGNATURE`.
2. **`GamoitsaniMacros/`** — a local Swift package the project references and
   `AppSettings.swift` imports. It was never committed and is not gitignored; it only
   exists on the original dev machine. Bring your local copy.

Have both in place, then confirm `Gamoitsani.xcworkspace` builds before starting.

### Starting the session

On the Mac, in a terminal:

```
git clone <this repo> && cd Gamoitsani     # or: git pull
git checkout claude/test-to25li
pod install                                # CocoaPods is still in use until Phase 9
claude
```

Then open the session with something like:

> Read `docs/2.0/PLAN.md`. It's the full audit and roadmap for Gamoitsani 2.0 from a
> previous session. Start with Phase 0. You have Xcode here, so build and run tests
> yourself before telling me anything is done.

Run Xcode alongside it — Claude Code is a terminal tool and has no Xcode extension, so
it drives `xcodebuild` and you keep Xcode open for the simulator and Previews.

### What changes once Xcode is available

- `xcodebuild` becomes the verification step for every change, instead of you being it.
- Phase 1 (repairing the three non-compiling test files) becomes checkable directly.
- The Core Data thread-confinement bug can be *proven* by running with
  `-com.apple.CoreData.ConcurrencyDebug 1` and watching it trap during a game.
- The leaked coordinators can be confirmed in Instruments rather than argued from code.

### Reading order for a fresh session

1. This file, top to bottom.
2. `Source/Common/Models/Game/GameStory.swift` — the singleton the whole rewrite is about.
3. `Source/Common/BaseCoordinator.swift` + any one `*Coordinator.swift` — the leak shape.
4. `Source/Modules/Game/Game/Views/GamePlay/BaseGamePlayViewModel.swift` — the timers.
5. `Source/Common/Utils/Managers/CoreDataManager.swift` — the data-layer problems.
