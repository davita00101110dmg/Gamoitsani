#!/usr/bin/env python3
"""Export v1's Firestore words into one bundled database per language.

Georgian is produced by the word project's own pipeline and is not touched here.
This exists for the other ten languages, whose only copy is the `translations` map
on each Firestore document. Running it once turns that into `words_en.db`,
`words_ru.db` and so on, in the same schema — after which the app needs no
network, no SDK and no Firebase project to offer those languages.

    # straight from Firestore
    pip install firebase-admin
    ./scripts/export_firestore_words.py --key serviceAccount.json --out build/words

    # or from a JSON dump, if you would rather not hand a script credentials
    ./scripts/export_firestore_words.py --from-json words.json --out build/words

What survives the trip, and what does not:

    lemma          <- translations[lang].word
    difficulty     <- translations[lang].difficulty        (per language)
    pos            <- wordType, mapped; 'noun' when unmappable
    is_family_safe <- ageAppropriateness, adult markers -> 0
    concreteness   <- isAbstract, flattened onto the 1..5 scale
    familiarity    -- absent from Firestore, left NULL
    is_actable     -- absent from Firestore, left NULL, so charades stays off
    categories     -- deliberately not exported, see below

v1 stores categories as free text on the word; the curated Georgian database has a
181-row tree with slugs. They do not line up, and inventing a second vocabulary
that only these files use would be worse than having none. The app ships a
difficulty selector, not a category picker, so nothing is lost today.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import re
import sqlite3
import sys
from collections import Counter
from pathlib import Path

SCHEMA_VERSION = 1

# The app's eleven. Anything else found in the data is reported and skipped, so a
# stray key cannot quietly produce a database nobody asked for.
KNOWN_LANGUAGES = {"ka", "en", "uk", "tr", "hy", "az", "de", "es", "fr", "ja", "ru"}

POS_MAP = {
    "noun": "noun", "nouns": "noun", "substantive": "noun",
    "verb": "verb", "verbs": "verb",
    "adj": "adj", "adjective": "adj", "adjectives": "adj",
    "propn": "propn", "proper": "propn", "proper_noun": "propn", "name": "propn",
}

ADULT_MARKERS = {"adult", "18+", "mature", "nsfw"}

DDL = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE categories (
  id         INTEGER PRIMARY KEY,
  parent_id  INTEGER REFERENCES categories(id),
  slug       TEXT NOT NULL UNIQUE,
  name_ka    TEXT NOT NULL,
  name_en    TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE words (
  id             INTEGER PRIMARY KEY,
  lemma          TEXT NOT NULL,
  pos            TEXT NOT NULL,
  difficulty     INTEGER,
  concreteness   INTEGER,
  familiarity    INTEGER,
  is_describable INTEGER NOT NULL DEFAULT 1,
  is_actable     INTEGER,
  is_family_safe INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE word_categories (
  word_id     INTEGER NOT NULL REFERENCES words(id),
  category_id INTEGER NOT NULL REFERENCES categories(id),
  PRIMARY KEY (word_id, category_id)
);
CREATE TABLE taboo_terms (
  word_id  INTEGER NOT NULL REFERENCES words(id),
  position INTEGER NOT NULL,
  term     TEXT NOT NULL,
  PRIMARY KEY (word_id, position)
);
CREATE INDEX ix_wc ON word_categories(category_id, word_id);
CREATE INDEX ix_words_difficulty ON words(difficulty);
CREATE INDEX ix_words_actable ON words(is_actable) WHERE is_actable = 1;
"""


def stable_id(document_id: str) -> int:
    """A word's id, derived from its Firestore document id.

    Hashed rather than counted, so ids survive words being added or deleted between
    runs. `words.id` is promised stable forever — a sequential number would shift
    every time an earlier document disappeared, silently invalidating every "already
    seen" record on every device.
    """
    digest = hashlib.sha1(document_id.encode("utf-8")).digest()
    return int.from_bytes(digest[:7], "big")  # 56 bits, comfortably positive


def read_from_firestore(key_path: str, collection: str) -> list[dict]:
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        sys.exit("firebase-admin is not installed. `pip install firebase-admin`")

    firebase_admin.initialize_app(credentials.Certificate(key_path))
    client = firestore.client()
    documents = []
    for snapshot in client.collection(collection).stream():
        data = snapshot.to_dict() or {}
        data["__id"] = snapshot.id
        documents.append(data)
    return documents


def read_from_json(path: str) -> list[dict]:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    if isinstance(raw, dict):
        # {"docId": {...}} as well as a bare list.
        return [dict(value, __id=key) for key, value in raw.items()]
    return [dict(item, __id=item.get("__id") or item.get("id") or str(index))
            for index, item in enumerate(raw)]


def field(document: dict, *names):
    """v1 writes snake_case to Firestore and camelCase in Swift. Accept both."""
    for name in names:
        if name in document and document[name] is not None:
            return document[name]
    return None


