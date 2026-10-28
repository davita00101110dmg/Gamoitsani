# GameCore — moving the game rules into a Linux-testable package

Goal: the game rules live in a pure-Swift, Foundation-only package that builds and tests on
Linux, with time and randomness injected, and the game behaves exactly as it does today.

## What reading the code turned up

**The rules are already in a pure package.** The 2.0 rewrite put them in
`Libraries/Packages/GamoitsaniCore` (Foundation only, no UIKit or SwiftUI), and on this
Linux toolchain (Swift 6.4.1) it already passes: `swiftd test` there runs 143 tests in
20 suites. `GamoitsaniEngine` (the `@Observable GameEngine` and `RoundTimer`) passes its 11
on Linux too, but only when the whole repo is mounted
(`swiftd test --package-path Libraries/Packages/GamoitsaniEngine` from the repo root).
From its own folder it fails, because `swiftd` mounts only the current directory and the
engine reaches `../GamoitsaniCore`.

So this is less a move out of the app than a consolidation. What is still missing:

1. **No single Foundation-only home for the rules plus the clock.** `RoundTimer` and the
   expiry check sit in the engine package, next to `Observation` and `@MainActor`.
2. **Time and randomness are only half injected.** The reducer takes `now` and the
   super-word placement as values, which is good. But `GameState.init` defaults to
   `SuperWordPlacement.random()`, the reducer's `nextPlacement` parameter does the same,
   and the app's `GameSession` calls `Date()` and `Challenge.draw(for:)` (system RNG)
   directly.
3. **A few rules live in the app target, where nothing tests them.** Deck sizing and the
   top-up threshold, and the word accounting that stops a top-up from repeating a card,
   sit in `GameSession` and `GameSetupView`.

## Inventory of rule types

Paths are relative to `Libraries/Packages/` unless they start with `Gamoitsani/`.

### Teams and turn order

| Type | File | Holds |
|---|---|---|
| `Team` | `GamoitsaniCore/.../Team.swift` | Score, counters, streaks, guess timing; `record`, `undo`, `skipSet`, `resetForNewGame`. Hand-written `Codable` (legacy saves lack `members`). |
| `GameState.advanceTurn` | `GamoitsaniCore/.../GameState.swift` | Rotates `currentTeamIndex`; wrapping to 0 starts the next round and clears the super-word ledger. |
| `Describer` | `GamoitsaniCore/.../Describer.swift` | Which member describes this turn; rotation derived from round and extra round, never stored. |
| `TeamValidator`, `TeamValidationError` | `GamoitsaniCore/.../GameSettings.swift` | 2–5 teams, non-empty, unique (case-insensitive) names, at most 30 characters. |

### Rounds and the timer

| Type | File | Holds |
|---|---|---|
| `GameSettings` | `GamoitsaniCore/.../GameSettings.swift` | Rounds clamped to 1–5, round length to 30–90 s, mode, super words, challenges, difficulty. Hand-written `Codable`. |
| `GameState` (`round`, `roundEndsAt`, `pausedRemaining`, `pauseClock`, `resumeClock`, `extraRound`) | `GamoitsaniCore/.../GameState.swift` | Wall-clock deadline for the round; a saved game freezes its remaining time. |
| `RoundTimer` | `GamoitsaniEngine/.../RoundTimer.swift` | Remaining time, expiry, progress, the 5-second urgency window. |
| `GameEngine.checkExpiry`, `remainingTime`, `timer` | `GamoitsaniEngine/.../GameEngine.swift` | Reads the clock and ends the turn once the deadline has passed. |

### Scoring for guessed and skipped words

| Type | File | Holds |
|---|---|---|
| `Scoring` | `GamoitsaniCore/.../Scoring.swift` | +1 / −1 for a word, +3 / −3 for a super word, −2 to skip an arcade set (0 in classic). |
| `PlayOutcome`, `GameMode` | `GamoitsaniCore/.../Scoring.swift` | `correct` / `skipped`; classic deals 1 word per set, arcade 5. |
| `SuperWordPlacement` | `GamoitsaniCore/.../Deck.swift` | Which slot holds the super word; moved every turn, one per team per round. |
| `GameRules.canReceiveSuperWord` | `GamoitsaniCore/.../GameRules.swift` | Once per team per round, only when enabled. |

