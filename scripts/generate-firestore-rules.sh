#!/bin/bash
#
# Generates firestore.rules from firestore.rules.template, substituting the collection
# names held in the gitignored Config.xcconfig. Both the config and the generated rules
# stay out of git; only the template is committed.
#
# Usage:  ./scripts/generate-firestore-rules.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="Gamoitsani/Resources/Configuration/Config.xcconfig"
TEMPLATE="firestore.rules.template"
OUTPUT="firestore.rules"

if [ ! -f "$CONFIG" ]; then
  echo "error: $CONFIG not found — copy Config.xcconfig.template first (see docs/SETUP.md)" >&2
  exit 1
fi

read_key() {
  local value
  value=$(grep -E "^$1 *=" "$CONFIG" | head -1 | sed -E 's/^[A-Z_]+ *= *//' | tr -d '[:space:]')
  if [ -z "$value" ] || [ "$value" = "REPLACE_ME" ]; then
    echo "error: $1 is unset or still REPLACE_ME in $CONFIG" >&2
    exit 1
  fi
  printf '%s' "$value"
}

WORDS=$(read_key WORDS_COLLECTION_NAME)
SUGGESTED=$(read_key SUGGESTED_WORDS_COLLECTION_NAME)

sed -e "s|__WORDS_COLLECTION__|$WORDS|g" \
    -e "s|__SUGGESTED_WORDS_COLLECTION__|$SUGGESTED|g" \
    "$TEMPLATE" > "$OUTPUT"

if grep -q "__WORDS_COLLECTION__\|__SUGGESTED_WORDS_COLLECTION__" "$OUTPUT"; then
  echo "error: placeholders remain in $OUTPUT" >&2
  exit 1
fi

echo "wrote $OUTPUT"
echo
echo "Review it, then deploy. If the Firebase CLI is not installed, npx runs it without"
echo "a global install (the project is pinned in .firebaserc):"
echo "    npx -y firebase-tools login"
echo "    npx -y firebase-tools deploy --only firestore:rules"
echo
echo "NOTE: deploying disables the in-app word review feature by design — its writes are"
echo "the vulnerability being closed. See the header of $TEMPLATE."
