#!/usr/bin/env bash
# Regenerate the Android project from twa-manifest.json and build a signed APK + AAB.
# Usage: scripts/build.sh            (uses the version already in twa-manifest.json)
# Bump appVersionCode/appVersion in twa-manifest.json first for a new release.
set -euo pipefail
cd "$(dirname "$0")/.."

SIGNING_DIR="${MWP_FM_SIGNING_DIR:-$HOME/.config/mwp-fm-android}"
PASS="$(cat "$SIGNING_DIR/keystore-password")"
export BUBBLEWRAP_KEYSTORE_PASSWORD="$PASS" BUBBLEWRAP_KEY_PASSWORD="$PASS"

bubblewrap update --skipVersionUpgrade </dev/null
bubblewrap build --skipPwaValidation </dev/null

VERSION="$(python3 -c 'import json;print(json.load(open("twa-manifest.json"))["appVersion"])')"
mkdir -p dist
cp app-release-signed.apk "dist/mwp-fm-$VERSION.apk"
echo "Built dist/mwp-fm-$VERSION.apk"
