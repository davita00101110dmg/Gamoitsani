#!/usr/bin/env python3
"""Quality report on the bundled Georgian word database. Reads, never writes.

    python3 tools/words/words_report.py

Opens `words_ka.db` read-only, runs the checks below, and writes two files:

    docs/words-report.md                  everything below the GENERATED marker;
                                          the hand-written part above it is kept
    tools/words/suggested-removals.csv    id, lemma, reason — one row per finding

What it checks:

    duplicates      exact, and again after normalising case, spaces and punctuation
    characters      Latin letters, digits, other scripts, stray symbols and spacing
    length          1-2 letters (too short), more than 3 words (too long for a card)
    fields          missing or out-of-range difficulty, pos, scales and flags;
                    words with no category, links to missing or non-leaf categories
    counts          words per category branch and leaf, per difficulty and tier

Nothing here edits a word. The CSV is a list of suggestions for a human to read.
"""

from __future__ import annotations

import argparse
import csv
import io
import sqlite3
import sys
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DB = REPO_ROOT / "Libraries/Packages/GamoitsaniData/Sources/GamoitsaniData/WordFiles/words_ka.db"
DEFAULT_REPORT = REPO_ROOT / "docs/words-report.md"
DEFAULT_CSV = REPO_ROOT / "tools/words/suggested-removals.csv"

# Everything above this line in the report is hand-written and survives a re-run.
MARKER = "<!-- GENERATED BELOW by tools/words/words_report.py — edits under this line are overwritten -->"

# Modern Georgian is written in Mkhedruli. U+10D0..U+10FA are its letters; U+10FB..U+10FF
# are punctuation and archaic additions that do not belong on a card.
MKHEDRULI = range(0x10D0, 0x10FB)
# The other Georgian scripts. Mtavruli is Mkhedruli's all-caps form; the other two are
# ecclesiastical. All three are "Georgian" to Unicode but wrong for a lemma.
OTHER_GEORGIAN = {
    "Mtavruli": range(0x1C90, 0x1CC0),
    "Asomtavruli": range(0x10A0, 0x10D0),
    "Nuskhuri": range(0x2D00, 0x2D30),
}

POS_VALUES = {"noun", "verb", "adj", "propn"}
SCALE = range(1, 6)  # difficulty, concreteness, familiarity: 1..5
FLAGS = {0, 1}

MAX_WORDS = 3
MIN_LETTERS = 3

# Lists in the report are cut here; the CSV always has every row.
LIST_LIMIT = 60

# The order checks appear in, in the summary, the report and the CSV.
CHECKS = [
    ("exact_duplicate", "Exact duplicate"),
    ("normalized_duplicate", "Duplicate after normalising"),
    ("latin", "Latin letters"),
    ("digit", "Digits"),
    ("other_script", "Other scripts"),
    ("stray_symbol", "Stray symbols or spacing"),
    ("too_short", "Too short (1-2 letters)"),
    ("too_long", "Too long (more than 3 words)"),
]


# ---------------------------------------------------------------------------- data


@dataclass(frozen=True)
class Word:
    id: int
    lemma: str
    pos: str | None = "noun"
    difficulty: int | None = 3
    concreteness: int | None = 3
    familiarity: int | None = 3
    is_describable: int | None = 1
    is_actable: int | None = 0
    is_family_safe: int | None = 1
    categories: tuple[int, ...] = ()


@dataclass(frozen=True)
class Category:
    id: int
    parent_id: int | None
    slug: str
    name_ka: str
    name_en: str | None
    sort_order: int = 0


@dataclass
class Dataset:
    words: list[Word]
    categories: dict[int, Category] = field(default_factory=dict)
    meta: dict[str, str] = field(default_factory=dict)


@dataclass(frozen=True)
class Finding:
    check: str
    word_id: int
    lemma: str
    reason: str