### Drawing words without repeats

| Type | File | Holds |
|---|---|---|
| `Deck`, `DeckWord` | `GamoitsaniCore/.../Deck.swift` | `deal` removes what it hands out, so a deck never deals a word twice; `add` tops it up. |
| `GameState.dealSet`, `refillDeck` | `GamoitsaniCore/.../GameState.swift` | Deals 1 or 5 words and marks the super word. |
| `GameRules.canStartTurn` | `GamoitsaniCore/.../GameRules.swift` | A turn cannot begin on an empty deck. |
| `GameSession.wordsPerTurn` | `Gamoitsani/Game/GameSession.swift` | `max(20, ⌈roundLength / 2⌉)`: the deck size per turn and the top-up threshold. |
| `GameSession.topUpDeckIfNeeded` (threshold, size, exclusion), `deckIDs`, `recordSeenWords` | `Gamoitsani/Game/GameSession.swift` | Top up below one turn's worth, draw two turns' worth, exclude every id already in this game's deck; played = starting ids − remaining. |
| Opening deck size | `Gamoitsani/Screens/Setup/GameSetupView.swift` (`startGame`) | `max(80, teams × rounds × wordsPerTurn)`. |

### Game-over conditions

| Type | File | Holds |
|---|---|---|
| `GameRules` (`hasPlayedAllRounds`, `isTie`, `isGameOver`, `needsExtraRound`, `winner`) | `GamoitsaniCore/.../GameRules.swift` | Over once every team has played every round and the top two are not level; a tie adds rounds until it breaks. |

### The state and reducer that tie them together

| Type | File | Holds |
|---|---|---|
| `GameState`, `GamePhase` | `GamoitsaniCore/.../GameState.swift` | The whole game as one `Codable` value (this is what goes to disk). |
| `GameEvent`, `GameEffect`, `GameEventRejection` | `GamoitsaniCore/.../GameEvent.swift` | User intents, outside results (deck refills), and why an event was refused. |
| `GameReducer` | `GamoitsaniCore/.../GameReducer.swift` | Pure `reduce` and `apply`; time and placement passed in. |
| `Challenge` | `GamoitsaniCore/.../Challenge.swift` | Per-team rule, persisted in `GameState`, drawn with an injectable RNG. |
| `WordDifficulty` | `GamoitsaniCore/.../WordDifficulty.swift` | Part of `GameSettings`, so it travels with it. |
| `GameEngine` | `GamoitsaniEngine/.../GameEngine.swift` | `@Observable` driver: reads the clock, draws placements and rematch challenges, keeps `lastRejection`. |
| `GameSession` (start, resume, persist) | `Gamoitsani/Game/GameSession.swift` | Deals challenges at start, resumes a frozen clock, pauses the clock on save; calls `Date()` and the system RNG directly. |

### Next to the rules, deliberately not moved

`Awards`, `PlayerLedger`/`PlayerRecord`, `ReviewPromptPolicy`, `TeamDraw`, `TeamNaming`,
`WeeklyNudge` and `WordProvider` stay in `GamoitsaniCore`. They are scoring presentation,
setup helpers, app policy or the data-layer seam, not rules of play. `BundledWordProvider`
and `SeenWords` (`GamoitsaniData`) import SQLite and stay put. Screen timing in the app (the
650 ms 3-2-1 beats, the 0.25 s display tick) is presentation, not rules.

## Plan

**Package.** `Packages/GameCore` at the repo root, as asked. That is a sibling of
`Libraries/Packages/` rather than inside it; see decisions. Swift tools 6.0, Swift 6
language mode, `.iOS(.v18)`, the app's own settings (`SWIFT_VERSION = 6.0`,
`IPHONEOS_DEPLOYMENT_TARGET = 18.0`). Foundation only, no dependencies.

**Copied as-is**, with only the file header changed, so the switch is a drop-in and
`diff` against the originals shows nothing else: `GameState`, `GameReducer`, `GameEvent`,
`GameRules`, `Scoring`, `Team`, `Deck`, `GameSettings`, `Challenge`, `WordDifficulty`,
`Describer` from `GamoitsaniCore`; `RoundTimer` from `GamoitsaniEngine`. Same names, same
public API, same hand-written `Codable`, so a game saved by today's build decodes after
the switch.

