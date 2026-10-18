#!/usr/bin/env bash
# Add the current release APK to the self-hosted F-Droid repo, re-sign the index and
# sync it to R2 (https://ai-files.myweirdprompts.com/fdroid/repo).
# Usage: scripts/fdroid-publish.sh            (after scripts/build.sh + the R2 APK upload)
#        scripts/fdroid-publish.sh --dry-run  (build the index locally, upload nothing)
# R2 is the source of truth for repo/: it is pulled down first, so any machine works.
# Runbook: docs/FDROID.md
set -euo pipefail
cd "$(dirname "$0")/.."

DRY_RUN=0; [ "${1:-}" = "--dry-run" ] && DRY_RUN=1
SIGNING_DIR="${MWP_FM_SIGNING_DIR:-$HOME/.config/mwp-fm-android}"
ENV_FILE="${MWP_R2_ENV:-$(cd .. && pwd)/My-Weird-Prompts/.env.production}"
BUCKET=mwp-public-files-other
PREFIX=fdroid

# Toolchain: same JDK/SDK as bubblewrap. fdroidserver: `uv tool install fdroidserver --with 'setuptools<81'`.
JDK="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.bubblewrap/config.json")))["jdkPath"])')"
SDK="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.bubblewrap/config.json")))["androidSdkPath"])')"
export JAVA_HOME="$JDK" ANDROID_HOME="$SDK" PATH="$JDK/bin:$SDK/build-tools/34.0.0:$PATH"
export FDROID_REPO_KEY_PASS="$(cat "$SIGNING_DIR/fdroid-repo-password")"

# R2 credentials (CF_R2_KEY_ID / CF_R2_ACCESS_KEY) as an env-only rclone remote.
eval "$(grep -E '^CF_R2_(KEY_ID|ACCESS_KEY)=' "$ENV_FILE" | sed 's/^/export /')"
export RCLONE_CONFIG_MWPR2_TYPE=s3 RCLONE_CONFIG_MWPR2_PROVIDER=Cloudflare \
  RCLONE_CONFIG_MWPR2_ACCESS_KEY_ID="$CF_R2_KEY_ID" RCLONE_CONFIG_MWPR2_SECRET_ACCESS_KEY="$CF_R2_ACCESS_KEY" \
  RCLONE_CONFIG_MWPR2_ENDPOINT=https://81ee9810726226b99b56e4d84ffac020.r2.cloudflarestorage.com \
  RCLONE_CONFIG_MWPR2_NO_CHECK_BUCKET=true

cd fdroid
mkdir -p repo archive
rclone copy "mwpr2:$BUCKET/$PREFIX/repo" repo --exclude 'status/**'
rclone copy "mwpr2:$BUCKET/$PREFIX/archive" archive --exclude 'status/**'

VERSION="$(python3 -c 'import json;print(json.load(open("../twa-manifest.json"))["appVersion"])')"
CODE="$(python3 -c 'import json;print(json.load(open("../twa-manifest.json"))["appVersionCode"])')"
APK="../dist/mwp-fm-$VERSION.apk"
[ -f "$APK" ] || { echo "ERROR: $APK missing; run scripts/build.sh first" >&2; exit 1; }
cp "$APK" "repo/com.myweirdprompts.fm_$CODE.apk"

rm -rf tmp repo/status archive/status
fdroid update 2>&1 | grep -v pkg_resources
python3 -c "import json;v=json.load(open('repo/index-v2.json'))['packages']['com.myweirdprompts.fm']['versions'];print('Versions in index:',sorted(x['manifest']['versionCode'] for x in v.values()))"

if [ "$DRY_RUN" = 1 ]; then echo "Dry run: not uploading"; exit 0; fi
rclone sync repo "mwpr2:$BUCKET/$PREFIX/repo" --exclude 'status/**' --header-upload "Cache-Control: no-cache" -v
rclone sync archive "mwpr2:$BUCKET/$PREFIX/archive" --exclude 'status/**' --header-upload "Cache-Control: no-cache" -v
echo "Published https://ai-files.myweirdprompts.com/$PREFIX/repo"