def load(db_path: Path) -> Dataset:
    """Read the database through a read-only URI, so not even a journal is written."""
    if not db_path.exists():
        raise FileNotFoundError(db_path)
    uri = f"file:{db_path.resolve()}?mode=ro&immutable=1"
    with sqlite3.connect(uri, uri=True) as conn:
        links: dict[int, list[int]] = defaultdict(list)
        for word_id, category_id in conn.execute(
            "SELECT word_id, category_id FROM word_categories ORDER BY word_id, category_id"
        ):
            links[word_id].append(category_id)

        words = [
            Word(*row, categories=tuple(links.get(row[0], ())))
            for row in conn.execute(
                "SELECT id, lemma, pos, difficulty, concreteness, familiarity,"
                " is_describable, is_actable, is_family_safe FROM words ORDER BY id"
            )
        ]
        categories = {
            row[0]: Category(*row)
            for row in conn.execute(
                "SELECT id, parent_id, slug, name_ka, name_en, sort_order FROM categories"
            )
        }
        meta = dict(conn.execute("SELECT key, value FROM meta"))
    return Dataset(words, categories, meta)


# -------------------------------------------------------------------------- checks


def normalize(text: str) -> str:
    """The key two entries collide on: case-folded, with only letters and digits kept.

    NFKC first, so compatibility forms and composed/decomposed pairs agree; casefold
    also maps Mtavruli onto Mkhedruli. Spaces, hyphens, punctuation and invisible
    format characters all drop out.
    """
    folded = unicodedata.normalize("NFKC", text).casefold()
    return "".join(ch for ch in folded if unicodedata.category(ch)[0] in "LN")


def find_duplicates(words: list[Word]) -> list[Finding]:
    """The lowest id in each group is kept; the rest are flagged.

    Ids are stable and players' seen-lists are keyed on them, so the oldest id is the
    one worth keeping. A word that is both an exact and a normalised duplicate is
    reported once, as exact.
    """
    findings: list[Finding] = []

    by_lemma: dict[str, list[Word]] = defaultdict(list)
    for word in words:
        by_lemma[word.lemma].append(word)
    exact_dupes: set[int] = set()
    for group in by_lemma.values():
        keep, *rest = sorted(group, key=lambda w: w.id)
        for word in rest:
            exact_dupes.add(word.id)
            findings.append(Finding(
                "exact_duplicate", word.id, word.lemma, f"exact duplicate of id {keep.id}"
            ))

    by_key: dict[str, list[Word]] = defaultdict(list)
    for word in words:
        if word.id not in exact_dupes:
            by_key[normalize(word.lemma)].append(word)
    for key, group in by_key.items():
        if not key or len(group) < 2:
            continue
        keep, *rest = sorted(group, key=lambda w: w.id)
        for word in rest:
            findings.append(Finding(
                "normalized_duplicate", word.id, word.lemma,
                f"same as id {keep.id} '{keep.lemma}' after normalising case, spaces and punctuation",
            ))
    return findings


def _script_name(ch: str) -> str:
    """'CYRILLIC' for 'д', 'GREEK' for 'λ' — the first word of the Unicode name."""
    name = unicodedata.name(ch, "")
    return name.split(" ")[0] if name else f"U+{ord(ch):04X}"


def character_findings(word: Word) -> list[Finding]:
    """One finding per kind of problem, listing the offending characters."""
    lemma = word.lemma
    latin: list[str] = []
    digits: list[str] = []
    other: dict[str, list[str]] = defaultdict(list)
    stray: list[str] = []

    for ch in lemma:
        cp = ord(ch)
        cat = unicodedata.category(ch)
        if cp in MKHEDRULI or ch in " -":
            continue
        georgian = next((n for n, r in OTHER_GEORGIAN.items() if cp in r), None)
        if georgian:
            other[georgian].append(ch)
        elif cat == "Nd" or ch.isdigit():
            digits.append(ch)
        elif cat[0] == "L" and "LATIN" in unicodedata.name(ch, ""):
            latin.append(ch)
        elif cat[0] == "L":
            other[_script_name(ch).title()].append(ch)
        else:
            stray.append(ch)

    # Spaces and hyphens are allowed only singly and between letters:
    # 'ნიუ-იორკი' and 'რიო-დე-ჟანეირო' are fine, ' ხე', 'ხე  ცა' and 'ხე-' are not.
    spacing: list[str] = []
    if lemma != lemma.strip(" -"):
        spacing.append("leading or trailing space/hyphen")
    if any(pair in lemma for pair in ("  ", "--", " -", "- ")):
        spacing.append("doubled or mixed space/hyphen")

    def show(chars: list[str]) -> str:
        # The code point too: lookalikes and invisible characters are the usual culprits.
        return ", ".join(f"'{c}' U+{ord(c):04X}" for c in dict.fromkeys(chars))

    findings = []
    if latin:
        findings.append(Finding("latin", word.id, lemma, f"Latin letters: {show(latin)}"))
    if digits:
        findings.append(Finding("digit", word.id, lemma, f"digits: {show(digits)}"))
    for script, chars in sorted(other.items()):
        findings.append(Finding("other_script", word.id, lemma, f"{script} script: {show(chars)}"))
    if stray or spacing:
        parts = ([f"symbols: {show(stray)}"] if stray else []) + spacing
        findings.append(Finding("stray_symbol", word.id, lemma, "; ".join(parts)))
    return findings


