"""Tests for words_report.py. Run with `python3 -m pytest tools/words`."""

from __future__ import annotations

import csv
import hashlib
import sqlite3
from pathlib import Path

import pytest

import words_report as wr
from words_report import Category, Dataset, Word

SCHEMA = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE categories (
  id INTEGER PRIMARY KEY, parent_id INTEGER, slug TEXT NOT NULL UNIQUE,
  name_ka TEXT NOT NULL, name_en TEXT, sort_order INTEGER NOT NULL DEFAULT 0);
CREATE TABLE words (
  id INTEGER PRIMARY KEY, lemma TEXT NOT NULL, pos TEXT NOT NULL,
  difficulty INTEGER, concreteness INTEGER, familiarity INTEGER,
  is_describable INTEGER NOT NULL DEFAULT 1, is_actable INTEGER,
  is_family_safe INTEGER NOT NULL DEFAULT 1);
CREATE TABLE word_categories (word_id INTEGER NOT NULL, category_id INTEGER NOT NULL,
  PRIMARY KEY (word_id, category_id));
CREATE TABLE taboo_terms (word_id INTEGER NOT NULL, position INTEGER NOT NULL,
  term TEXT NOT NULL, PRIMARY KEY (word_id, position));
"""


def checks(findings, check):
    return [f for f in findings if f.check == check]


# --------------------------------------------------------------------- normalize


@pytest.mark.parametrize("a, b", [
    ("ნიუ-იორკი", "ნიუ იორკი"),
    ("ნიუ-იორკი", "ნიუიორკი"),
    ("ხე.", "ხე"),
    (" ხე ", "ხე"),
    ("ᲮᲔ", "ხე"),               # Mtavruli folds onto Mkhedruli
    ("Coca-Cola", "coca cola"),
    ("ხ​ე", "ხე"),         # zero-width space
])
def test_normalize_collapses_case_spaces_and_punctuation(a, b):
    assert wr.normalize(a) == wr.normalize(b)


def test_normalize_keeps_distinct_words_apart():
    assert wr.normalize("ხე") != wr.normalize("ხეები")


# -------------------------------------------------------------------- duplicates


def test_exact_duplicates_keep_lowest_id():
    words = [Word(5, "ხე"), Word(2, "ხე"), Word(9, "ხე"), Word(3, "ცა")]
    found = checks(wr.find_duplicates(words), "exact_duplicate")
    assert sorted(f.word_id for f in found) == [5, 9]
    assert all("id 2" in f.reason for f in found)


def test_normalized_duplicates_are_separate_from_exact():
    words = [Word(1, "ნიუ-იორკი"), Word(2, "ნიუ იორკი"), Word(3, "ნიუ-იორკი")]
    found = wr.find_duplicates(words)
    assert [(f.check, f.word_id) for f in found] == [
        ("exact_duplicate", 3),
        ("normalized_duplicate", 2),
    ]


def test_no_duplicates_in_clean_list():
    assert wr.find_duplicates([Word(1, "ხე"), Word(2, "ცა"), Word(3, "მზე")]) == []


# -------------------------------------------------------------------- characters


@pytest.mark.parametrize("lemma", ["აბაზანა", "ნიუ-იორკი", "რიო-დე-ჟანეირო", "შავი ზღვა"])
def test_clean_georgian_has_no_character_findings(lemma):
    assert wr.character_findings(Word(1, lemma)) == []


@pytest.mark.parametrize("lemma, check, needle", [
    ("ტაქსი taxi", "latin", "'t'"),
    ("ლოს-ანჯელესი LA", "latin", "'L'"),
    ("ფეხბურთი 2", "digit", "'2'"),
    ("კოშკი ٣", "digit", "'٣'"),            # Arabic-Indic digit
    ("მოსკოვი Москва", "other_script", "Cyrillic"),
    ("ᲮᲔ", "other_script", "Mtavruli"),
    ("Ⴀბა", "other_script", "Asomtavruli"),
    ("ხე!", "stray_symbol", "'!'"),
    ("ხე ცა", "stray_symbol", "U+00A0"),  # no-break space
    ("ხე​ცა", "stray_symbol", "U+200B"),  # zero-width space
    (" ხე", "stray_symbol", "leading or trailing"),
    ("ხე-", "stray_symbol", "leading or trailing"),
    ("ხე  ცა", "stray_symbol", "doubled"),
    ("ხე--ცა", "stray_symbol", "doubled"),
    ("ხე჻ცა", "stray_symbol", "U+10FB"),  # Georgian paragraph separator
])
def test_character_findings(lemma, check, needle):
    found = wr.character_findings(Word(1, lemma))
    matching = checks(found, check)
    assert matching, found
    assert needle in matching[0].reason


def test_mixed_problems_report_each_kind_once():
    found = wr.character_findings(Word(1, "ab12 д!"))
    assert sorted(f.check for f in found) == ["digit", "latin", "other_script", "stray_symbol"]


# ------------------------------------------------------------------------ length


@pytest.mark.parametrize("lemma, expected", [
    ("ა", "too_short"),
    ("ხე", "too_short"),
    ("მზე", None),
    ("ერთი ორი სამი", None),
    ("ერთი ორი სამი ოთხი", "too_long"),
    ("რიო-დე-ჟანეირო", None),        # hyphens join, so this is one word
    ("ა ბ", "too_short"),            # two letters, however spaced
])
def test_length(lemma, expected):
    found = wr.length_findings(Word(1, lemma))
    assert [f.check for f in found] == ([expected] if expected else [])


# ------------------------------------------------------------------------ fields


def tree():
    return {
        1: Category(1, None, "food", "საკვები", "Food"),
        2: Category(2, 1, "food_fruits", "ხილი", "Fruit"),
        3: Category(3, 1, "food_empty", "ცარიელი", "Empty"),
    }


def test_clean_fields_have_no_issues():
    dataset = Dataset([Word(1, "ვაშლი", categories=(2,)), Word(2, "მსხალი", categories=(2,))],
                      {k: v for k, v in tree().items() if k != 3}, {"word_count": "2"})
    assert wr.field_issues(dataset) == {}


def test_missing_and_out_of_range_fields():
    words = [
        Word(1, "ა1", pos=None, categories=(2,)),
        Word(2, "ა2", pos="adverb", categories=(2,)),
        Word(3, "ა3", difficulty=None, categories=(2,)),
        Word(4, "ა4", difficulty=7, categories=(2,)),
        Word(5, "ა5", familiarity=0, concreteness=None, categories=(2,)),
        Word(6, "ა6", is_actable=None, is_family_safe=2, categories=(2,)),
        Word(7, "ა7"),
        Word(8, "ა8", categories=(99,)),
        Word(9, "ა9", categories=(1,)),
    ]
    issues = wr.field_issues(Dataset(words, tree(), {"word_count": "100"}))

    def ids(heading):
        return [int(line.split()[0]) for line in issues[heading]]

    assert ids("pos missing") == [1]
    assert ids("pos not one of noun / verb / adj / propn") == [2]
    assert ids("difficulty missing") == [3]
    assert ids("difficulty outside 1–5") == [4]
    assert ids("familiarity outside 1–5") == [5]
    assert ids("concreteness missing") == [5]
    assert ids("is_actable missing") == [6]
    assert ids("is_family_safe not 0 or 1") == [6]
    assert ids("no category") == [7]
    assert ids("linked to a category that does not exist") == [8]
    assert ids("linked to a branch instead of a leaf category") == [9]
    assert issues["leaf category with no words"] == ["`food_empty`"]
    assert "meta.word_count disagrees with the words table" in issues


def test_broken_category_tree():
    cats = {
        1: Category(1, None, "lonely", "x", None),
        2: Category(2, 42, "orphan", "y", "Orphan"),
        3: Category(3, None, "root", "z", "Root"),
        4: Category(4, 3, "leaf", "w", "Leaf"),
        5: Category(5, 4, "grandchild", "v", "Grandchild"),
    }
    words = [Word(1, "ხე", categories=(2, 4, 5))]
    issues = wr.field_issues(Dataset(words, cats))
    assert issues["branch with no leaf categories"] == ["`lonely`"]
    assert issues["category whose parent does not exist"] == ["`orphan` → parent 42"]
    assert issues["category nested deeper than branch → leaf"] == ["`grandchild`"]
    assert issues["category without an English name"] == ["`lonely`"]


def test_constant_columns():
    words = [Word(1, "ხე", difficulty=1), Word(2, "ცა", difficulty=2)]
    lines = wr.constant_columns(Dataset(words))
    assert any("is_family_safe" in line for line in lines)
    assert not any("difficulty" in line for line in lines)


# ------------------------------------------------------------------------ counts


def test_difficulty_and_tier_counts():
    words = [Word(i, f"w{i}", difficulty=d) for i, d in enumerate([1, 2, 2, 3, 4, 5, None])]
    assert wr.difficulty_counts(words) == {1: 1, 2: 2, 3: 1, 4: 1, 5: 1, None: 1}
    assert wr.tier_counts(words) == {
        "easy (≤ 2)": 3, "medium (≤ 3)": 4, "hard (≥ 4)": 2, "mixed (all)": 7,
    }


def test_category_counts_are_distinct_words():
    cats = tree() | {4: Category(4, None, "other", "სხვა", "Other"),
                     5: Category(5, 4, "other_leaf", "სხვა2", "Other leaf")}
    words = [Word(1, "ვაშლი", categories=(2, 3)),     # two leaves, one branch
             Word(2, "მსხალი", categories=(2, 5)),    # two branches
             Word(3, "ქლიავი", categories=(99,))]     # dangling, ignored
    leaf, branch = wr.category_counts(Dataset(words, cats))
    assert leaf == {2: 2, 3: 1, 5: 1}
    assert branch == {1: 2, 4: 1}


# ------------------------------------------------------------- end to end, on disk


def make_db(path: Path, words, categories, links, meta=None):
    with sqlite3.connect(path) as conn:
        conn.executescript(SCHEMA)
        conn.executemany("INSERT INTO categories VALUES (?,?,?,?,?,?)", categories)
        conn.executemany("INSERT INTO words VALUES (?,?,?,?,?,?,?,?,?)", words)
        conn.executemany("INSERT INTO word_categories VALUES (?,?)", links)
        conn.executemany("INSERT INTO meta VALUES (?,?)",
                         (meta or {"content_version": "20260101", "word_count": str(len(words))}).items())
    conn.close()


@pytest.fixture
def fixture_db(tmp_path):
    db = tmp_path / "words_ka.db"
    make_db(
        db,
        words=[
            (1, "ხე", "noun", 1, 5, 5, 1, 1, 1),
            (2, "ვაშლი", "noun", 1, 5, 5, 1, 1, 1),
            (3, "ვაშლი", "noun", 2, 5, 5, 1, 1, 1),
            (4, "ნიუ-იორკი", "propn", 2, 4, 5, 1, 0, 1),
            (5, "ნიუ იორკი", "propn", 2, 4, 5, 1, 0, 1),
            (6, "pizza", "noun", 1, 5, 5, 1, 1, 1),
            (7, "ერთი ორი სამი ოთხი", "noun", None, 3, 3, 1, None, 1),
        ],
        categories=[(1, None, "food", "საკვები", "Food", 1), (2, 1, "food_fruits", "ხილი", "Fruit", 1)],
        links=[(1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2)],
    )
    return db


def test_load_reads_every_column(fixture_db):
    dataset = wr.load(fixture_db)
    assert len(dataset.words) == 7
    assert dataset.words[0] == Word(1, "ხე", "noun", 1, 5, 5, 1, 1, 1, (2,))
    assert dataset.words[6].categories == ()
    assert dataset.meta["content_version"] == "20260101"


def test_load_missing_file_raises(tmp_path):
    with pytest.raises(FileNotFoundError):
        wr.load(tmp_path / "nope.db")


def test_main_writes_report_and_csv_without_touching_db(fixture_db, tmp_path):
    report = tmp_path / "report.md"
    removals = tmp_path / "removals.csv"
    before = hashlib.sha256(fixture_db.read_bytes()).hexdigest()
    siblings = set(fixture_db.parent.iterdir())

    assert wr.main(["--db", str(fixture_db), "--report", str(report), "--csv", str(removals)]) == 0

    assert hashlib.sha256(fixture_db.read_bytes()).hexdigest() == before
    # no -journal or -wal file left next to the database
    assert set(fixture_db.parent.iterdir()) - siblings == {report, removals}

    with removals.open(encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    assert list(rows[0]) == ["id", "lemma", "check", "reason"]
    assert {(r["id"], r["check"]) for r in rows} == {
        ("3", "exact_duplicate"),
        ("5", "normalized_duplicate"),
        ("6", "latin"),
        ("1", "too_short"),
        ("7", "too_long"),
    }
    assert all(r["reason"] for r in rows)

    text = report.read_text(encoding="utf-8")
    assert wr.MARKER in text
    assert "| Exact duplicate | 1 |" in text
    assert "| Duplicate after normalising | 1 |" in text
    assert "### difficulty missing — 1" in text
    assert "### no category — 1" in text
    assert "| `food` | ხილი (Fruit) | `food_fruits` | 6 |" in text
    assert "| missing | 1 |" in text


def test_rerun_keeps_hand_written_header_and_is_stable(fixture_db, tmp_path):
    report = tmp_path / "report.md"
    removals = tmp_path / "removals.csv"
    report.write_text(f"# My notes\n\nKeep me.\n\n{wr.MARKER}\n\nstale generated text\n",
                      encoding="utf-8")
    args = ["--db", str(fixture_db), "--report", str(report), "--csv", str(removals)]

    wr.main(args)
    first = report.read_text(encoding="utf-8")
    assert first.startswith("# My notes\n\nKeep me.\n\n" + wr.MARKER)
    assert "stale generated text" not in first

    wr.main(args)
    assert report.read_text(encoding="utf-8") == first


def test_report_without_marker_keeps_existing_text(fixture_db, tmp_path):
    report = tmp_path / "report.md"
    report.write_text("# Intro only\n", encoding="utf-8")
    wr.main(["--db", str(fixture_db), "--report", str(report), "--csv", str(tmp_path / "r.csv")])
    text = report.read_text(encoding="utf-8")
    assert text.startswith("# Intro only\n\n" + wr.MARKER)


@pytest.mark.skipif(not wr.DEFAULT_DB.exists(), reason="bundled words_ka.db not present")
def test_real_database_matches_its_meta():
    dataset = wr.load(wr.DEFAULT_DB)
    assert str(len(dataset.words)) == dataset.meta["word_count"]
    assert sum(wr.difficulty_counts(dataset.words).values()) == len(dataset.words)
