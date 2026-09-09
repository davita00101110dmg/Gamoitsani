# Gamoitsani 2.0 — where things stand

Written 3 September 2026, at the end of the session that built Phase 8's ad layer and
the remove-ads purchase.
Read this with `docs/2.0/PLAN.md` (the architecture, still accurate) and
`docs/2.0/WORD-DB.md` (the word database: decided, designed, not yet built).

---

## The one-paragraph version

`Gamoitsani2` is a complete, playable rewrite living beside v1 as a separate bundle id
(`davitikhvedelidze.Gamoitsani2`). Six local SPM packages, Swift 6 strict concurrency,
iOS 18, 235 tests. Setup, both game modes, scoreboard, sharing, settings, sound, launch
animation, the full ad stack and the remove-ads purchase all work. **It plays on 60
hardcoded sample words** — the data layer is built and tested but not connected, because
the word source is still an open decision. v1 still builds and must keep building until cutover.

---

## Immediate state

**Two things are waiting, in this order.**

**1. Test the highlight reel and player records.** Branch `feature/reel-and-profiles`,
one PR. Both are built, unit-tested and installed on the owner's phone, but **neither has
been exercised in a real game**. See "What needs testing" below. Nothing else should start
until this is either merged or fixed.

**2. Then the word database.** Design is settled and written down in `WORD-DB.md`; no code
exists. **Start it on its own branch** once the reel work is merged.

`main` carries everything through PR #27 — ads, the remove-ads purchase, recording, the
review prompt and the weekly reminder.

Never push to `main` directly; work reaches it through a PR the owner merges. And never
put a `claude.ai/code/session_...` link in a commit trailer or PR body — the repo is
public. Keep `Co-Authored-By`; drop `Claude-Session`.

---

## What needs testing

Both landed in one commit and have only ever been built, never played.

**The highlight reel.** Turn recording on in Extras, play a **full game with at least two
turns**, reach the podium. A few seconds later one video should appear in Photos: the
picked moments with the word over each, ending on the share card. Per-turn clips no longer
save — the reel replaces them.

The composition was verified locally by exporting one and looking at frames, so slices
stitch and the card renders. What has *not* been seen is the real path: whether the
moments chosen are the funny ones, whether ~25s feels right, and whether a 3s lead-in is
enough run-up.

If nothing appears, **Debug → Recording → Copy log** traces the reel
(`reel: cutting N turns`, `reel: exported …KB`, `reel: SAVED TO PHOTOS`). That names the
failing step directly — do not guess, this feature cost five rounds of guessing already.

**Player records.** The turn-info screen should name who is describing and who is next,
rotating through the team. Tapping a name in the setup roster opens their record; a
"Players" link there lists everyone. Records only accumulate for teams built with the
player draw — teams typed in by hand have no members to credit.

Two judgement calls worth a look: whether the describer line reads well on turn info, and
whether the reel's pacing is right.

---

## Package graph

```
Gamoitsani2 (app)          composition root, navigation, screens, AdMob adapter
   ├── GamoitsaniEngine    @Observable GameEngine over a pure reducer
   │      └── GamoitsaniCore
   ├── GamoitsaniData      SwiftData cache + Firestore sync   ← BUILT, NOT WIRED
   │      └── GamoitsaniCore
   ├── GamoitsaniDesign    tokens, type, motion, sound, haptics
   ├── GamoitsaniL10n      catalogue + per-language bundle lookup
   └── GamoitsaniAds       ad policy only — no SDK dependency
```

