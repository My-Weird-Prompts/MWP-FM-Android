# Releasing MWP FM for Android

This runbook is the process used for v1.0.0 on 2026-10-17. Every step was run and
verified that day unless it is marked otherwise.

## When you need a release (and when you don't)

The APK is a Trusted Web Activity. It opens `https://stream.myweirdprompts.com/` in
Chrome and contains none of the web code.

- **Web/UI/feature change to the radio app** → **no APK release.** Push to
  `My-Weird-Prompts` (`radio/`). Vercel deploys it and installed apps show it on next
  launch.
- **Shell change** (app name, launcher icon, theme/navigation colours, shortcuts,
  orientation, start URL, package, min SDK) → release, via `twa-manifest.json`.
- **Bubblewrap/Android target-SDK bump** (Play-style hygiene, new Android version) →
  release.

## Moving parts

| Thing | Where |
| --- | --- |
| Shell source of truth | `twa-manifest.json` in this repo. `app/` and the Gradle files are generated from it; never hand-edit them. |
| Web app source | `radio/` in `danielrosehill/My-Weird-Prompts`, deployed by the Vercel project `mwp-radio` to `stream.myweirdprompts.com`. The standalone `danielrosehill/mwp-radio` repo is stale; its builds are skipped by the ignore step. |
| Digital Asset Links | `My-Weird-Prompts/radio/.well-known/assetlinks.json`, served at `https://stream.myweirdprompts.com/.well-known/assetlinks.json` |
| Signing key | `~/.config/mwp-fm-android/release.keystore`, alias `mwp-fm`. The password is in `keystore-password` beside it; the store and key passwords are the same. |
| Public download | R2 bucket `mwp-public-files-other`, which is served at `https://ai-files.myweirdprompts.com/`. Keys: `mwp-fm.apk` (latest) and `mwp-fm-<version>.apk`. |
| Site links | `My-Weird-Prompts/website/src/components/Header.astro` (Subscribe menu "Android App") and `website/src/pages/subscribe/listen.astro` ("MWP FM (Android)"). Both point at `mwp-fm.apk`, so a normal release does not touch them. |
| GitHub release | `My-Weird-Prompts/MWP-FM-Android` (private), tag `v<version>`, APK attached |

## 1. Toolchain (one-off per machine)

Check whether it is already set up:

```bash
bubblewrap --version                       # 1.24.1 used
cat ~/.bubblewrap/config.json              # jdkPath + androidSdkPath both set
ls ~/Development/Android/Sdk/build-tools   # must contain 34.0.0 (bubblewrap's BUILD_TOOLS_VERSION)
ls -l ~/Development/Android/Sdk/bin        # symlink → cmdline-tools/latest/bin
```

From scratch:

```bash
npm i -g @bubblewrap/cli

# JDK 17. Do NOT trust bubblewrap's own JDK download; see the gotchas below.
mkdir -p ~/.bubblewrap/jdk && cd ~/.bubblewrap/jdk
curl -sSL -o jdk17.tar.gz "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"
tar xzf jdk17.tar.gz && rm jdk17.tar.gz          # → jdk-17.x.y+z/
JDK=$(ls -d ~/.bubblewrap/jdk/jdk-17*)

# Android SDK (ANDROID_HOME is ~/Development/Android/Sdk in the shell profile)
SDK=~/Development/Android/Sdk; mkdir -p $SDK/cmdline-tools
curl -sSL -o /tmp/cmdline.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q /tmp/cmdline.zip -d /tmp/cmdline && mv /tmp/cmdline/cmdline-tools $SDK/cmdline-tools/latest
yes | JAVA_HOME=$JDK $SDK/cmdline-tools/latest/bin/sdkmanager --sdk_root=$SDK \
  "build-tools;34.0.0" "platforms;android-35" "platform-tools"
ln -sfn cmdline-tools/latest/bin $SDK/bin        # bubblewrap path check needs <sdk>/bin

printf '{"jdkPath":"%s","androidSdkPath":"%s"}' "$JDK" "$SDK" > ~/.bubblewrap/config.json
```

The signing key must be **restored** to `~/.config/mwp-fm-android/`, not regenerated.
A new key breaks in-place upgrades for every installed copy and requires a new
`assetlinks.json` fingerprint.

## 2. Bump the version

In `twa-manifest.json`, set `appVersionCode` to the previous value + 1 (Android
refuses to install a lower or equal code over an existing install) and set
`appVersion` (semver). Make any shell changes in the same file.

## 3. Build and verify

```bash
scripts/build.sh
```

This runs `bubblewrap update --skipVersionUpgrade` (regenerates `app/` from the
manifest) and `bubblewrap build --skipPwaValidation`, with the keystore passwords passed
through `BUBBLEWRAP_KEYSTORE_PASSWORD` and `BUBBLEWRAP_KEY_PASSWORD` and stdin closed
so it never prompts. It then:

