# Gamoitsani 2.0 — where things stand

Written 3 September 2026, at the end of the session that built Phase 8's ad layer and
the remove-ads purchase.
Read this with `docs/2.0/PLAN.md`, which is the architecture and still accurate.

---

## The one-paragraph version

`Gamoitsani2` is a complete, playable rewrite living beside v1 as a separate bundle id
(`davitikhvedelidze.Gamoitsani2`). Six local SPM packages, Swift 6 strict concurrency,
iOS 18, 193 tests. Setup, both game modes, scoreboard, sharing, settings, sound, launch
animation, the full ad stack and the remove-ads purchase all work. **It plays on 60
hardcoded sample words** — the data layer is built and tested but not connected, because
the word source is still an open decision. v1 still builds and must keep building until cutover.

---

## Immediate state

Work is on branch `ads/phase-8-ad-layer`, open as **PR #24**. The CI fix is pushed and the
PR is green; three commits after it are local only.

```
892484a  spin only the row that is working          (local)
c50f1b5  say why a purchase is unavailable          (local)
7e0d0e6  StoreKit 2 + the remove-ads offer policy   (local)
b64b926  CI xcconfig fix + two skipped suites       (pushed)
```

Never push to `main` directly — the owner's rule is that work reaches main through a PR
they merge.

**Never put a `claude.ai/code/session_...` link in a commit trailer or PR body.** The repo
is public. Keep `Co-Authored-By`; drop `Claude-Session`.

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

Tests: Core 89, Data 21, Design 23, Ads 20, Capture 21, Engine 11, L10n 6. Plus
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
| **Word source** | The decision, and the only thing blocking anything else. Bundled DB vs Firestore. Owner is building a word DB in parallel and wants this decided last. |
| **`GamoitsaniData` wiring** | Zero imports in the app. `SampleWordProvider` (60 words) feeds the deck. Blocked on the word source. |
| **Add word screen** | Still `PlaceholderScreen`. Blocked on the word source. |
| **Crashlytics** | Not started, and **cutover-blocking** by the owner's decision. A ground-up rewrite meeting real devices is exactly when crash reports matter. |
| **Analytics** | Not started. v1 has an `AnalyticsManager`; 2.0 has nothing. |
| ~~**Game recording**~~ | **Done, on a different premise.** Front camera at 1080p for the play phase only, word overlaid at export from the engine's timeline, saved to Photos. The screen is never captured, so no ad can appear in a clip. `GamoitsaniCapture` + `Gamoitsani2/Recording/`. |
| **Notifications** | v1's `NotificationsManager`. **Being ported.** v1's copy is hardcoded English, so this needs new copy in 11 languages and lands inside the translation pass. |
| **Word review** | The hidden five-taps-on-title screen. **Being ported, but not as it was** — `firestore.rules` made words read-only because those unauthenticated writes were the attack path. It needs a Cloud Function or an authenticated admin claim first. Server work, not UI work. |
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
- **All four remaining v1 features are being ported** — recording, notifications, word
  review, automatic review prompt. This was an explicit call, not an omission.

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

1. **Push the three local commits** to PR #24.
2. **Crashlytics.** Cutover-blocking, self-contained, and depends on nothing.
3. **The remaining ported features** — automatic review prompt is next and the cheapest;
   word review has server work in front of it; notifications need copy in 11 languages.
4. **Analytics.**
5. **Run 2.0 on an iPad** before anyone plans a submission.
6. **Word source**, when the owner's DB is ready. Unblocks `GamoitsaniData`, Add word and
   the real deck.
7. **Translations, last.** Notification copy lands here too.

The Georgian strings added for the purchase UI (`iap.*`, `common.ok`) were written by
Claude and have not been reviewed by the owner, who is the native speaker.
