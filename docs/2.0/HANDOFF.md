# Gamoitsani 2.0 — where things stand

Written 10 September 2026, at the end of the session that connected the word database,
brought the other ten languages over from Firestore, and ran architecture, formatting and
accessibility passes over the whole target.
Read this with `docs/2.0/PLAN.md` (the architecture, still accurate),
`docs/2.0/WORD-DB.md` (the word database, now built) and
`docs/2.0/ACCESSIBILITY.md`.

---

## The one-paragraph version

`Gamoitsani` is a complete, playable rewrite, and as of cutover Phase A it is the **only**
thing in this repo — v1's target and sources are deleted. It still ships under a separate
bundle id (`davitikhvedelidze.Gamoitsani`) until Phase B flips it. Eight local SPM
packages, Swift 6 strict concurrency, iOS 18. Setup, both game modes, scoreboard, sharing,
settings, sound, launch animation, the full ad stack and the remove-ads purchase all work.
**It plays on a real word database** — 6,374 curated Georgian words plus ten more languages
exported from v1's Firestore, bundled as read-only SQLite, no network and no SDK.

The shipping 1.7 on the App Store is still v1 and still reads from Firestore. That backend
keeps running until 2.0 replaces it.

---

## Immediate state

`main` carries everything through PR #31. Nothing is open.

**The one thing outstanding is that nobody has played a game.** Four PRs landed in a day —
the word database, the dead-cache removal, the effect-lifecycle fixes and the formatting
pass — every one of them verified by tests, builds and a device install, and not one of
them by playing. What that leaves unproven: real words on screen, seen-word exclusion
across two games, the mid-game deck top-up, the double-tap guard on Play, and the rematch
placement.

**`feature/reel-and-profiles` is drifting.** One commit, never pushed, and now seventeen
behind `main`. The highlight reel and player records are built and unit-tested but have
never been exercised in a real game. Every merge makes that rebase worse.

Never push to `main` directly; work reaches it through a PR the owner merges. And never
put a `claude.ai/code/session_...` link in a commit trailer or PR body — the repo is
public. Keep `Co-Authored-By`; drop `Claude-Session`.

---

## Package graph

```
Gamoitsani (app)           composition root, navigation, screens, AdMob adapter
   ├── GamoitsaniEngine    @Observable GameEngine over a pure reducer
   │      └── GamoitsaniCore
   ├── GamoitsaniData      bundled read-only SQLite, one file per language
   │      └── GamoitsaniCore
   ├── GamoitsaniCapture   what a recording contains
   ├── GamoitsaniDesign    tokens, type, motion, sound, haptics
   ├── GamoitsaniL10n      catalogue + per-language bundle lookup
   ├── GamoitsaniAds       ad policy only — no SDK dependency
   └── GamoitsaniMacros    the UserDefault macro
```

A strict DAG — `Core` is a leaf, nothing imports upward, no cycles.

Tests: Core 116, Data 24, Design 23, Capture 21, Ads 20, Engine 11, L10n 6 — 221. Plus
GamoitsaniMacros 2, which needs `swift test`: it is a compiler plugin with no simulator
destination.

---

## Done

- **Domain and engine** — pure value types over a reducer, deadline-based timing, one
  scoring authority. Fixes v1's tie crash, deck exhaustion scoring, arcade toggle-off
  double-count.
- **Screens** — setup (with player draw), turn info, challenge, countdown, both play modes,
  podium, leaderboard, stats sheet, settings.
- **Launch** — static launch screen handing off to a card-deal splash, cold start only.
- **Sound** — seven synthesised sounds, `.ambient` session, Settings toggle.
- **Haptics** — every `sensoryFeedback` goes through a `haptics` modifier so the setting
  silences all of it.
- **Share card** — podium rendered to a PNG with earned titles, `ShareLink`.
- **Team draw** — type in the room, shuffle into balanced teams, edit the line-up after.
- **Accessibility** — VoiceOver pass over the game flow.
- **Ads** — consent (UMP + ATT), banner, interstitial, app-open. Policy is a tested package.
- **CI** — builds both targets, runs all package tests, two guard scripts, weekly sanitizers.

## Not done