def letter_count(lemma: str) -> int:
    return sum(1 for ch in lemma if unicodedata.category(ch)[0] == "L")


def word_count(lemma: str) -> int:
    """Whitespace-separated words. A hyphen joins: 'რიო-დე-ჟანეირო' is one word."""
    return len(lemma.split())


def length_findings(word: Word) -> list[Finding]:
    letters = letter_count(word.lemma)
    words = word_count(word.lemma)
    if letters < MIN_LETTERS:
        return [Finding("too_short", word.id, word.lemma, f"too short: {letters} letter(s)")]
    if words > MAX_WORDS:
        return [Finding("too_long", word.id, word.lemma, f"too long: {words} words")]
    return []


def entry_findings(dataset: Dataset) -> list[Finding]:
    """Every per-entry finding, in CHECKS order, then by id."""
    findings = find_duplicates(dataset.words)
    for word in dataset.words:
        findings += character_findings(word)
        findings += length_findings(word)
    order = {check: i for i, (check, _) in enumerate(CHECKS)}
    return sorted(findings, key=lambda f: (order[f.check], f.word_id))


# ---------------------------------------------------------------------- field checks


def field_issues(dataset: Dataset) -> dict[str, list[str]]:
    """Missing or inconsistent fields, as human-readable lines grouped by heading.

    These are fixes to metadata, not reasons to drop a word, so they stay out of
    the removals CSV.
    """
    issues: dict[str, list[str]] = defaultdict(list)
    cats = dataset.categories

    def label(word: Word) -> str:
        return f"{word.id} `{word.lemma}`"

    for word in dataset.words:
        if word.pos is None or word.pos == "":
            issues["pos missing"].append(label(word))
        elif word.pos not in POS_VALUES:
            issues["pos not one of noun / verb / adj / propn"].append(f"{label(word)}: `{word.pos}`")

        for column in ("difficulty", "concreteness", "familiarity"):
            value = getattr(word, column)
            if value is None:
                issues[f"{column} missing"].append(label(word))
            elif value not in SCALE:
                issues[f"{column} outside 1–5"].append(f"{label(word)}: {value!r}")

        for column in ("is_describable", "is_actable", "is_family_safe"):
            value = getattr(word, column)
            if value is None:
                issues[f"{column} missing"].append(label(word))
            elif value not in FLAGS:
                issues[f"{column} not 0 or 1"].append(f"{label(word)}: {value!r}")

        if not word.categories:
            issues["no category"].append(label(word))
        for category_id in word.categories:
            category = cats.get(category_id)
            if category is None:
                issues["linked to a category that does not exist"].append(
                    f"{label(word)} → category {category_id}"
                )
            elif category.parent_id is None:
                issues["linked to a branch instead of a leaf category"].append(
                    f"{label(word)} → `{category.slug}`"
                )

    used = {cid for word in dataset.words for cid in word.categories}
    children = defaultdict(list)
    for category in cats.values():
        if category.parent_id is not None:
            children[category.parent_id].append(category)
            if category.parent_id not in cats:
                issues["category whose parent does not exist"].append(
                    f"`{category.slug}` → parent {category.parent_id}"
                )
            elif cats[category.parent_id].parent_id is not None:
                issues["category nested deeper than branch → leaf"].append(f"`{category.slug}`")
            if category.id not in used:
                issues["leaf category with no words"].append(f"`{category.slug}`")
        if not (category.name_en or "").strip():
            issues["category without an English name"].append(f"`{category.slug}`")
    for category in cats.values():
        if category.parent_id is None and not children[category.id]:
            issues["branch with no leaf categories"].append(f"`{category.slug}`")

    if dataset.meta.get("word_count") not in (None, str(len(dataset.words))):
        issues["meta.word_count disagrees with the words table"].append(
            f"meta says {dataset.meta['word_count']}, table has {len(dataset.words)}"
        )
    return dict(issues)


