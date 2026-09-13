#!/usr/bin/env python3
"""
Fails if the built app would crash on launch for want of an ad application id.

The Google Mobile Ads SDK throws `GADInvalidInitializationException` from its initialiser
when `GADApplicationIdentifier` is missing or empty. That is a launch crash, not a build
error, so nothing upstream of running the app notices.

This has happened once already. Converting the app's group to a synchronized folder
destroyed the file reference the target's base configuration pointed at; `pod install`
then filled the empty slot with its own xcconfig, every `$(AD_UNIT)` in Info.plist
resolved to nothing, and the build stayed green all the way onto a phone.

Checks the built product rather than the project, so it catches any cause: a lost base
configuration, a key missing from the template, a typo in Info.plist.

    ./scripts/verify-ad-config.py <path-to-.app>
"""

import plistlib
import sys
from pathlib import Path

# Keys substituted from Config.xcconfig that the app cannot run without. An empty value is
# as bad as a missing one, which is why both are checked.
REQUIRED = [
    "GADApplicationIdentifier",
    "BANNER_AD_ID",
    "INTERSTITIAL_AD_ID",
    "APP_OPEN_AD_ID",
    "REMOVE_ADS_PRODUCT_ID",
]

if len(sys.argv) != 2:
    print(__doc__.strip(), file=sys.stderr)
    sys.exit(2)

app = Path(sys.argv[1])
info = app / "Info.plist"
if not info.is_file():
    print(f"error: no Info.plist in {app}", file=sys.stderr)
    sys.exit(1)

plist = plistlib.loads(info.read_bytes())

problems = []
for key in REQUIRED:
    value = plist.get(key)
    if value is None:
        problems.append(f"  {key}: missing")
    elif not str(value).strip():
        problems.append(f"  {key}: empty — the xcconfig substitution did not resolve")
    # An unresolved substitution reaches the plist verbatim rather than as an empty string.
    elif str(value).startswith("$("):
        problems.append(f"  {key}: unsubstituted ({value})")

if problems:
    print("error: the built app is missing ad configuration:", file=sys.stderr)
    print("\n".join(problems), file=sys.stderr)
    print(
        "\nUsually the target's base configuration is no longer Gamoitsani/Config.xcconfig.",
        file=sys.stderr,
    )
    sys.exit(1)

print(f"ad configuration present in {app.name} ({len(REQUIRED)} keys)")
