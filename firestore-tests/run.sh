#!/bin/bash
#
# Runs the Firestore rules tests against the emulator.
#
# Requires a JDK. If `java -version` fails but Android Studio is installed, its bundled
# runtime works:
#   export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
#
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f ../firestore.rules ]; then
  echo "../firestore.rules missing — run ../scripts/generate-firestore-rules.sh first" >&2
  exit 1
fi
if [ ! -d node_modules ]; then
  echo "run 'npm install' in firestore-tests/ first" >&2
  exit 1
fi

exec ./node_modules/.bin/firebase emulators:exec \
  --only firestore \
  --project demo-gamoitsani \
  --config ../firebase.json \
  "node rules.test.mjs"