| | |
|---|---|
| ~~**The word database**~~ | **Done.** 6,374 curated Georgian words plus ten languages exported once from v1's Firestore, all bundled as read-only SQLite in `GamoitsaniData/WordFiles`. Four difficulty tiers, shown only where a file's difficulty column can support them — which today means Georgian alone. Seen words are remembered and the deck tops up mid-game. See `WORD-DB.md`. |
| ~~**Crashlytics**~~ | **Dropped.** Crashes come from Xcode Organizer / App Store Connect instead — free, no SDK, and 2.0 currently has no Firebase at all. Adding Crashlytics would mean pulling Firebase back into a clean build. Revisit only for a bug that needs non-fatal logging or breadcrumbs. |
| ~~**Analytics**~~ | **Dropped** for the same reason. App Store Connect covers downloads and retention. Add only when there is a specific question worth an SDK. |
| **Challenge content** | **Exported, not wired.** 17 challenges, complete in all eleven languages, pulled out of v1's Firestore and saved to `~/Desktop/gamoitsani-words/export/challenges.json`. The app still shows one hardcoded `game.challenge.placeholder` to every team. Needs a home and a selection rule — see below. |
| ~~**Highlight reel**~~ | **Built, untested in a real game.** One video per game instead of six clips. `HighlightPolicy` in `GamoitsaniCapture`. |
| ~~**Player records**~~ | **Built, untested in a real game.** Describer rotation on turn info, records in the roster. `Describer` and `PlayerLedger` in `GamoitsaniCore`. |
| ~~**Automatic review prompt**~~ | **Done.** `ReviewPromptPolicy` in `GamoitsaniCore`, asked on the podium a second after it settles. v1's never fired once: it was gated on a counter that was read but never written. |
| ~~**Game recording**~~ | **Done, on a different premise.** Front camera at 1080p for the play phase only, word overlaid at export from the engine's timeline, saved to Photos. The screen is never captured, so no ad can appear in a clip. `GamoitsaniCapture` + `Gamoitsani/Recording/`. |
| ~~**Notifications**~~ | **Done.** Weekly reminder, Saturday evening, rotating copy, English only. No in-app toggle — iOS Settings owns the permission. Asked once on the podium after a first game. |
| ~~**Word review**~~ | **Dropped.** v1's hidden five-taps-on-title screen let any client delete words from the production database after three downvotes, unauthenticated, with a client-controlled reviewer id. `firestore.rules` already disabled it. 2.0 ships a curated SQLite file the owner builds, so there is nothing to crowd-moderate — quality control belongs in the tooling that produces the DB, not in the shipped app. |
| **Rewarded ads** | Implemented and tested, deliberately no trigger. See below. |
| **Translations** | 118 keys. `en` complete, `ka` 110/118 — the eight gaps are the weekly-reminder copy, left in English on purpose. The other nine sit at 26/118 and fall back to English. `docs/2.0/LOCALIZATION.md` is stale: it still says 58 keys. |
| **iPad** | First render happened this session and it works, including dark mode. The setup form stretches the full width and reads sparse, so it wants a max-width pass before App Store review. |
| **Cutover (Phase 9)** | See the checklist below. |

---

## Decisions that are settled — do not relitigate

- **No Home screen.** The app opens on setup.
- **Only game mechanics carry over from v1.** Navigation, screens and IA are all open.
- **Code quality over v1 compatibility.** No compromises to accommodate the old codebase.
- **No banner on the play screen.** Five arcade rows and two classic buttons get tapped
  fast under a running clock; a banner there means accidental clicks, which is invalid
  traffic and gets AdMob accounts flagged. Banners are on setup, turn info and the podium.
- **The interstitial fires on leaving a finished game**, never over the podium.
- **App-open fires on resume only**, never on cold launch, never mid-game.
- **Location targeting is dropped.** v1 asked for it with no `NSLocation*` usage
  description, so iOS never showed the prompt — it never collected anything.
- **Mediation is AdMob + Vungle + Meta.** InMobi, Chartboost, ironSource, Mintegral and
  Unity each earned ~$0 and cost 78 MB. Release build went 53 MB → 16 MB.
- **There is no 1.8, and no further v1 release.** The next thing on the App Store is 2.0.
  Phase 2's hotfixes stay committed and unreleased, which means the shipping 1.7 keeps
  its StoreKit 1 observer bug and its hardcoded IAB TCF consent string until 2.0 replaces
  it. That is an accepted cost — do not propose shipping v1 again to fix them.