def pos_for(document: dict, counters: Counter) -> str:
    raw = field(document, "word_type", "wordType")
    if isinstance(raw, str):
        mapped = POS_MAP.get(raw.strip().lower())
        if mapped:
            return mapped
    if field(document, "is_proper_noun", "isProperNoun") is True:
        return "propn"
    counters["pos_defaulted"] += 1
    return "noun"


def family_safe_for(document: dict) -> int:
    raw = field(document, "age_appropriateness", "ageAppropriateness")
    if isinstance(raw, str) and raw.strip().lower() in ADULT_MARKERS:
        return 0
    return 1


def concreteness_for(document: dict):
    raw = field(document, "is_abstract", "isAbstract")
    if raw is True:
        return 2
    if raw is False:
        return 4
    return None


def clamp_difficulty(value) -> int | None:
    try:
        number = int(value)
    except (TypeError, ValueError):
        return None
    return max(1, min(5, number))


def build(language: str, rows: list[tuple], out_dir: Path, content_version: str) -> Path:
    path = out_dir / f"words_{language}.db"
    path.unlink(missing_ok=True)

    connection = sqlite3.connect(path)
    connection.executescript(DDL)
    connection.executemany(
        "INSERT OR IGNORE INTO words "
        "(id, lemma, pos, difficulty, concreteness, familiarity, "
        " is_describable, is_actable, is_family_safe) "
        "VALUES (?, ?, ?, ?, ?, NULL, 1, NULL, ?)",
        rows,
    )
    written = connection.execute("SELECT COUNT(*) FROM words").fetchone()[0]
    connection.executemany(
        "INSERT INTO meta (key, value) VALUES (?, ?)",
        [
            ("schema_version", str(SCHEMA_VERSION)),
            ("content_version", content_version),
            ("language", language),
            ("word_count", str(written)),
        ],
    )
    connection.commit()
    connection.execute("VACUUM")
    connection.close()
    return path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--key", help="service account JSON for Firestore")
    source.add_argument("--from-json", help="a dump of the words collection")
    parser.add_argument("--collection", default="words")
    parser.add_argument("--out", default="build/words", help="where the .db files go")
    parser.add_argument("--languages", help="comma separated; default is everything found")
    parser.add_argument("--minimum", type=int, default=200,
                        help="skip a language with fewer words than this")
    arguments = parser.parse_args()

    documents = (read_from_json(arguments.from_json) if arguments.from_json
                 else read_from_firestore(arguments.key, arguments.collection))
    print(f"read {len(documents)} documents")

    wanted = (set(arguments.languages.split(",")) if arguments.languages
              else set(KNOWN_LANGUAGES))

    by_language: dict[str, list[tuple]] = {}
    seen_ids: dict[str, set[int]] = {}
    counters: Counter = Counter()

    for document in documents:
        translations = field(document, "translations") or {}
        if not isinstance(translations, dict):
            continue

        identifier = stable_id(str(document.get("__id")))
        pos = pos_for(document, counters)
        safe = family_safe_for(document)
        concreteness = concreteness_for(document)

        for language, payload in translations.items():
            language = str(language).strip().lower()
            if language not in wanted:
                if language not in KNOWN_LANGUAGES:
                    counters[f"unknown_language:{language}"] += 1
                continue

            if isinstance(payload, dict):
                word = payload.get("word")
                difficulty = clamp_difficulty(payload.get("difficulty"))
            else:
                word, difficulty = payload, None

            if not isinstance(word, str) or not word.strip():
                counters[f"blank:{language}"] += 1
                continue

            # A hash collision would silently drop a word. Loud is better.
            bucket = seen_ids.setdefault(language, set())
            if identifier in bucket:
                counters[f"collision:{language}"] += 1
                continue
            bucket.add(identifier)

            by_language.setdefault(language, []).append(
                (identifier, word.strip(), pos, difficulty, concreteness, safe)
            )

    out_dir = Path(arguments.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    content_version = datetime.date.today().strftime("%Y%m%d")

    print(f"\n{'language':<10}{'words':>8}   result")
    for language in sorted(by_language, key=lambda code: -len(by_language[code])):
        rows = by_language[language]
        if len(rows) < arguments.minimum:
            print(f"{language:<10}{len(rows):>8}   skipped, under --minimum")
            continue
        path = build(language, rows, out_dir, content_version)
        size = path.stat().st_size / 1024
        with_difficulty = sum(1 for row in rows if row[3] is not None)
        print(f"{language:<10}{len(rows):>8}   {path} · {size:.0f} KB · "
              f"{with_difficulty * 100 // max(1, len(rows))}% have difficulty")

    if counters:
        print("\nnotes")
        for name, count in sorted(counters.items()):
            print(f"  {name}: {count}")
    print("\nCategories and is_actable are deliberately absent — see the module docstring.")


if __name__ == "__main__":
    main()
