# Gamoitsani 2.0 — where things stand

Written 3 September 2026, at the end of the session that built Phase 8's ad layer.
Read this with `docs/2.0/PLAN.md`, which is the architecture and still accurate.

---

## The one-paragraph version

`Gamoitsani2` is a complete, playable rewrite living beside v1 as a separate bundle id
(`davitikhvedelidze.Gamoitsani2`). Six local SPM packages, Swift 6 strict concurrency,
iOS 18, 162 tests. Setup, both game modes, scoreboard, sharing, settings, sound, launch
animation and the full ad stack all work. **It plays on 60 hardcoded sample words** — the
data layer is built and tested but not connected, because the word source is still an open
decision. v1 still builds and must keep building until cutover.

---

## Immediate state

**5 commits sit unpushed on local `main`.** They must not be pushed to `main` directly —
the owner's rule is that work reaches main through a PR they merge. Branch, push the
branch, open the PR.

```
7bfa991  app-open ad + banner placements + debug tooling
a89a157  banner infinite-request loop fix + anchored adaptive sizing
f1e348e  drop Unity from mediation
f2330a9  trim mediation to four networks
f6ff226  ads: consent, banner, interstitial, policy
```

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

Tests: Core 89, Data 21, Design 23, Ads 12, Engine 11, L10n 6.

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
| **Word source** | The decision. Bundled DB vs Firestore. Owner is building a word DB in parallel and wants this decided last. |
| **`GamoitsaniData` wiring** | Zero imports in the app. `SampleWordProvider` (60 words) feeds the deck. |
| **Add word screen** | Still `PlaceholderScreen`. Depends on the word source. |
| **Rewarded ads** | Implemented and tested, deliberately no trigger. See below. |
| **Translations** | 89 keys. Only `en` and `ka` are complete; the other nine have 26 each. `docs/2.0/LOCALIZATION.md` lists what is missing. |
| **StoreKit 2** | Remove-ads IAP. `AdState.adsRemoved` exists and is honoured by the policy; nothing sets it. |
| **Analytics, Crashlytics** | Not started. |
| **Cutover (Phase 9)** | Flip bundle id, delete v1 and its six extra pods. |

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

1. **Push the 5 commits** via a PR.
2. **Translations** — 63 keys × 9 languages. `docs/2.0/LOCALIZATION.md` has the table. The
   owner wants to review the English and Georgian copy before translating.
3. **StoreKit 2 remove-ads.** Self-contained, the policy already honours `adsRemoved`, and
   it monetises the people most annoyed by ads.
4. **Word source**, when the owner's DB is ready. This unblocks Add word and the real deck.