- prints the `aapt2` badging line. Check `package`, `versionCode` and `versionName`.
- checks that the APK's signer SHA-256 equals the `assetlinks.json` fingerprint, and
  **exits non-zero if it differs**.
- copies the APK to `dist/mwp-fm-<version>.apk` and prints its sha256.

Builds are not byte-reproducible: rebuilding the same version gives a different sha256 from the published file. That is expected and harmless because the signing key is the same, but compare sha256 against *this* build when you upload. The outputs `*.apk`, `*.aab` and `dist/` are git-ignored. The build takes about 1 minute
once Gradle is cached.

## 4. Upload to R2

Use both keys: the versioned one and the `mwp-fm.apk` alias.

Neither direct route works:

- `mcp__gateway__cloudflare__r2_object_put` with `source_path` runs on residenceserver
  and cannot see laptop files (ENOENT).
- The local `rclone` remote `r2-daniel` is not scoped to this bucket (403).

What works is a presigned PUT from the gateway, then curl from the laptop:

1. `mcp__gateway__cloudflare__r2_presign` with bucket `mwp-public-files-other`, key
   `mwp-fm-<version>.apk`, method `PUT`, expires_in `900`, content_type
   `application/vnd.android.package-archive`.
2. `curl -X PUT -H "Content-Type: application/vnd.android.package-archive" --upload-file dist/mwp-fm-<version>.apk "<url>"`
   should return 200. The URL includes `x-amz-checksum-crc32=AAAAAA==`; R2 accepted
   the upload anyway.
3. Repeat with key `mwp-fm.apk`.

Then verify that the public bytes match the local build. Add a cache-busting query
because Cloudflare fronts the domain:

```bash
sha256sum dist/mwp-fm-<version>.apk
for k in mwp-fm.apk mwp-fm-<version>.apk; do
  curl -s "https://ai-files.myweirdprompts.com/$k?v=$RANDOM" | sha256sum
  curl -sI "https://ai-files.myweirdprompts.com/$k" | grep -i content-type   # application/vnd.android.package-archive
done
```

## 5. Commit, tag, GitHub release

```bash
git commit -am "Release <version>: <what changed>"   # also add a row to the Releases table in README.md
git push
git tag v<version> && git push origin v<version>
gh release create v<version> dist/mwp-fm-<version>.apk --title "MWP FM <version>" --notes "<what changed>"
```

## 6. Verify the full-screen link (only when package or key changed, or on first release)

```bash
curl -s "https://digitalassetlinks.googleapis.com/v1/assetlinks:check?source.web.site=https://stream.myweirdprompts.com&relation=delegate_permission/common.handle_all_urls&target.android_app.package_name=com.myweirdprompts.fm&target.android_app.certificate.sha256_fingerprint=38:8C:2C:C1:C9:A3:1F:56:56:F0:37:02:52:0F:F0:2D:7C:14:46:83:AB:C4:8E:7B:6D:D5:D1:A4:6D:18:DA:D3"
# → {"linked": true, ...}
```

If it is not linked, the app still runs but shows a Chrome URL bar. The usual causes:
the file was committed somewhere that doesn't deploy (see "Web app source" above), or the
fingerprint or package changed.

## 7. Device check (manual, by Daniel)

Sideload `https://ai-files.myweirdprompts.com/mwp-fm.apk` over the existing install. It
should upgrade in place with no uninstall, and open full-screen with no URL bar. Check
that playback continues with the screen off. v1.0.0 was **not** device-tested at
release time.

## Gotchas found on 2026-10-17

- **Bubblewrap's JDK download can be silently truncated.** In March 2026 its
  `OpenJDK17U-…tar.gz` was incomplete, leaving `jdk17u-jdk-17.0.11-9`, a source
  tree, as the "JDK". `config.json` was left as `{"jdkPath":"","androidSdkPath":""}`.
  That is why the first TWA attempt stalled and the project went to Expo instead.
  Install Temurin yourself.
- **`The provided androidSdk isn't correct.`** `AndroidSdkTools.validatePath` (in
  `@bubblewrap/core/dist/lib/androidSdk/AndroidSdkTools.js`) only accepts a root that
  has `tools/` or `bin/`. Google's layout puts the tools in `cmdline-tools/latest/bin`.
  Fix: symlink `<sdk>/bin`.
- **`bubblewrap init` is interactive.** We wrote `twa-manifest.json` by hand. The
  schema is the `TwaManifestJson` interface in `@bubblewrap/core/dist/lib/TwaManifest.d.ts`.
  `bubblewrap update` then generated the project with no prompts.
- **The system Java is 25**, which is too new for Bubblewrap's Gradle. Always use
  the JDK 17 set in `config.json`.
- **Previous Android app:** `danielrosehill/MWP-Android-APK`, an Expo/React Native
  app built with `npx eas build -p android --profile preview` on the
  `my-weird-prompts` Expo account. It is retired. Its APKs
  (`mwp-listener-v2.apk` in `mwppublic`, `-v3.apk` in `mwp-public-files-other`) are
  left in place but no longer linked.
