#!/usr/bin/env python3
"""
Fails if the app asks for a string the catalogue does not have.

`l10n("...")` returns the key itself when it is missing, so a typo ships as a raw key on
screen rather than as a build error. Run from the repo root.
"""

import json
import re
import sys
from pathlib import Path

CATALOGUE = Path(
    "Libraries/Packages/GamoitsaniL10n/Sources/GamoitsaniL10n/Resources/Localizable.xcstrings"
)
SOURCES = [Path("Gamoitsani")]

# l10n("key") and L10n.string("key", ...). Interpolated keys are skipped deliberately —
# `l10n("rules.\(index)")` cannot be checked without evaluating it.
CALL = re.compile(r'(?:l10n|L10n\.string)\(\s*"([^"\\]+)"')

catalogue = json.loads(CATALOGUE.read_text())
known = set(catalogue["strings"])

used: dict[str, list[str]] = {}
for root in SOURCES:
    for path in root.rglob("*.swift"):
        for key in CALL.findall(path.read_text()):
            used.setdefault(key, []).append(str(path))

missing = {k: v for k, v in used.items() if k not in known}
if missing:
    print("error: keys used in code but absent from the catalogue:", file=sys.stderr)
    for key, files in sorted(missing.items()):
        print(f"  {key}  ({', '.join(sorted(set(files)))})", file=sys.stderr)
    sys.exit(1)

# Not fatal: a key may be built by interpolation, or kept for a screen not written yet.
unused = sorted(known - set(used))
print(f"{len(used)} keys used, all present. {len(unused)} in the catalogue are unreferenced.")