**New, Foundation-only, copied out of the engine and the app:**

- `GameClock` protocol with `SystemClock`: the one place time is read.
- `GameRunner`: `GameEngine`'s logic without `Observation` or `@MainActor`, plus the rule
  parts of `GameSession` (start, resume, save). It reads time from a `GameClock` and
  draws placements and challenges from an injected `RandomNumberGenerator`. Its
  `isOutOfTime` answers "is the round over?" without mutating, for the reason under
  Findings.
- `WordSupply` and `DeckLedger`: the deck sizing, top-up threshold and no-repeat
  accounting that now live in `GameSession` and `GameSetupView`.

No app source and no existing package is edited. The owner switches over in Xcode, with
the steps and a ready, verified patch at the end of this document.

**Tests**, Swift Testing (the toolchain supports it). `swiftd test` in `Packages/GameCore`:
**151 tests in 28 suites pass, with 1 known issue recorded on purpose** (see Findings).

- 95 tests in 15 suites are the existing suites for every copied type, unchanged apart
  from the import, so the copy is held to the same expectations as the original.
- `GameEngine`'s own suite, ported to `GameRunner`.
- New suites that drive whole games through `GameRunner` with a manual clock and a seeded
  generator: team rotation; a round ending when the clock runs out; saving and resuming
  with time left; scoring for guessed, skipped and super words and arcade set skips; no
  word shown twice in a game, across rematches and top-ups too; the game ending, ties
  included; one team; the deck running dry; a zero-length round; same seed and same
  clock giving the same game, and a different seed a different one.
- A save written by today's `GamoitsaniCore` encoder, checked in as a fixture. `GameCore`
  decodes it field for field and resumes it mid-turn, so the switch cannot lose a game.

Test helpers (a manual clock; the seeded generator the ported `DeckTests` already had) stay
in the test target. Only what the app needs is public.

## Decisions

- **Copy, not reference.** `GameCore` cannot depend on `GamoitsaniCore`: `swiftd` would
  not resolve the path, and the end state wants one home for the rules, not two. Until the
  switch there are two copies; the switch deletes one.
- **Package path as asked**, `Packages/GameCore`. The repo's other packages are in
  `Libraries/Packages/`. Moving it there later is a folder move plus one path in each
  manifest that points at it.
- **API kept source-compatible.** The defaulted `.random()` parameters stay, because the
  app relies on them today. The deterministic route is `GameRunner`, which never uses them.
- **A zero-length round cannot be configured**: `GameSettings` clamps 0 s to 30 s, as
  today. A state that has one anyway (only a hand-edited save could) ends on the first
  expiry check in `GameRunner`. `GameEngine` would hit `RoundTimer`'s precondition there
  instead. That is the one behaviour difference, and nothing in the app can reach it.
- **Copies stay byte-identical** apart from the file header, including a handful of doc
  comments in the originals that stop mid-sentence (`GameReducer`, `GameRules`, `Deck`,
  `Team.record`, `RoundTimer.isUrgent`). Fix them in whichever copy survives.
- **Behaviour bugs found on the way are pinned, not fixed** (see Findings), so the switch
  itself changes nothing a player can see. Fixing them is a separate, reviewable change.
- **`.gitignore` narrowed.** `/Packages/` was ignored wholesale as SwiftPM's old
  edit-checkout folder. It is now `/Packages/*` with `!/Packages/GameCore/`, so anything
  else SwiftPM drops there is still ignored. Otherwise every new file in the package would
  need `git add -f`.
- **CI runs `GameCore` now**, as its own step: the package loop only walks
  `Libraries/Packages/`. This is also the first run of these tests on Apple's Foundation.
- **The switch re-exports instead of re-importing.** `GamoitsaniCore` gets one
  `@_exported import GameCore`, so the 13 app files and the data package that
  `import GamoitsaniCore` compile unchanged. The alternative is an `import GameCore` line
  in each of them.

## Findings — noticed, not changed

1. **A tie-break can give the same player two describing turns running.** In a live game
   `GameState.round` already includes tie-break rounds, and `Describer.index` adds
   `extraRound` on top. With two members and the default three rounds, the member who
   described round 3 describes the first tie-break too: exactly what its comment says it
   prevents. The original test passes only because it calls `round: 3, extraRound: 1`, a
   pair real state never produces. Likely fix: `turnsTaken = max(0, round - 1)`. Recorded
   in `TeamRotationTests` with `withKnownIssue`, which fails once the bug is fixed, as a
   reminder to unwrap it.