- **The remove-ads offer lives in the setup form and in Settings.** Four other placements
  were built and looked at on a device first — a chip above the banner, two toolbar
  variants, a row on the podium, and a toast after the interstitial — and all were
  rejected. Do not re-propose them.
- **The IAP product identifier is v1's**, `davitikhvedelidze.Gamoitsani.removeAds`.
  Identifiers belong to the App Store Connect app record, not to a bundle id, so reusing
  it is what lets existing customers keep the upgrade at cutover.
- **Words ship as a read-only SQLite database in the bundle.** Not Firestore. The owner is
  building it. Challenges go in the same file. **Add word is dropped entirely** — the route
  and the last `PlaceholderScreen` are deleted, and every route in 2.0 is a real screen.
- **No Firebase, and no Crashlytics.** The six files that imported it were v1's and went
  with v1 in Phase A, so there is no Firebase SDK in this repo at all. The Firestore
  *backend* still serves the shipping 1.7 — see Phase C. Crash reports come from Xcode
  Organizer, which costs nothing and needs no SDK.
- **All four v1 features are settled.** Recording, the review prompt and notifications are
  done. **Word review is dropped** — it existed to crowd-moderate a database anyone could
  write to, and 2.0 ships a curated file instead. Do not rebuild it.

---

## Cutover checklist (Phase 9)

**Phase A is done.** v1's three targets, its 164 sources, its storyboards, its scheme and
its five extra pods are deleted; `Pods/` went 389 MB → 116 MB. All eight package suites
pass without it. v1 is recoverable from git history if a question about old behaviour
comes up.

**`APP_LANGUAGE` → `app.language` is done** and must ship in the same build that flips the
bundle id. `Localization.migrateLegacyLanguage` copies the key across once and deletes the
old one.

### Phase B — done

The target, scheme, directory and `.storekit` file are all called `Gamoitsani`, and
`PRODUCT_BUNDLE_IDENTIFIER` is `davitikhvedelidze.Gamoitsani`. **The app now inherits v1's
`UserDefaults` container on upgrade**, which is what makes the language migration load-
bearing rather than theoretical.

`LegacyStoreCleanup` deletes the orphaned v1 Core Data store — `Gamoitsani.sqlite` plus
its `-wal` and `-shm` sidecars, in Application Support — on launch. It is self-terminating
rather than flag-guarded: once the files are gone the existence checks find nothing. Both
it and the language migration were verified by planting state in a real simulator
container and reading it back after launch, because neither can fail visibly.

**`HAS_REMOVED_ADS` stays ignored, deliberately.** It is tempting to honour it so nobody
loses a purchase, but that device-local flag is exactly the unreliable thing 2.0 replaced,
and v1 could set it without a verified transaction. `Transaction.currentEntitlements` is
authoritative and already covers anyone who really bought it, on any device, forever. Do
not add a fallback.

A target rename leaves bookkeeping the rename API does not reach: `productName`, the
product reference, the `.storekit` file reference and the abandoned `Pods-Gamoitsani2`
xcconfig references all had to be fixed separately. `PRODUCT_NAME` was already
`Gamoitsani`, so the built artefact was right the whole time and none of it showed up as a
build failure — the dangling `.storekit` reference would have shown up as a purchase that
finds no product.

### Phase C — after 2.0 is actually on the App Store

**The Firestore backend config deliberately stays for now.** `firestore.rules.template`,
`firestore-tests/`, `firebase.json`, `.firebaserc` and `scripts/generate-firestore-rules.sh`
govern rules for a database **the shipping 1.7 still reads from**. Deleting them changes
nothing deployed, but it throws away the source of truth for a live service while that
service is still serving. They go once 2.0 has replaced 1.7 on the App Store — not before.

`scripts/export_firestore_words.py` stays regardless: it is the record of how the bundled
word data was produced.

**`scripts/generate-firestore-rules.sh` is broken as of Phase A** and this is deliberate
rather than overlooked. It read the Firestore collection names out of v1's
`Config.xcconfig`, which was gitignored and went with v1 — so the names exist nowhere in
this repo any more, by design, since that is why they were gitignored. If the live 1.7's
rules ever need redeploying before Phase C, the names have to come from the Firebase
console or from a copy of the old config.

---

## Traps this codebase has already hit

Each of these cost real time. They are all fixed; do not reintroduce them.

