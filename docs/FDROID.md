# F-Droid repo

MWP FM is distributed through the self-hosted My Weird Prompts F-Droid repository. Users
add the repo once in an F-Droid client (F-Droid, Droid-ify, Neo Store) and the client then
installs and updates the app like any store app.

| | |
| --- | --- |
| Repo URL | `https://ai-files.myweirdprompts.com/fdroid/repo` |
| Index signing fingerprint (SHA-256) | `9EF8AA135BECA4F168B4DB56F34875B31C41425C8D2A0B054F784DE20C1D53E3` |
| Short link | `myweirdprompts.com/fdroid` |
| Repo, CI, config, metadata, key handling | [My-Weird-Prompts/fdroid](https://github.com/My-Weird-Prompts/fdroid) |

**Publishing is automatic:** that repo's workflow checks this repo's GitHub releases
hourly and indexes the APK attached to the newest release (asset `mwp-fm-<version>.apk`).
So the GitHub release in [RELEASING.md](RELEASING.md) step 5 is the publish step.

History: from 2026-10-18 to 2026-10-20 the repo was built by hand from `fdroid/` and
`scripts/fdroid-publish.sh` in this repo. Both were removed when it moved to
My-Weird-Prompts/fdroid on CI, with the same URL and index key.

## Why self-hosted rather than a store

The main F-Droid repo builds from source and signs with its own key. That build could
not upgrade over the release-signed APK, and its fingerprint would also have to go in
`assetlinks.json`. IzzyOnDroid's inclusion policy excludes "apps which are only
launching a website inside a webview", which describes a TWA. A self-hosted repo needs
nobody's approval, and it keeps the release key.

Obtainium is the other no-approval route. It tracks GitHub releases on this repo, which
has been public since 2026-10-18.
