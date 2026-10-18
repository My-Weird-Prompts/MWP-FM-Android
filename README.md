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
| Versioned copies | `https://ai-files.myweirdprompts.com/mwp-fm-<version>.apk` |
| R2 bucket | `mwp-public-files-other` (served as `ai-files.myweirdprompts.com`) |
| Linked from | myweirdprompts.com header "Android App", `/subscribe/listen`, `/app` (hero button + `#android` card), MWP FM About screen (Android browsers only) |
| Short links | `myweirdprompts.com/apk` → the APK; `myweirdprompts.com/android` → `/app#android` (both in `website/vercel.json`) |

## Releases

| Version | Code | Date | Notes |
| --- | --- | --- | --- |
| 1.0.0 | 1 | 2026-10-17 | First TWA build. Replaces the Expo "MWP Listener" APK (`mwp-listener-v3.apk`) as the site download. |

## App stores (checked 2026-10-18)

- **F-Droid main repo**: not viable as-is. It builds from public FOSS source and signs
  with F-Droid's own key, and this repo is private with no licence. An F-Droid-signed
  build would also need its fingerprint added to `assetlinks.json` and could not
  upgrade over our signed APK.
- **IzzyOnDroid**: its [App Inclusion Policy](https://izzyondroid.org/docs/general/AppInclusionPolicy/)
  lists "apps which are only launching a website inside a webview" (no added value over a
  bookmark) as excluded. A TWA is exactly that, so expect a rejection. This was not tested.
- **Viable without anyone's approval**: a self-hosted F-Droid repo (built with
  `fdroidserver`, index on R2), which users add in F-Droid, Droid-ify or Neo Store, and
  [Obtainium](https://obtainium.imranr.dev/) tracking GitHub releases. Obtainium needs this
  repo to be public.

Most updates need no reinstall in any case, because web deploys reach the app directly
(see above).

## Building and releasing

Full runbook, including toolchain setup from scratch, R2 upload and verification:
**[docs/RELEASING.md](docs/RELEASING.md)**. In short: bump `appVersionCode` and
`appVersion` in `twa-manifest.json`, run `scripts/build.sh`, upload to R2 as both
`mwp-fm-<version>.apk` and `mwp-fm.apk`, then tag and create a GitHub release.

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