**`GameState` and `GameSettings` both have hand-written `Codable` inits, and must keep
them.** `GameState` is what reaches disk, and `GameStateStore.load` decodes it with `try?`.
A synthesised decoder throws `keyNotFound` on any game saved before a new property existed
and the `try?` swallows it, so an in-progress game vanishes silently on upgrade. Every
property in both is optional-decoded with a default. Adding a field without doing the same
is the single easiest way to lose players' games.

**`.accessibilityElement(children: .combine)` hides child buttons behind the actions
rotor.** It reads a row nicely — "Rounds, 1" — but VoiceOver's swipe up and down stop
working. A combined row that holds a value needs `accessibilityAdjustableAction`.

**Effect results must not travel through `GameEvent`.** Words arriving from a mid-game
draw go through `GameEffect` and `GameEngine.apply`, not `send`, so a view cannot inject
them. The split is what stops a screen reaching into a running game.

**Anything async that re-enters the game must be generation-stamped.** `GameSession` bumps
a counter on start, resume and leave; a draw that returns to a different game is dropped.
Without it a top-up begun in a Hard Georgian game landed in the Easy English one that
replaced it.

**Firestore's word data lives in `new_words`, not `words`.** The older collection is a flat
`word_ka`/`word_en` pair with no translations map, and documents without one are skipped
before any counter increments — so a run against it reports nothing at all, silently.

**Both targets build a product called `Gamoitsani.app` into the same directory.** Running
v1's tests overwrites 2.0's app bundle. If a `simctl install` seems to install the wrong
thing, that is why — build 2.0 with its own `-derivedDataPath`.

**A resource directory named `Resources` breaks codesigning.** `.copy("Resources")` puts a
`Resources/` folder inside the resource bundle, which collides with bundle layout and is
rejected as malformed. The word files live in `WordFiles/` for that reason.

**SwiftUI already owns the name `Layout`.** `PlayerRoster` implements that protocol, so a
design token called `Layout` makes the type ambiguous. It is `Sizing`.

**`zsh` does not word-split unquoted variables.** A loop over `$FILES` or `$BRANCHES` hands
the whole list to the command as one argument and reports a single confusing failure. Use
an array, or `while read`.

**`Team` has a hand-written `Codable` init.** The synthesised one throws `keyNotFound` on
payloads saved before `members` existed, and `GameStateStore.load` swallows that with
`try?` — an in-progress game vanishes silently on upgrade. Any new `Team` property needs
the same treatment plus a legacy-decode test.

**`L10n.string` falls back explicitly.** A `Bundle` built from one `.lproj` has no fallback
chain and returns the key. Partially translated languages render raw keys without this.

**Sheets do not inherit the environment you expect.** Presented content takes the
environment from wherever `.sheet` was attached. `DebugMenuSheet` takes `debug`, `session`
and `ads` as parameters for this reason. This bug has been introduced twice.

**Never compare `BannerView.adSize` against the requested size to decide a reload.** The SDK
rewrites its own `adSize` to the creative it received, so the comparison is always true and
the app enters an infinite ad-request loop that hangs and crashes. Key reloads on the width
you asked for.

**Google's banner test unit returns random creative sizes** — 468x60, 320x100, 728x90 for a
320x50 request. Do not infer the requested size from what appears on screen. Measure it.

**TSan calls exclusivity violations "Swift access race", not "data race".** A grep for the
latter reported zero while the run was failing.

**`INFOPLIST_KEY_UILaunchScreen_Generation` emits a `UILaunchScreen` dict nested inside
itself and drops `UIColorName`.** The launch colour comes from a partial `Info.plist`.

**`StoreKitConfigurationFileReference` is a child element, not an attribute.** Xcode
writes it as `<StoreKitConfigurationFileReference identifier = "...">` inside
`LaunchAction`, with the path relative to the `.xcodeproj` rather than to the scheme file.
Hand-written as an attribute it is silently ignored, the purchase finds no product, and
the failure looks like a broken product id.

**StoreKit test configurations only exist when Xcode launches the app.** A `devicectl`
install, or tapping the icon, has none — and 2.0's separate bundle id means the real App
Store has no products for it either. Buying only works under ⌘R until cutover.

**`CATextLayer` does not render inside `AVVideoCompositionCoreAnimationTool`.** The layer
behind it, its border and its shadow all composite correctly and the text is simply absent,
with no error. Draw text into an image with `UIGraphicsImageRenderer` and set it as
`contents`. An explicit `CTFont` does not help — that was tested.

