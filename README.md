# MWP FM — Android

Sideloadable Android app for [MWP FM](https://stream.myweirdprompts.com), the
My Weird Prompts streaming PWA (source: `danielrosehill/mwp-radio`).

It is a **Trusted Web Activity (TWA)** generated with
[Bubblewrap](https://github.com/GoogleChromeLabs/bubblewrap): a thin Android shell that
opens `https://stream.myweirdprompts.com/` full-screen in Chrome. The app has no copy of
the web code, so **every web deploy of mwp-radio reaches the app with no rebuild.** You
only need a new APK to change the shell itself: name, icons, colours, shortcuts,
package or version.

| | |
| --- | --- |
| Package | `com.myweirdprompts.fm` |
| Download (always latest) | <https://ai-files.myweirdprompts.com/mwp-fm.apk> |
| Versioned copies | `https://ai-files.myweirdprompts.com/mwp-fm-<version>.apk` |
| R2 bucket | `mwp-public-files-other` (served as `ai-files.myweirdprompts.com`) |
| Linked from | myweirdprompts.com header "Android App" + `/subscribe/listen` |

## Releases

| Version | Code | Date | Notes |
| --- | --- | --- | --- |
| 1.0.0 | 1 | 2026-10-17 | First TWA build. Replaces the Expo "MWP Listener" APK (`mwp-listener-v3.apk`) as the site download. |

## Building

Prerequisites, all set up on Daniel's laptop on 2026-10-17:

- `@bubblewrap/cli` 1.24.1 (global npm, node v20)
- `~/.bubblewrap/config.json` → `jdkPath` = `~/.bubblewrap/jdk/jdk-17.0.20.1+1` (Temurin 17),
  `androidSdkPath` = `~/Development/Android/Sdk`
- Android SDK: `cmdline-tools/latest`, `build-tools;34.0.0`, `platforms;android-35`

```bash
# 1. bump appVersionCode (+1) and appVersion in twa-manifest.json
# 2. build
scripts/build.sh          # → dist/mwp-fm-<version>.apk (+ app-release-bundle.aab)
# 3. upload dist/mwp-fm-<version>.apk to R2 as mwp-fm-<version>.apk AND mwp-fm.apk
# 4. git tag v<version>, push, create a GitHub release with the APK attached
```

Only `twa-manifest.json` is the source of truth. `bubblewrap update` regenerates `app/`,
the Gradle files and the icons from it, so edit the manifest and do not edit `app/` by hand.

## Signing key

- Keystore: `~/.config/mwp-fm-android/release.keystore`, alias `mwp-fm`
- Password: `~/.config/mwp-fm-android/keystore-password`. The store and key passwords are the same.
- SHA-256: `38:8C:2C:C1:C9:A3:1F:56:56:F0:37:02:52:0F:F0:2D:7C:14:46:83:AB:C4:8E:7B:6D:D5:D1:A4:6D:18:DA:D3`

The keystore is not in git. **If it is lost, users cannot upgrade in place.** Android
rejects an update signed with a different key, so every user would have to uninstall
first, and you would also have to change `assetlinks.json`.

The same fingerprint is published at
`https://stream.myweirdprompts.com/.well-known/assetlinks.json`, which is in the
mwp-radio repo. That file proves to Chrome that the app and the site belong together.
Without it, the app still works but shows a browser URL bar at the top.

## Setup gotchas (found 2026-10-17)

- **Bubblewrap's bundled-JDK download in March 2026 was truncated.** The
  `~/.bubblewrap/jdk/OpenJDK17U-…tar.gz` was incomplete, so `jdk17u-jdk-17.0.11-9`
  was a source tree, not a runnable JDK. `config.json` had been left empty, which is
  probably why the first attempt was abandoned in favour of Expo. Fix: download
  Temurin 17 from `api.adoptium.net` and point `jdkPath` at it.
- **Bubblewrap rejects a standard SDK layout** with `The provided androidSdk isn't
  correct.` `AndroidSdkTools.validatePath` requires `<sdk>/tools` or `<sdk>/bin` at
  the SDK root. A Google-style install has `cmdline-tools/latest/bin` instead. Fix:
  `ln -s cmdline-tools/latest/bin ~/Development/Android/Sdk/bin`.
- `bubblewrap init` is interactive. Writing `twa-manifest.json` by hand and running
  `bubblewrap update` avoids it. Passwords are passed through
  `BUBBLEWRAP_KEYSTORE_PASSWORD` / `BUBBLEWRAP_KEY_PASSWORD`, with stdin closed.

## History

The earlier Android app was a separate React Native/Expo codebase, built with EAS cloud
builds: `danielrosehill/MWP-Android-APK`, published as `mwp-listener-v2/v3.apk`. It
stopped being developed in April 2026, while the PWA kept improving. The decision
record `mwp-radio/planning/decisions/003-pwa-vs-native-apk.md` names TWA as the path
for an APK without a rewrite. The TWA does not give the PWA's limits a native fix
(background audio on aggressive OEMs, no Android Auto). The Expo route remains the
path if those become requirements.