def constant_columns(dataset: Dataset) -> list[str]:
    """Columns that hold one value for every word — not wrong, but they filter nothing."""
    out = []
    if not dataset.words:
        return out
    for column in ("pos", "difficulty", "concreteness", "familiarity",
                   "is_describable", "is_actable", "is_family_safe"):
        values = {getattr(w, column) for w in dataset.words}
        if len(values) == 1:
            out.append(f"`{column}` is `{next(iter(values))!r}` for every word")
    return out


# --------------------------------------------------------------------------- counts


def difficulty_counts(words: list[Word]) -> Counter:
    return Counter(w.difficulty for w in words)


def tier_counts(words: list[Word]) -> dict[str, int]:
    """The app's four tiers, as `WordDifficulty` defines them."""
    known = [w.difficulty for w in words if isinstance(w.difficulty, int)]
    return {
        "easy (≤ 2)": sum(1 for d in known if d <= 2),
        "medium (≤ 3)": sum(1 for d in known if d <= 3),
        "hard (≥ 4)": sum(1 for d in known if d >= 4),
        "mixed (all)": len(words),
    }


def category_counts(dataset: Dataset) -> tuple[dict[int, int], dict[int, int]]:
    """Distinct words per leaf and per branch.

    A word can sit in several leaves, so neither column sums to the word count.
    """
    leaf: Counter = Counter()
    branch: dict[int, set[int]] = defaultdict(set)
    for word in dataset.words:
        for category_id in set(word.categories):
            category = dataset.categories.get(category_id)
            if category is None:
                continue
            leaf[category_id] += 1
            branch[category.parent_id if category.parent_id is not None else category.id].add(word.id)
    return dict(leaf), {cid: len(ids) for cid, ids in branch.items()}


# --------------------------------------------------------------------------- output


def _md(text: str) -> str:
    return text.replace("|", "\\|")


