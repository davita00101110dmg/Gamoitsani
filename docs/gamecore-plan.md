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
  draws placements and challenges from an injected `RandomNumberGenerator`.
- `WordSupply` and `DeckLedger`: the deck sizing, top-up threshold and no-repeat
  accounting that now live in `GameSession` and `GameSetupView`.

Nothing in the app or the existing packages is edited. The owner switches over in Xcode
(steps at the end of this document).

**Tests**, Swift Testing (the toolchain supports it):

- The existing suites for every copied type, ported, so the copy is held to the same 140
  or so expectations as the original.
- New suites for: team rotation; a round ending when the clock runs out; scoring for
  guessed and skipped words; no repeated word within one game, including across top-ups;
  the game ending correctly, ties included; one team; the word list running out; a
  zero-length round; same seed and same clock giving the same game; and a save written
  by today's `GamoitsaniCore` decoding in `GameCore`.

Test helpers (a manual clock, a seeded generator) stay in the test target. Only what the
app needs is public.

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

## Switching the app over in Xcode

To be completed at the end of the work.