**`fillMode = .both` makes a layer visible before its animation begins.** Fill applies the
first value to all time before `beginTime`, so per-window animations stacked in one place
render as a single element for the whole clip. Give each layer one animation spanning the
entire clip instead.

**Verify video composition by exporting a clip and looking at a frame.** Both of the above
are invisible in code and obvious in a single frame. `AVAssetImageGenerator` on the export
output, written to a PNG, finds in one run what a build-deploy-play cycle does not find in
several.

**`PHPhotoLibrary.performChanges` deadlocks if its change block is main-actor isolated.**
A `static func` on a `@MainActor` type is isolated too, and so is the block it passes.
Photos waits for the block while the main actor waits for `performChanges` — no error, no
timeout. Mark the wrapper `nonisolated`.

**`AVCaptureMovieFileOutput` does not retain its recording delegate.** An
inline-constructed one is deallocated before the file is written, `didFinishRecordingTo`
never arrives, and everything downstream silently never happens.

**A query must not delete.** `PendingClipStore.pending()` used to remove footage it could
not pair with a timeline — and a clip being recorded has no timeline yet, so any call
during a turn destroyed the file being written, including the one behind a debug panel.

**Package resources do not always rebuild incrementally.** Added sound files were missing
from the `.app` while the build succeeded and the app ran silently. Check the bundle, not
the exit code.

---

## Rewarded ads — deferred on purpose

Built, tested, no trigger. `AdMobAds.showRewarded()` works; `AdPolicy.allowsRewarded`
offers it even inside an ad-free window but never to someone who bought ads away; the
reward extends `adFreeUntil` rather than replacing it.

The owner's position: wire it when the game has something worth trading for. Candidates
once the word DB exists — unlock a pack for a session, extra words when a deck runs out.
The ad-free hour is the shape already implemented.

**Before it can ship:** AdMob has no rewarded ad unit and no rewarded mediation group.

---

## How to work here

- **Build:** `xcodebuild -workspace Gamoitsani.xcworkspace -scheme Gamoitsani`. Never the
  `.xcodeproj`. `pod install` is required — 2.0 uses CocoaPods for the ad SDKs only.
- **Config:** `Gamoitsani/Config.xcconfig` is gitignored. Copy the template. It carries
  Google's test ad units; production units are the owner's to add.
- **Run on the owner's iPhone** for anything visible — there is a `run-on-device` skill.
  The simulator is fine for screenshots and was flaky in the last session.
- **Ask before pushing. Always.** Main only via PR.
- **Ask before acting on design.** Propose options and wait; do not build on a floated idea.
- **Comments are 1–2 lines.** Rationale that runs long belongs in the commit message.
- **Debug menu:** shake, or two-finger double tap. Ads panel shows consent, SDK state,
  which formats are loaded, and has direct triggers plus a cadence reset.

## Suggested next steps

1. **Play a game.** Everything below is guesswork until someone does. Four PRs of word-
   database work landed without a single game being played, and the reel and player
   records have never run in one either.
2. **Rebase `feature/reel-and-profiles`** before it drifts further. One commit, seventeen
   behind, never pushed.
3. **Wire the challenges.** The content is exported and complete in eleven languages; what
   is missing is where it lives and how one gets chosen. `setup.challenge.detail` promises
   "each team gets a silly rule", which implies one per team for the game — and that means
   the choice is persisted state, so it needs the same decoder treatment as everything else
   in `GameState`.
4. **Give the iPad a max-width pass.** It renders correctly but the form is stretched.
   App Store review tests on iPad, so this is the item that can become a rejection rather
   than a to-do.
5. **Cutover.** The checklist above. Note that removing Firebase *is* cutover — 2.0 has
   none, and v1's six imports go when v1 does.

The Firebase project is no longer needed by any 2.0 pipeline: the words and the challenges
have both been exported. The service account key used for that should be rotated.

Georgian copy written by Claude and not yet reviewed by the owner, who is the native
speaker: the `iap.*` keys, `common.ok`, `common.done`, the `players.*` keys, and the
difficulty tier names and their details (`setup.difficulty.*`, `setup.extras.none`). The
weekly reminder copy is English only by decision, so it needs nothing.