2. **Arcade "New words −2" on an empty table costs two points and deals nothing.** The
   button is always enabled, and the reducer accepts `.skipSet` with an empty deck. This
   is reachable only if a top-up fails mid-turn. Pinned in `EdgeCaseTests`. Fix by
   rejecting `.skipSet` with `.deckExhausted`, or disabling the button.
3. **After a resume, a word from earlier in the same game can come back**, narrowly. The
   top-up exclusion restarts from what is left in the deck. Once a language's unseen pool
   is exhausted, `BundledWordProvider.more` stops excluding seen words, so a word played
   before the save can be drawn again. This is in `GamoitsaniData`, outside this package.
4. **Wrapping `GameRunner` in the `@Observable` engine would re-render the play screen
   four times a second.** `RoundClock` calls `engine.checkExpiry()` on every 0.25 s tick,
   and a mutating call on a stored property of an `@Observable` class notifies every
   reader of it, even when nothing changes. This came out of rehearsing the switch with
   `withObservationTracking`. The fix is in this branch (`isOutOfTime`, read first), and
   the patch adds an engine test that fails without it.

## Switching the app over in Xcode

Everything here was rehearsed on Linux before being written down.
`docs/gamecore-switchover.patch` was applied to a clean checkout of this branch.
`GameCore` (151), `GamoitsaniCore` (52) and `GamoitsaniEngine` (8) passed there, and the
patched `GameSession.swift` compiled against them with `GamoitsaniData` stubbed (SQLite3
is not on Linux). The app target, `GameSetupView.swift` and actually playing a game could
not be checked here; steps 4 and 5 cover them.

### 1. Add GameCore to the project (the app is unchanged after this step)

1. Open `Gamoitsani.xcworkspace`, not the `.xcodeproj`.
2. **File ▸ Add Package Dependencies… ▸ Add Local…**, choose the `Packages/GameCore`
   folder, then **Add Package**.
3. In **Choose Package Products**, set the `GameCore` row's target to **None** and confirm.
   The app reaches it through `GamoitsaniCore` after step 2, so nothing links it directly.
4. Pick the **GameCore** scheme and an iOS 18 simulator, then **⌘U**. Expect 151 tests
   passing, one of them with a known issue (Finding 1).

### 2. Move the rules out of the old packages

From the repo root, on a new branch:

```bash
git rm \
  Libraries/Packages/GamoitsaniCore/Sources/GamoitsaniCore/{Challenge,Deck,Describer,GameEvent,GameReducer,GameRules,GameSettings,GameState,Scoring,Team,WordDifficulty}.swift \
  Libraries/Packages/GamoitsaniCore/Tests/GamoitsaniCoreTests/{Challenge,Deck,GameReducer,GameRules,GameSettings,MovingSuperWord,Scoring}Tests.swift \
  Libraries/Packages/GamoitsaniEngine/Sources/GamoitsaniEngine/RoundTimer.swift \
  Libraries/Packages/GamoitsaniEngine/Tests/GamoitsaniEngineTests/RoundTimerTests.swift
```

```bash
git apply docs/gamecore-switchover.patch
```

If the patch no longer applies because `main` has moved, the edits it makes are listed
under "Files that change" below and are small enough to make by hand.

Back in Xcode, **File ▸ Packages ▸ Resolve Package Versions**, so it sees that
`GamoitsaniCore` now depends on `GameCore`.

### 3. Test the packages

| Scheme | Expect |
|---|---|
| GameCore | 151 tests, 1 known issue |
| GamoitsaniCore | 52 tests in 6 suites (was 143; the other 91 now run in GameCore) |
| GamoitsaniEngine | 8 tests (was 11: 4 timer tests moved, 1 observation test added) |
| GamoitsaniData | unchanged |

### 4. Build the app

**Gamoitsani** scheme, **⌘B**. Only `GameSession.swift` and `GameSetupView.swift` change in
the app. Every other `import GamoitsaniCore` keeps compiling through the re-export.

### 5. Play it on the phone (the `run-on-device` skill)

