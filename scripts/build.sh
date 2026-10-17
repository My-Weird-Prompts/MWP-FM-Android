#!/usr/bin/env bash
# Regenerate the Android project from twa-manifest.json, build a signed APK + AAB,
# verify package/version/signing cert, and stage dist/mwp-fm-<version>.apk.
# Usage: scripts/build.sh
# Bump appVersionCode/appVersion in twa-manifest.json first for a new release.
# Full runbook: docs/RELEASING.md
set -euo pipefail
cd "$(dirname "$0")/.."

SIGNING_DIR="${MWP_FM_SIGNING_DIR:-$HOME/.config/mwp-fm-android}"
# Must match radio/.well-known/assetlinks.json in My-Weird-Prompts.
EXPECTED_CERT="388c2cc1c9a31f5656f03702520ff02d7c144683abc48e7b6dd5d1a46d18dad3"

PASS="$(cat "$SIGNING_DIR/keystore-password")"
export BUBBLEWRAP_KEYSTORE_PASSWORD="$PASS" BUBBLEWRAP_KEY_PASSWORD="$PASS"

bubblewrap update --skipVersionUpgrade </dev/null
bubblewrap build --skipPwaValidation </dev/null

# Verify with the same JDK/SDK bubblewrap uses.
JDK="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.bubblewrap/config.json")))["jdkPath"])')"
SDK="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.bubblewrap/config.json")))["androidSdkPath"])')"
BT="$SDK/build-tools/34.0.0"
"$BT/aapt2" dump badging app-release-signed.apk | sed -n 1p
CERT="$(JAVA_HOME="$JDK" PATH="$JDK/bin:$PATH" "$BT/apksigner" verify --print-certs app-release-signed.apk 2>/dev/null \
  | sed -n 's/^Signer #1 certificate SHA-256 digest: //p')"
if [ "$CERT" != "$EXPECTED_CERT" ]; then
  echo "ERROR: signing cert $CERT does not match assetlinks fingerprint $EXPECTED_CERT" >&2
  exit 1
fi
echo "Signing cert matches assetlinks.json"

VERSION="$(python3 -c 'import json;print(json.load(open("twa-manifest.json"))["appVersion"])')"
mkdir -p dist
cp app-release-signed.apk "dist/mwp-fm-$VERSION.apk"
sha256sum "dist/mwp-fm-$VERSION.apk"
echo "Built dist/mwp-fm-$VERSION.apk"