def render_report(dataset: Dataset, findings: list[Finding], source: str) -> str:
    words = dataset.words
    by_check: dict[str, list[Finding]] = defaultdict(list)
    for finding in findings:
        by_check[finding.check].append(finding)
    issues = field_issues(dataset)
    flagged_ids = {f.word_id for f in findings}

    out = io.StringIO()
    w = out.write

    w(f"## Results\n\n")
    w(f"Source: `{source}` · content_version `{dataset.meta.get('content_version', '?')}`"
      f" · {len(words):,} words · {len(dataset.categories)} categories\n\n")
    w("| Check | Entries |\n|---|---:|\n")
    for check, title in CHECKS:
        w(f"| {title} | {len(by_check[check])} |\n")
    w(f"| Field problems | {sum(len(v) for v in issues.values())} |\n")
    w(f"| **Distinct words in `suggested-removals.csv`** | **{len(flagged_ids)}** |\n\n")

    w("## Entry checks\n\n")
    w("Duplicates are matched exactly, then again after NFKC, case-folding and dropping "
      "every character that is not a letter or digit (spaces, hyphens, punctuation). In "
      "each group the lowest id is kept, since players' seen-lists are keyed on it.\n\n"
      "Allowed characters are Mkhedruli letters (U+10D0–U+10FA), plus a single space or "
      "hyphen between letters. A hyphen joins rather than splits, so `რიო-დე-ჟანეირო` "
      "counts as one word.\n\n")
    for check, title in CHECKS:
        rows = by_check[check]
        w(f"### {title} — {len(rows)}\n\n")
        if not rows:
            w("None.\n\n")
            continue
        w("| id | lemma | reason |\n|---:|---|---|\n")
        for f in rows[:LIST_LIMIT]:
            w(f"| {f.word_id} | {_md(f.lemma)} | {_md(f.reason)} |\n")
        if len(rows) > LIST_LIMIT:
            w(f"\n…and {len(rows) - LIST_LIMIT} more in `suggested-removals.csv`.\n")
        w("\n")

    w("## Field checks\n\n")
    w("Checked against the frozen schema in `docs/2.0/WORD-DB-SCHEMA.md`: `pos` in "
      "noun / verb / adj / propn; `difficulty`, `concreteness`, `familiarity` present and "
      "1–5; the three `is_*` flags present and 0 or 1; every word in at least one leaf "
      "category that exists; every category under a branch that exists. These are "
      "metadata fixes, not removals, so they are not in the CSV.\n\n")
    if not issues:
        w("No missing or inconsistent fields.\n\n")
    for heading in sorted(issues):
        lines = issues[heading]
        w(f"### {heading} — {len(lines)}\n\n")
        for line in lines[:LIST_LIMIT]:
            w(f"- {line}\n")
        if len(lines) > LIST_LIMIT:
            w(f"- …and {len(lines) - LIST_LIMIT} more\n")
        w("\n")
    constants = constant_columns(dataset)
    if constants:
        w("Not errors, but these columns carry no information yet:\n\n")
        for line in constants:
            w(f"- {line}\n")
        w("\n")

    w("## Counts per difficulty\n\n")
    w("| difficulty | words | share |\n|---|---:|---:|\n")
    counts = difficulty_counts(words)
    for key in sorted(counts, key=lambda k: (k is None, k if isinstance(k, int) else 0)):
        label = "missing" if key is None else str(key)
        w(f"| {label} | {counts[key]:,} | {counts[key] / max(len(words), 1):.1%} |\n")
    w("\nThe setup screen's tiers (`WordDifficulty`):\n\n| tier | words |\n|---|---:|\n")
    for tier, n in tier_counts(words).items():
        w(f"| {tier} | {n:,} |\n")
    w("\n")

    w("## Counts per category\n\n")
    leaf, branch = category_counts(dataset)
    links = sum(len(set(word.categories)) for word in words)
    w(f"{links:,} word–category links for {len(words):,} words: a word can sit in several "
      "leaves and even several branches, so the columns below do not add up to the word "
      "count. Counts are distinct words.\n\n")
    roots = sorted((c for c in dataset.categories.values() if c.parent_id is None),
                   key=lambda c: (c.sort_order, c.id))
    w("### Branches\n\n| branch | slug | words |\n|---|---|---:|\n")
    for root in roots:
        w(f"| {_md(root.name_ka)} ({_md(root.name_en or '')}) | `{root.slug}` | {branch.get(root.id, 0):,} |\n")
    w("\n### Leaves\n\n")
    playable = sum(1 for c in dataset.categories.values() if c.parent_id is not None and leaf.get(c.id, 0) >= 40)
    total_leaves = sum(1 for c in dataset.categories.values() if c.parent_id is not None)
    w(f"{playable} of {total_leaves} leaves have 40 or more words.\n\n")
    w("| branch | leaf | slug | words |\n|---|---|---|---:|\n")
    for root in roots:
        kids = sorted((c for c in dataset.categories.values() if c.parent_id == root.id),
                      key=lambda c: (c.sort_order, c.id))
        for kid in kids:
            w(f"| `{root.slug}` | {_md(kid.name_ka)} ({_md(kid.name_en or '')}) | `{kid.slug}` | {leaf.get(kid.id, 0):,} |\n")
    return out.getvalue()


DEFAULT_HEADER = "# Georgian word database — quality report\n\n"


def write_report(path: Path, body: str) -> None:
    """Replace everything below MARKER, keeping the hand-written header above it."""
    header = DEFAULT_HEADER
    if path.exists():
        existing = path.read_text(encoding="utf-8")
        if MARKER in existing:
            header = existing.split(MARKER, 1)[0]
        elif existing.strip():
            header = existing.rstrip("\n") + "\n\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"{header}{MARKER}\n\n{body}", encoding="utf-8")


def write_csv(path: Path, findings: list[Finding]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["id", "lemma", "check", "reason"])
        for f in findings:
            writer.writerow([f.word_id, f.lemma, f.check, f.reason])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV)
    args = parser.parse_args(argv)

    dataset = load(args.db)
    findings = entry_findings(dataset)
    try:
        source = args.db.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        source = args.db.name
    write_report(args.report, render_report(dataset, findings, source))
    write_csv(args.csv, findings)
    print(f"{len(dataset.words)} words, {len(findings)} findings "
          f"→ {args.report.name}, {args.csv.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
