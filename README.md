# MWP FM — Android

Sideloadable Android app for [MWP FM](https://stream.myweirdprompts.com), the
My Weird Prompts streaming PWA (source: `radio/` in `danielrosehill/My-Weird-Prompts`. The Vercel project `mwp-radio` builds from that folder. The standalone `danielrosehill/mwp-radio` repo is stale and is **not** deployed).

It is a **Trusted Web Activity (TWA)** generated with
[Bubblewrap](https://github.com/GoogleChromeLabs/bubblewrap): a thin Android shell that
opens `https://stream.myweirdprompts.com/` full-screen in Chrome. The app has no copy of
the web code, so **every web deploy of the radio app reaches the app with no rebuild.** You
only need a new APK to change the shell itself: name, icons, colours, shortcuts,
package or version.

| | |
| --- | --- |
| Package | `com.myweirdprompts.fm` |
| Download (always latest) | <https://ai-files.myweirdprompts.com/mwp-fm.apk> |
| F-Droid repo | `https://ai-files.myweirdprompts.com/fdroid/repo`, fingerprint `9EF8AA135BECA4F168B4DB56F34875B31C41425C8D2A0B054F784DE20C1D53E3`. Run from [My-Weird-Prompts/fdroid](https://github.com/My-Weird-Prompts/fdroid); see [docs/FDROID.md](docs/FDROID.md) |
| Obtainium | Add `https://github.com/My-Weird-Prompts/MWP-FM-Android` (tracks GitHub releases) |
| Licence | Apache-2.0 (the Bubblewrap template is Apache-2.0) |
| Versioned copies | `https://ai-files.myweirdprompts.com/mwp-fm-<version>.apk` |
| R2 bucket | `mwp-public-files-other` (served as `ai-files.myweirdprompts.com`) |
| Linked from | F-Droid is the recommended path on the site (since 2026-10-20): header "Android App" → `/app#android`; `/app` hero and `#android` card lead with F-Droid and keep the APK as fallback; `/subscribe/listen` and the MWP FM About screen (Android browsers only) → `/app/fdroid` |
| Short links | `myweirdprompts.com/apk` → the APK; `myweirdprompts.com/android` → `/app#android`; `myweirdprompts.com/fdroid` → `/app/fdroid` (setup guide) (both in `website/vercel.json`) |

## Releases

| Version | Code | Date | Notes |
| --- | --- | --- | --- |
| 1.0.0 | 1 | 2026-10-17 | First TWA build. Replaces the Expo "MWP Listener" APK (`mwp-listener-v3.apk`) as the site download. |

## Update channels

Most updates need no reinstall, because web deploys reach the app directly. For shell
releases, users can choose:

- the **self-hosted F-Droid repo** (auto-updates in F-Droid, Droid-ify or Neo Store).
  See [docs/FDROID.md](docs/FDROID.md), which also explains why it is not in the main
  F-Droid repo or IzzyOnDroid.
- **Obtainium**, pointed at this repo's GitHub releases. It works, but the website deliberately does not mention it (Daniel's call, 2026-10-20): the site offers F-Droid (recommended) and the APK only.
- a manual download of `mwp-fm.apk`.

All three carry the same release-signed APK, so a user can switch between them without
reinstalling.

## Building and releasing

Full runbook, including toolchain setup from scratch, R2 upload and verification:
**[docs/RELEASING.md](docs/RELEASING.md)**. In short: bump `appVersionCode` and
`appVersion` in `twa-manifest.json`, run `scripts/build.sh`, upload to R2 as both
`mwp-fm-<version>.apk` and `mwp-fm.apk`, then tag and create a GitHub release. The
F-Droid repo picks the release up by itself within the hour.

`twa-manifest.json` is the only source of truth. Never hand-edit `app/`.

## Signing key

- Keystore: `~/.config/mwp-fm-android/release.keystore`, alias `mwp-fm`
- Password: `~/.config/mwp-fm-android/keystore-password`. The store and key passwords are the same.
- SHA-256: `38:8C:2C:C1:C9:A3:1F:56:56:F0:37:02:52:0F:F0:2D:7C:14:46:83:AB:C4:8E:7B:6D:D5:D1:A4:6D:18:DA:D3`

The keystore is not in git. **If it is lost, users cannot upgrade in place.** Android
rejects an update signed with a different key, so every user would have to uninstall
first, and you would also have to change `assetlinks.json`.

The same fingerprint is published at
`https://stream.myweirdprompts.com/.well-known/assetlinks.json`, which is in the
`My-Weird-Prompts` repo at `radio/.well-known/assetlinks.json`. That file proves to Chrome that the app and the site belong together.
Without it, the app still works but shows a browser URL bar at the top.

## Setup gotchas

See the "Gotchas" section of [docs/RELEASING.md](docs/RELEASING.md): the truncated
Bubblewrap JDK, the SDK path check, the R2 upload route, and the non-interactive init.

## History

The earlier Android app was a separate React Native/Expo codebase, built with EAS cloud
builds: `danielrosehill/MWP-Android-APK`, published as `mwp-listener-v2/v3.apk`. It
stopped being developed in April 2026, while the PWA kept improving. The decision
record `My-Weird-Prompts/radio/planning/decisions/003-pwa-vs-native-apk.md` names TWA as the path
for an APK without a rewrite. The TWA does not give the PWA's limits a native fix
(background audio on aggressive OEMs, no Android Auto). The Expo route remains the
path if those become requirements.
