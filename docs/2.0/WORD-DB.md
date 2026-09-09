# The word database — design, decided but not yet built

Everything settled with the owner about how 2.0 gets its words. **No code exists for
this yet.** Read `APP_SCHEMA.md` (shipped with the database) alongside this.

---

## The decision

Words ship as a **read-only SQLite file bundled with the app**. Not Firestore. The owner
builds it from a working database with a review pipeline; only `status='approved'` words
are exported.

`words_ka.db` — 2,964 words, 405 KB today, roughly 6,000 and ~1 MB when review finishes.
The schema is frozen; only the row count changes.

---

## What is actually in the file

Verified by querying the real thing, not read off the documentation:

| | |
|---|---|
| Words | 2,964, all Georgian |
| Nulls | none in `difficulty`, `concreteness`, `familiarity`, `is_actable` |
| Difficulty | 1:225 · 2:927 · 3:1374 · 4:431 · 5:7 |
| Tiers | easy `<=2` **1,152** · normal `<=3` **2,526** · hard `>=4` **438** |
| `is_actable` | 1,917 (65%) — charades is viable whenever it is wanted |
| `is_family_safe` | all 1 — the filter is a no-op today |
| `is_describable` | all 1 — likewise |
| `taboo_terms` | empty — Taboo mode cannot ship yet |
| Categories | 181 rows, 15 branches, 166 leaves |
| Orphans | none; every word has at least one category |
| Indexes | `ix_wc`, `ix_words_difficulty`, `ix_words_actable` all present |

**Category leaves are mostly too small to play.** Only **18 of 166** have 40+ words. The
15 branches are the usable unit (77–461 words each), and even the thinnest —
`აბსტრაქტული ცნებები`, 77 — is marginal for a full game.

---

## Settled with the owner

- **Difficulty is the only filter in 2.0.** Three tiers — easy / normal / hard — on the
  setup screen. No category picker: one control, and it maps to a column populated for
  every word.
- **Seen words are remembered.** Ids already played are excluded, so a group works
  through the database instead of meeting the same cards every few evenings. The list
  clears when the remaining pool drops below a game's worth.
- **Georgian is the only language with words today**, and the picker offers only languages
  that have a word file. Adding `words_en.db` brings English back with **no code change**.
- **The other ten languages come from a one-time export, not from Firebase.** v1's
  Firestore holds `translations: [String: TranslationData]` per word, and that data is
  exported into bundled files rather than fetched at runtime. See below.
- **The owner's position on quality:** Georgian must be well reviewed; the other languages
  may be imperfect. Having them imperfect beats not having them.

---

## Why not keep Firebase for the other languages

This was asked directly and argued through. Exporting wins because:

- **It would be two-tier permanently.** Georgian gets a reviewed database with difficulty,
  concreteness, familiarity and `is_actable`. Firestore holds the old unreviewed data with
  none of that, and no path to improving it without rebuilding review for it.
- **The audit's sync failures would return** — a failed sync stamping itself successful and
  blocking retries for seven days, an unbounded first download with no checkpoint, and
  `fetchLimit = 1500` sorted by date making older words permanently unreachable. Bundling
  makes all three impossible.
- **The cost already paid would return** — the SDK, launch-time init, a privacy manifest,
  App Store data disclosure, and keeping `WordSync`/`CachedWord` alive. 2.0 is currently
  Firebase-free and the release build went 53 MB → 16 MB partly by shedding SDKs.
- **The features would not match.** Difficulty tiers come from the new schema; words from
  Firestore have a different shape, so the selector would either lie or vanish for some
  languages.

---

## The exporter

`scripts/export_firestore_words.py` — written, tested against a fixture, **never run
against the real Firestore** because it needs the owner's credentials.

```sh
pip install firebase-admin
./scripts/export_firestore_words.py --key serviceAccount.json --out build/words
# or, without handing a script credentials:
./scripts/export_firestore_words.py --from-json words.json --out build/words
```

It emits one `words_XX.db` per language in a schema verified byte-identical to
`words_ka.db`, and reports per-language coverage so it is obvious which are worth
shipping.

What survives the trip:

| Column | From | |
|---|---|---|
| `lemma` | `translations[lang].word` | clean |
| `difficulty` | `translations[lang].difficulty` | per language, already there |
| `pos` | `wordType`, mapped | `noun` when unmappable, counted in the report |
| `is_family_safe` | `ageAppropriateness` | adult markers → 0 |
| `concreteness` | `isAbstract` | a boolean flattened onto 1–5, crude |
| `familiarity` | — | absent from Firestore, left NULL |
| `is_actable` | — | absent, left NULL, so **charades stays off** for these languages |
| categories | — | deliberately not exported |

v1 stores categories as free text on the word; the curated database has a 181-row tree
with slugs. They do not line up, and inventing a second vocabulary only these files use
would be worse than having none. 2.0 ships a difficulty selector, not a category picker,
so nothing is lost today.

**Ids are hashed from the Firestore document id**, not counted. `words.id` is promised
stable forever, and a sequential number would shift every time an earlier document was
deleted — silently invalidating every "already seen" record on every device.

**Two things worth checking before shipping an exported file:** whether the translations
are good enough to ship at all, and whether all eleven languages actually have entries —
`translations` is a map and may well be sparse.

---

## The implementation, as designed

```
GamoitsaniData
  WordDatabase        actor · opens the bundled file read-only · SQLite3 C API, no dependency
  WordQuery           difficulty range · exclusions · limit
  BundledWordProvider conforms to the existing WordProvider seam
  SeenWords           played ids, persisted, cleared when the pool runs low
```

The database ships as a resource inside `GamoitsaniData`, so the package owns its data and
`Bundle.module` finds it. Raw SQLite3 rather than GRDB: it is a read-only file with four
queries, and this project has spent real effort shedding dependencies.

`WordSync` and `CachedWord` — the Firestore-era cache — get deleted. Nothing above
`WordProvider.deck(language:count:)` changes, which is why that seam was worth keeping.

### Two traps waiting in this work

**`GameSettings` is persisted with synthesised `Codable`.** Adding a `difficulty` field
throws `keyNotFound` on games saved before it, and `GameStateStore.load` swallows that
with `try?` — an in-progress game vanishing silently on upgrade. It needs a hand-written
decode with a default and a legacy-decode test, exactly like `Team.members`.

**The deck request is far too greedy.** `GameSetupView.startGame` asks for
`max(60, teams × rounds × 40)` — 1,000 words at maximum settings, more than the easy tier
holds and more than twice the hard tier. It was written against 60 sample words. Make it
roughly 15 per team-round and clamp to what the query can return, or a Hard game exhausts
the deck mid-play.

### Suggested order

1. `WordDatabase` + `BundledWordProvider`, real file bundled — replaces `SampleWordProvider`
2. Difficulty in `GameSettings`, with the legacy-decode guard
3. Seen-word exclusion
4. Gate the language picker on available word files
5. Delete `WordSync` and `CachedWord`

---

## Still open

- **Is the current file final enough to bundle?** The schema is frozen and only rows
  change, so bundling this copy and treating a newer one as a drop-in is the plan unless
  the owner says otherwise.
- **Charades.** `is_actable` covers 1,917 words. A real new game mode, not scoped.
- **Taboo.** `taboo_terms` exists and is empty. Blocked on content, not code.
- **`CFBundleLocalizations`** should become `ka` for 2.0 while Georgian is the only word
  file, and the App Store listing drops to one language at cutover.
