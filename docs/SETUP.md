# Setup — building Gamoitsani from a fresh clone

Everything needed to build is in the repository. There are two generated inputs you have
to produce locally: `Config.xcconfig` (secrets, gitignored) and `Pods/` (`pod install`).

## Requirements

| | |
|---|---|
| Xcode | 16 or newer (verified on Xcode 26.6) |
| iOS deployment target | 16.0 |
| CocoaPods | 1.16+ (`brew install cocoapods` or `gem install cocoapods`) |

## Steps

### 1. Clone

```sh
git clone https://github.com/davita00101110dmg/Gamoitsani.git
cd Gamoitsani
```

### 2. Create `Config.xcconfig`

The real config holds ad unit IDs, Firestore collection names and mediation SDK secrets,
so it is not committed. Copy the template:

```sh
cp Gamoitsani/Resources/Configuration/Config.xcconfig.template \
   Gamoitsani/Resources/Configuration/Config.xcconfig
```

The template is **buildable and runnable as-is** — it ships Google's public AdMob *test*
unit IDs and placeholder collection names. That is enough to compile the app and launch it
in the simulator. To point at production, fill in the real values; every key is documented
in the template.

Keys flow `Config.xcconfig` → `Gamoitsani/Resources/Info.plist` (via `$(VAR)` substitution)
→ `Configuration.value(for:)` at runtime. A missing key does **not** break the build — it
throws at runtime and the caller logs and falls back to an empty string. So a typo here
surfaces as a dead ad unit or an empty Firestore query, not a compile error. If something
is mysteriously empty at runtime, check this file first.

### 3. Install pods

```sh
pod install
```

`Pods/` is generated and no longer tracked in git. `Podfile.lock` **is** tracked, so this
resolves the same versions everyone else has.

### 4. Open the workspace

```sh
open Gamoitsani.xcworkspace
```

**Always open `Gamoitsani.xcworkspace`, never `Gamoitsani.xcodeproj`** — the pods are only
wired up in the workspace.

The local Swift package at `Libraries/Packages/GamoitsaniMacros` (which provides the
`@UserDefault` macro used by `AppSettings.swift`) is committed and referenced by path, so
Xcode resolves it automatically. Remaining dependencies (Firebase, swift-collections,
facebook-ios-sdk) come from SPM and resolve on first open.

### 5. Build

```sh
xcodebuild build \
  -workspace Gamoitsani.xcworkspace \
  -scheme Gamoitsani \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

Or just hit ⌘B in Xcode.

## Running tests

```sh
xcodebuild test \
  -workspace Gamoitsani.xcworkspace \
  -scheme Gamoitsani \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

> **Known broken.** The `GamoitsaniTests` target does not currently compile:
> `CoreDataManagerTests` calls `WordFirebase.init` with 4 of its 11 required arguments, and
> `LanguageManagerTests` references a `UserDefaults.Keys` type that does not exist. The 39
> existing test cases therefore never run. Repairing this is **Phase 1** of the 2.0
> roadmap — see [`docs/2.0/PLAN.md`](2.0/PLAN.md). Until then CI builds the app but does
> not gate on tests.

## Firestore security rules

The rules live in `firestore.rules.template` with the collection names redacted, since
those names are held in the gitignored `Config.xcconfig`. Generate and deploy:

```sh
./scripts/generate-firestore-rules.sh     # writes firestore.rules (gitignored)

# npx avoids a global install; .firebaserc pins the target project, so rules cannot be
# deployed to the wrong one by accident.
npx -y firebase-tools login
npx -y firebase-tools deploy --only firestore:rules
```

The rules can also be pasted into the Firebase console under Firestore Database → Rules,
which needs no CLI at all.

**Deploying is a production change with a deliberate breaking effect.** The rules make
the words collection read-only from clients, which closes the hole where any
unauthenticated caller could delete documents from the live word database — and which
therefore **disables the in-app word review feature** (the one behind five taps on the
title), because that feature's writes are the attack path. Reads, challenges and word
suggestions all keep working, so the shipped v1.7 app is otherwise unaffected.

### Testing the rules

```sh
cd firestore-tests && npm install
./run.sh
```

19 checks against the Firestore emulator: five that the shipped app still works, and
fourteen that the hole is shut. Requires a JDK — if `java -version` fails and you have
Android Studio, its bundled runtime works:

```sh
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

## Troubleshooting

**`Config.xcconfig not found` / unresolved `$(BANNER_AD_ID)`** — you skipped step 2.

**`Pods-Gamoitsani.debug.xcconfig` missing** — you skipped step 3. `Config.xcconfig`
`#include`s the pod xcconfigs, so `pod install` must run before the first build.

**Build works from Xcode but not the CLI** — check you passed `-workspace`, not `-project`.

**`GamoitsaniMacros` fails to resolve** — the package lives at
`Libraries/Packages/GamoitsaniMacros`. If the reference broke, re-add it in Xcode with
File → Add Package Dependencies → Add Local.
