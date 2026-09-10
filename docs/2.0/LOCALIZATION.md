# Localization — 2.0

129 keys in eleven languages, in
`Libraries/Packages/GamoitsaniL10n/Sources/GamoitsaniL10n/Resources/Localizable.xcstrings`.
English is the source and the fallback: `L10n.string` falls back explicitly, so a missing
key renders in English rather than as a raw key.

v1's catalogue is separate and stays untouched — the two key schemes differ.

## Where each language stands

| Language | Keys | State |
|---|---|---|
| English | 129 / 129 | The source. Everything missing elsewhere falls back here. |
| Georgian | 121 / 129 | Complete. The eight gaps are the weekly reminder, English by decision. |
| Azerbaijani, German, Spanish, French, Armenian, Japanese, Russian, Turkish, Ukrainian | 31 / 129 | Carried over from v1. The other 98 fall back to English. |

The nine are missing exactly the same 98 keys — they came over in one export from v1's
Firestore, so they cover v1's vocabulary and nothing 2.0 added.

## What the nine already have

31 keys, where v1's English and 2.0's are close enough that v1's translations apply:

`challenge.handOnHead` · `challenge.questionForm` · `challenge.robotVoice` ·
`challenge.royalTitles` · `challenge.whisper` · `common.cancel` · `game.leaderboard` ·
`game.noWords` · `game.start` · `home.title` · `mode.arcade` · `mode.arcade.detail` ·
`mode.classic` · `mode.classic.detail` · `settings.feedback` · `settings.language` ·
`settings.rate` · `settings.share` · `settings.title` · `setup.addTeam` ·
`setup.error.duplicate` · `setup.error.empty` · `setup.mode` · `setup.play` ·
`setup.superWord.detail` · `setup.teamName` · `setup.teams` · `stats.guessed` ·
`stats.sets` · `stats.skipped` · `stats.streak`

Ten of these say it differently in v1 than in 2.0 — the translations follow v1's wording,
not 2.0's English. Worth a skim before shipping, not a blocker:

| 2.0 key | 2.0 English | What the translations actually say |
|---|---|---|
| `game.leaderboard` | Leaderboard | Scoreboard |
| `game.noWords` | No words left | No more words |
| `mode.arcade.detail` | Five words at once | Play with 5 words at once |
| `mode.classic.detail` | One word at a time | Play one word at a time |
| `setup.error.duplicate` | Two teams share this name | Team with this name already exists |
| `setup.error.empty` | Give this team a name | Name cannot be empty |
| `setup.mode` | Mode | Game mode |
| `setup.play` | Play | Start |
| `stats.guessed` | guessed | Words Guessed |
| `stats.skipped` | skipped | Words Skipped |

## What the nine are missing

98 keys. Eight of them are deliberate, so the real gap is **90**.

| Area | Keys | What a player in those languages sees today |
|---|---|---|
| `setup.*` | 26 | Most of the setup screen is English |
| `game.*` | 14 | Round labels, the challenge card, end-of-turn |
| `iap.*` | 8 | The remove-ads offer and its errors |
| `reminder.*` | 8 | **Deliberate.** The weekly reminder is English by decision. |
| `a11y.*` | 7 | VoiceOver reads English on a localized screen |
| `challenge.*` | 7 | The seven rules new in 2.0 |
| `players.*` | 7 | The player draw and the roster |
| `settings.*` | 7 | Settings rows added since v1 |
| `award.*` | 5 | The titles earned on the share card |
| `rules.*` | 4 | The how-to-play sheet |
| `common.*` | 2 | `common.ok`, `common.done` |
| `teams.*` | 2 | Choosing between the draw and typing names |
| `share.*` | 1 | The share sheet's message |

`a11y.*` is the one to weigh: a VoiceOver user in German hears English labels over an
otherwise German screen.

## Georgian awaiting a native check

Written by Claude, never checked by the owner, who is the native speaker:
`setup.difficulty.*`, `setup.extras.none`, the seven `challenge.*` keys new in 2.0
(`accent`, `commentator`, `lookAway`, `onlyQuestions`, `shoutIt`, `singIt`,
`thirdPerson`), `iap.*`, `common.ok`, `common.done`, and `players.*`.

The other five `challenge.*` keys are v1's own Georgian and are already translated into
all eleven languages — changing their English or Georgian means re-translating nine.

## How to apply

Edit the catalogue directly. Adding a language to a key means adding a `localizations`
entry with a `stringUnit`; there is no need to touch Xcode's editor.

`scripts/verify-localization-keys.py` fails the build if the app asks for a key the
catalogue does not have. It runs in CI. It does not check whether a key is *translated* —
only that it exists.