1. **Saves survive the switch.** Install a build of the current `main`, start a game, and
   leave it mid-turn with time on the clock. Then install the switched build over it. The
   resume card should appear and resume with the same time left.
2. **Classic to the end**: guess and skip words, let the clock run out, and get a
   tie-break if you can.
3. **Arcade** with super words on: a set skip costs 2, and a super word ±3.
4. **Challenges on**: each team keeps its rule; a rematch deals new ones.
5. **Background mid-turn** past the deadline and come back: the turn has ended.

### 6. CI

Nothing more to do. This branch already adds the **Test GameCore** step, and the existing
loop keeps testing `GamoitsaniCore` and `GamoitsaniEngine`.

### Files that change

| File | Change |
|---|---|
| `Libraries/Packages/GamoitsaniCore/Package.swift` | Depends on `../../../Packages/GameCore`. |
| `Libraries/Packages/GamoitsaniCore/Sources/GamoitsaniCore/GameCoreExport.swift` | **New.** `@_exported import GameCore`. |
| `.../GamoitsaniCore/{Awards,PlayerRecord,TeamDraw,WordProvider}.swift` | `import GameCore`, so they don't rely on another file's import. |
| `.../GamoitsaniCoreTests/PlayerRecordTests.swift` | The `Describer` suite removed (it is in GameCore). |
| `.../GamoitsaniCoreTests/TeamDrawTests.swift` | The `Team persistence` suite removed (it is in GameCore). |
| `Libraries/Packages/GamoitsaniEngine/Sources/GamoitsaniEngine/GameEngine.swift` | A thin `@Observable` wrapper over `GameRunner`. `init(state:now:nextPlacement:drawChallenges:)` becomes `init(state:clock:random:)` and `init(runner:)`. Adds `stateForSaving()`. Same public surface otherwise. |
| `.../GamoitsaniEngineTests/GameEngineTests.swift` | The test clock conforms to `GameClock`; adds "checkExpiry does not notify observers while time remains". |
| `Gamoitsani/Game/GameSession.swift` | Builds engines from `GameRunner`, so no `Date()` or system RNG of its own. `deckIDs` becomes `DeckLedger`, and `wordsPerTurn` moves to `WordSupply`. |
| `Gamoitsani/Screens/Setup/GameSetupView.swift` | The opening deck size comes from `WordSupply.openingDeckSize`. |

### Files deleted

- `Libraries/Packages/GamoitsaniCore/Sources/GamoitsaniCore/`: `Challenge`, `Deck`,
  `Describer`, `GameEvent`, `GameReducer`, `GameRules`, `GameSettings`, `GameState`,
  `Scoring`, `Team`, `WordDifficulty` (`.swift`).
- `Libraries/Packages/GamoitsaniCore/Tests/GamoitsaniCoreTests/`: `ChallengeTests`,
  `DeckTests`, `GameReducerTests`, `GameRulesTests`, `GameSettingsTests`,
  `MovingSuperWordTests`, `ScoringTests` (`.swift`).
- `Libraries/Packages/GamoitsaniEngine/Sources/GamoitsaniEngine/RoundTimer.swift` and
  `Tests/GamoitsaniEngineTests/RoundTimerTests.swift`.
- After the switch has shipped: `docs/gamecore-switchover.patch`.

### Until you switch: check the copies have not drifted

A fix made to the rules in `GamoitsaniCore` before the switch has to be made in `GameCore`
too. This prints nothing while they match:

```bash
for f in Challenge Deck Describer GameEvent GameReducer GameRules GameSettings GameState Scoring Team WordDifficulty; do diff -I '^//  ' Libraries/Packages/GamoitsaniCore/Sources/GamoitsaniCore/$f.swift Packages/GameCore/Sources/GameCore/$f.swift; done; diff -I '^//  ' Libraries/Packages/GamoitsaniEngine/Sources/GamoitsaniEngine/RoundTimer.swift Packages/GameCore/Sources/GameCore/RoundTimer.swift
```

### If you would rather keep it in `Libraries/Packages/`

1. Move the folder to `Libraries/Packages/GameCore`.
2. Change the dependency path in `GamoitsaniCore`'s manifest to `../GameCore`.
3. Remove and re-add the local package in Xcode.
4. Point the CI step at the new path.
5. Drop the two `.gitignore` lines for `/Packages/`.
