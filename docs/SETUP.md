# Setup — building Gamoitsani from a fresh clone

Everything needed to build is in the repository. There are two generated inputs you have
to produce locally: `Config.xcconfig` (secrets, gitignored) and `Pods/` (`pod install`).

## Requirements

| | |
|---|---|
| Xcode | 16 or newer (verified on Xcode 26.6) |
| iOS deployment target | 18.0 |
| CocoaPods | 1.16+ (`brew install cocoapods`) |

## Steps

### 1. Clone

```sh
git clone https://github.com/davita00101110dmg/Gamoitsani.git
cd Gamoitsani
```

### 2. Create `Config.xcconfig`

The real config holds ad unit IDs and mediation SDK credentials, so it is not committed.
Copy the template:

```sh
cp Gamoitsani2/Config.xcconfig.template Gamoitsani2/Config.xcconfig
```

The template is **buildable and runnable as-is** — it ships Google's public AdMob *test*
unit IDs. That is enough to compile the app and launch it in the simulator. To point at
production, fill in the real values; every key is documented in the template.

Two of those keys matter more than they look. `ADMOB_TEST_DEVICE_ID` and
`UMP_TEST_DEVICE_ID` register a physical device so it receives *test* creatives even
against production unit IDs. Running a debug build on an unregistered device with real
units serves yourself real ads, which is invalid traffic and is how AdMob accounts get
flagged. Register the device first.

Keys flow `Config.xcconfig` → `Info.plist` (via `$(VAR)` substitution) → runtime. A
missing key does **not** break the build — it surfaces as a dead ad unit, not a compile
error. If something is mysteriously empty at runtime, check this file first.

### 3. Install pods

```sh
LANG=en_US.UTF-8 pod install
```

The locale is not optional on Ruby 4.x — without it CocoaPods dies on a UTF-8 encoding
error before it does anything.

`Pods/` is generated and not tracked. `Podfile.lock` **is** tracked, so this resolves the
same versions everyone else has. CocoaPods carries the ad SDKs only; everything else is
SPM.

### 4. Open the workspace

```sh
open Gamoitsani.xcworkspace
```

**Always open `Gamoitsani.xcworkspace`, never `Gamoitsani.xcodeproj`** — the pods are only
wired up in the workspace.

The eight local packages under `Libraries/Packages/` are referenced by path, so Xcode
resolves them automatically on first open.

### 5. Build

```sh
xcodebuild build \
  -workspace Gamoitsani.xcworkspace \
  -scheme Gamoitsani2 \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

Or ⌘B in Xcode.

## Running tests

The tests live in the packages, not in an app target — the `Gamoitsani2` scheme has no
test action at all, and asking for one reports "not currently configured for the test
action".

```sh
UDID=$(xcrun simctl list devices available --json | /usr/bin/python3 -c \
  'import json,sys;print(next(d["udid"] for v in json.load(sys.stdin)["devices"].values() for d in v if "iPhone" in d["name"]))')

for pkg in GamoitsaniCore GamoitsaniEngine GamoitsaniDesign GamoitsaniData \
           GamoitsaniL10n GamoitsaniAds GamoitsaniCapture; do
  ( cd "Libraries/Packages/$pkg" && xcodebuild test \
      -scheme "$pkg" -destination "id=$UDID" CODE_SIGNING_ALLOWED=NO )
done
```

`GamoitsaniMacros` is the exception — it is a compiler plugin, builds for the host
toolchain, and has no simulator destination:

```sh
( cd Libraries/Packages/GamoitsaniMacros && swift test )
```

## Running on a physical device

There is a `run-on-device` skill in `.claude/skills/` with the exact incantation. The one
thing worth knowing up front: the `-destination` UDID is **not** the identifier
`xcrun devicectl list devices` prints. Get the right one from:

```sh
xcodebuild -showdestinations -workspace Gamoitsani.xcworkspace -scheme Gamoitsani2 \
  | grep -i 'platform:iOS,' | grep -v Simulator
```

## Troubleshooting

**`Config.xcconfig not found` / unresolved `$(BANNER_AD_ID)`** — you skipped step 2.

**`Pods-Gamoitsani2.debug.xcconfig` missing** — you skipped step 3. `Config.xcconfig`
`#include`s the pod xcconfigs, so `pod install` must run before the first build.

**`pod install` fails with a UTF-8 / encoding error** — set `LANG=en_US.UTF-8`.

**Build works from Xcode but not the CLI** — check you passed `-workspace`, not `-project`.

**"Scheme Gamoitsani2 is not currently configured for the test action"** — expected. See
"Running tests" above.

**A sound or word file is missing at runtime while the build succeeds** — package
resources do not always rebuild incrementally. Check the built `.app` bundle rather than
the exit code.
