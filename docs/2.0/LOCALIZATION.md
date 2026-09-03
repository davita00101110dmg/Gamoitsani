# Localization — 2.0

v1 ships 123 keys in 11 languages. 2.0 has 58 keys, authored in English and Georgian.
This is what carried over and what still needs you.

- **23 keys** reused v1's translations automatically — nothing to do.
- **10 of those** reuse v1 copy whose wording differs from 2.0's English. Worth a skim (§2).
- **35 keys** are new. They need translating into the 9 non-Georgian languages (§3).

Georgian and English are already written for every key — only the other nine are missing.

---

## 1. Reused from v1 as-is

Identical text, so v1's translations apply directly.

| 2.0 key | Text | Taken from |
|---|---|---|
| `common.cancel` | Cancel | `cancel` |
| `game.start` | Start | `start` |
| `home.title` | GAMOITSANI | `app.title` |
| `mode.arcade` | Arcade | `screen.game_details.arcade.title` |
| `mode.classic` | Classic | `screen.game_details.classic.title` |
| `settings.language` | Language | `screen.settings.language` |
| `settings.title` | Settings | `screen.settings.title` |
| `setup.addTeam` | Add a team | `screen.game_details.teams.add` |
| `setup.superWord.detail` | One word per round is worth 3 | `screen.game_details.super_word.description` |
| `setup.teamName` | Team name | `screen.game_details.teams.name_placeholder` |
| `setup.teams` | Teams | `screen.game_details.section.teams` |
| `stats.sets` | sets skipped | `screen.game_scoreboard.performance_stat_row.sets_skipped` |
| `stats.streak` | best streak | `screen.game_scoreboard.performance_stat_row.best_streak` |

## 2. Reused, but v1 says it differently

Same meaning, different phrasing. The translations are v1's, so they follow the **v1**
column, not 2.0's English. Fine to leave — flag any you want re-translated to match.

| 2.0 key | 2.0 English | v1 English (what the translations say) |
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

## 3. New in 2.0 — needs translation

No v1 equivalent. English and Georgian below are the source; the nine columns are blank.
Review the copy first — if any wording is wrong, change it here before translating.

---

## How to apply

Fill the tables in §3, or say the word and I'll draft them for you to correct — either
way they want a native check before shipping. Georgian, English and any language you
edit go straight into
`Libraries/Packages/GamoitsaniL10n/Sources/GamoitsaniL10n/Resources/Localizable.xcstrings`.

v1's catalogue stays untouched — 2.0 has its own, and the two key schemes differ.