Tests: Core 119, Data 21, Design 23, Ads 20, Capture 34, Engine 11, L10n 6. Plus
GamoitsaniMacros 2, which needs `swift test` — it is a compiler plugin with no simulator
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
| **The word database** | **Decided, designed, not built. See `WORD-DB.md`.** The file exists (2,964 Georgian words). The app still plays on 60 hardcoded sample words. This is the next piece of work and the only thing standing between 2.0 and being a real game. |
| ~~**Crashlytics**~~ | **Dropped.** Crashes come from Xcode Organizer / App Store Connect instead — free, no SDK, and 2.0 currently has no Firebase at all. Adding Crashlytics would mean pulling Firebase back into a clean build. Revisit only for a bug that needs non-fatal logging or breadcrumbs. |
| ~~**Analytics**~~ | **Dropped** for the same reason. App Store Connect covers downloads and retention. Add only when there is a specific question worth an SDK. |
| **Challenge content** | 2.0 has a single `game.challenge.placeholder` string — v1 fetched challenges from Firestore, which is going. Decided: challenges ship in the same bundled SQLite DB as the words. |
| ~~**Highlight reel**~~ | **Built, untested in a real game.** One video per game instead of six clips. `HighlightPolicy` in `GamoitsaniCapture`. |
| ~~**Player records**~~ | **Built, untested in a real game.** Describer rotation on turn info, records in the roster. `Describer` and `PlayerLedger` in `GamoitsaniCore`. |
| ~~**Automatic review prompt**~~ | **Done.** `ReviewPromptPolicy` in `GamoitsaniCore`, asked on the podium a second after it settles. v1's never fired once: it was gated on a counter that was read but never written. |
| ~~**Game recording**~~ | **Done, on a different premise.** Front camera at 1080p for the play phase only, word overlaid at export from the engine's timeline, saved to Photos. The screen is never captured, so no ad can appear in a clip. `GamoitsaniCapture` + `Gamoitsani2/Recording/`. |
| ~~**Notifications**~~ | **Done.** Weekly reminder, Saturday evening, rotating copy, English only. No in-app toggle — iOS Settings owns the permission. Asked once on the podium after a first game. |
| ~~**Word review**~~ | **Dropped.** v1's hidden five-taps-on-title screen let any client delete words from the production database after three downvotes, unauthenticated, with a client-controlled reviewer id. `firestore.rules` already disabled it. 2.0 ships a curated SQLite file the owner builds, so there is nothing to crowd-moderate — quality control belongs in the tooling that produces the DB, not in the shipped app. |
| **Automatic review prompt** | **Being ported.** v1's never fired: its counter was read but never written. Cheapest of the four. |
| **Rewarded ads** | Implemented and tested, deliberately no trigger. See below. |
| **Translations** | 94 keys. Only `en` and `ka` are complete. `docs/2.0/LOCALIZATION.md` lists what is missing. Owner wants this done last, after the copy settles. |
| **iPad** | Both targets declare `TARGETED_DEVICE_FAMILY = "1,2"`, so nothing regresses — but every 2.0 screen has only ever run on the owner's iPhone. App Store review tests on iPad. Run it there before cutover. |
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
- **No Firebase in 2.0, and no Crashlytics.** 2.0 already has none; v1 still imports it in
  six files and must keep building, so "remove Firebase" *is* the cutover step. Crash
  reports come from Xcode Organizer, which costs nothing and needs no SDK.
- **All four v1 features are settled.** Recording, the review prompt and notifications are
  done. **Word review is dropped** — it existed to crowd-moderate a database anyone could
  write to, and 2.0 ships a curated file instead. Do not rebuild it.

---

## Cutover checklist (Phase 9)

Flipping the bundle id to `davitikhvedelidze.Gamoitsani` also inherits **v1's
`UserDefaults` container**, and the two key schemes do not line up.

- **`APP_LANGUAGE` → `app.language`.** v1 wrote the first, 2.0 reads the second. Without a
  one-time read of the old key at first launch, every existing user who deliberately chose
  a language gets silently reset to the system default on upgrade.
- **`HAS_REMOVED_ADS` stays ignored, deliberately.** It is tempting to honour it so nobody
  loses a purchase, but that device-local flag is exactly the unreliable thing 2.0
  replaced, and v1 could set it without a verified transaction.
  `Transaction.currentEntitlements` is authoritative and already covers anyone who really
  bought it, on any device, forever. Do not add a fallback.
- **Delete the orphaned v1 Core Data store.** It is a disposable word cache and will
  otherwise sit on disk forever.
- Delete v1 sources, its target, storyboards/XIBs, and its six extra pods. CocoaPods
  itself stays — 2.0 uses it for the ad SDKs.

---

## Traps this codebase has already hit

Each of these cost real time. They are all fixed; do not reintroduce them.

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

- **Build:** `xcodebuild -workspace Gamoitsani.xcworkspace -scheme Gamoitsani2`. Never the
  `.xcodeproj`. `pod install` is required — 2.0 uses CocoaPods for the ad SDKs only.
- **Config:** `Gamoitsani2/Config.xcconfig` is gitignored. Copy the template. It carries
  Google's test ad units; production units are the owner's to add.
- **Run on the owner's iPhone** for anything visible — there is a `run-on-device` skill.
  The simulator is fine for screenshots and was flaky in the last session.
- **Ask before pushing. Always.** Main only via PR.
- **Ask before acting on design.** Propose options and wait; do not build on a floated idea.
- **Comments are 1–2 lines.** Rationale that runs long belongs in the commit message.
- **Debug menu:** shake, or two-finger double tap. Ads panel shows consent, SDK state,
  which formats are loaded, and has direct triggers plus a cadence reset.

## Suggested next steps

1. **Test the reel and player records**, merge `feature/reel-and-profiles` or fix what it
   shows. Nothing else should start first.
2. **Build the word database layer** on its own branch. `WORD-DB.md` has the design, the
   decisions and the two traps waiting in it.
3. **Run 2.0 on an iPad.** No 2.0 screen has ever rendered on one, and both targets
   declare `TARGETED_DEVICE_FAMILY = "1,2"`. App Store review tests on iPad, so this is
   the one remaining item that can become a rejection rather than a to-do.
4. **Export the other languages** when the owner has checked whether v1's translations are
   good enough to ship. `scripts/export_firestore_words.py` is written and tested against
   a fixture; it needs their Firestore credentials to run.
5. **Cutover.** The checklist above.

Georgian copy written by Claude and not yet reviewed by the owner, who is the native
speaker: the `iap.*` keys, `common.ok`, `common.done`, and the `players.*` keys. The
weekly reminder copy is English only by decision, so it needs nothing.
