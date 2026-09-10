# The word database — design, decided but not yet built

Everything settled with the owner about how 2.0 gets its words. **No code exists for
this yet.** Read `APP_SCHEMA.md` (shipped with the database) alongside this.

---

## The decision

Words ship as a **read-only SQLite file bundled with the app**. Not Firestore. The owner
builds it from a working database with a review pipeline; only `status='approved'` words
are exported.

`words_ka.db` — 6,374 words, 790 KB. This is the reviewed file: the earlier 2,964-word
copy has been replaced. The schema is frozen; only the row count changes.

---

## What is actually in the file

Verified by querying the real thing, not read off the documentation:

| | |
|---|---|
| Words | 6,374, all Georgian |
| Nulls | none in `difficulty`, `concreteness`, `familiarity`, `is_actable` |
| Difficulty | 1:662 · 2:2108 · 3:2771 · 4:818 · 5:15 |
| Tiers | easy `<=2` **2,770** · normal `<=3` **5,541** · hard `>=4` **833** |
| `is_actable` | 3,869 (61%) — charades is viable whenever it is wanted |
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

- **Difficulty is the only filter in 2.0.** Four tiers — easy `<=2` / medium `<=3` /
  hard `>=4` / mixed — as chips on the setup screen, defaulting to mixed. No category
  picker. The control is shown only for files whose difficulty column has a real spread,
  which today means Georgian alone.
- **Seen words are remembered.** Ids already played are excluded, so a group works
  through the database instead of meeting the same cards every few evenings. The list
  clears when the remaining pool drops below a game's worth.
- **All eleven languages ship a word file.** Georgian is curated (6,374 words); the other
  ten were exported from v1's Firestore on 9 September 2026. The picker is built from the
  files actually present, so removing one removes the language rather than leaving an option
  that silently deals Georgian cards.
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

`scripts/export_firestore_words.py` — **run against the real Firestore on 9 September 2026.**
All ten non-Georgian languages are exported and bundled.

```sh
pip install firebase-admin
./scripts/export_firestore_words.py --key serviceAccount.json --out build/words
```

### What the run actually found

**The data is in `new_words`, not `words`.** The `words` collection is the old flat
`word_ka` / `word_en` pair — no `translations` map, no difficulty, no word type. Running
against it yields nothing at all, silently, because a document with no `translations` is
skipped before any counter is incremented. `--collection` now defaults to `new_words`.

3,470 documents, and every one carries all eleven translations — so before de-duplication
each language came out at exactly 3,470 words.

**Firestore's per-language difficulty is unusable.** This is the finding that mattered:

| | d1 | d2 | d3 | d4 | d5 | hard tier |
|---|---|---|---|---|---|---|
| en | 1794 | 1476 | 192 | 8 | 0 | **8 words** |
| ru | 1742 | 1528 | 198 | 2 | 0 | **2 words** |
| ja | 825 | 2336 | 295 | 12 | 2 | **14 words** |
| ka *(curated)* | 662 | 2108 | 2771 | 818 | 15 | *833 words* |

`<= 3` covers 99.9% of every exported file, so Easy, Normal and Mixed would all deal the
same deck and Hard would deal two cards. **The app therefore asks each file whether its
difficulty is worth a selector** — `WordDatabase.hasUsableDifficulty()`, which wants at
least 200 words in both the easy and hard tiers — and the setup screen simply omits the
control where it is not. Georgian keeps all four tiers; the other ten play the whole file.

That check reads the data rather than a `meta` flag on purpose: the curated Georgian file
comes from the word project's own pipeline, not from this script, so a flag written here
would only ever exist in ten of the eleven files.

**Duplicates had to be removed.** Distinct Georgian words often share one translation —
Japanese lost 402 of 3,470, Turkish 348, Azerbaijani 347, English only 4. The engine tells
cards apart by id, not by text, so without the de-duplication pass the same word could be
dealt twice in one game. Final counts run 3,068 (ja) to 3,466 (en).

**Casing is deliberately left alone.** Every exported lemma is capitalised — `Slippers`,
`Статуя`. Lowercasing was considered and rejected: it would break German nouns, which must
be capitalised, and proper nouns like `Google` and `Alps`. Capitalised words read fine on a
card.

**Georgian is not exported by default.** The curated file has 6,374 words, a real spread,
`is_actable` and the category tree; the export would have been 3,470 flat words with none
of that. `--languages ka` still forces it if ever needed.

What survives the trip:

| Column | From | |
|---|---|---|
| `lemma` | `translations[lang].word` | clean, de-duplicated |
| `difficulty` | `translations[lang].difficulty` | present but flat — see above |
| `pos` | `word_type`, mapped | only 8 of 3,470 needed the `noun` default |
| `is_family_safe` | `age_appropriateness` | adult markers → 0 |
| `concreteness` | `is_abstract` | a boolean flattened onto 1–5, crude |
| `familiarity` | — | absent from Firestore, left NULL |
| `is_actable` | — | absent, left NULL, so **charades stays Georgian-only** |
| categories | — | deliberately not exported |

v1 stores categories as free text on the word; the curated database has a 181-row tree with
slugs. They do not line up, and inventing a second vocabulary only these files use would be
worse than having none.

**Ids are hashed from the Firestore document id**, not counted. `words.id` is promised
stable forever, and a sequential number would shift every time an earlier document was
deleted — silently invalidating every "already seen" record on every device. Zero
collisions across all ten languages.

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

- **The exported languages have never been read by a native speaker.** The words sample
  well, but nobody has checked 3,000 of them. Some are weak party words — `Will`, `Free`,
  `Born`, `Outlined` — and 105 English entries are multi-word.
- **Charades.** `is_actable` covers 1,917 words. A real new game mode, not scoped.
- **Taboo.** `taboo_terms` exists and is empty. Blocked on content, not code.
- **`CFBundleLocalizations`** — no longer forced to `ka`, since every language now has
  words. Still needs setting to the eleven the app actually ships.
