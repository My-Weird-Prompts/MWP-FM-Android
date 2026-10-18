# Self-hosted F-Droid repo

MWP FM is distributed through its own F-Droid repository. Users add the repo once in
an F-Droid client (F-Droid, Droid-ify, Neo Store), and the client then installs and
updates the app like any store app. Set up and first published on 2026-10-18; every
fact below was verified that day unless marked otherwise.

| | |
| --- | --- |
| Repo URL | `https://ai-files.myweirdprompts.com/fdroid/repo` |
| Index signing fingerprint (SHA-256) | `9EF8AA135BECA4F168B4DB56F34875B31C41425C8D2A0B054F784DE20C1D53E3` |
| One-tap add link | `https://ai-files.myweirdprompts.com/fdroid/repo?fingerprint=9EF8AA135BECA4F168B4DB56F34875B31C41425C8D2A0B054F784DE20C1D53E3` |
| Short link | `myweirdprompts.com/fdroid` → the add link (`website/vercel.json` in My-Weird-Prompts) |
| Hosting | R2 bucket `mwp-public-files-other`, prefixes `fdroid/repo/` and `fdroid/archive/` |
| Config | `fdroid/config.yml`, app metadata `fdroid/metadata/com.myweirdprompts.fm.yml`, app icon `fdroid/metadata/com.myweirdprompts.fm/en-US/icon.png`, repo icon `fdroid/icon.png` |
| Index signing key | `~/.config/mwp-fm-android/fdroid-repo.keystore`, alias `mwp-fm-fdroid-repo`. The password is in `fdroid-repo-password` beside it; the store and key passwords are the same. Not in git. |
| Publish script | `scripts/fdroid-publish.sh` (`--dry-run` builds the index locally without uploading) |

The index key is separate from the APK release key. The client pins the index key when
a user adds the repo. **If the index key is lost, every user has to remove and re-add the
repo** under a new fingerprint. The installed app is unaffected, because the APK is still
signed with the release key. Back up both keys together.

## Publishing a release

After `scripts/build.sh` and the R2 upload in [RELEASING.md](RELEASING.md):

```bash
scripts/fdroid-publish.sh
```

The script:

1. pulls the current `fdroid/repo` and `fdroid/archive` from R2. R2 is the source of truth
   for repo state, and the local `fdroid/repo/` is git-ignored.
2. copies `dist/mwp-fm-<appVersion>.apk` in as `com.myweirdprompts.fm_<appVersionCode>.apk`.
3. runs `fdroid update`, which re-signs `entry.jar` and the indexes. `archive_older: 3`
   moves older versions to `archive/`.
4. runs `rclone sync` back to R2 with `Cache-Control: no-cache`.

R2 credentials are `CF_R2_KEY_ID` and `CF_R2_ACCESS_KEY`, read from
`../My-Weird-Prompts/.env.production`. Override the path with `MWP_R2_ENV`. They are
exposed as an env-only rclone remote. The laptop's `r2-daniel` remote gets a 403 on this
bucket, and per-file presigned PUTs are what RELEASING.md uses for the APK itself.

Verify afterwards. Each file should return 200 with a sha256 matching the local copy in
`fdroid/repo/`:

```bash
B=https://ai-files.myweirdprompts.com/fdroid/repo
curl -s "$B/entry.json"                                   # timestamp should be new
curl -s "$B/index-v2.json?v=$RANDOM" | python3 -c "import json,sys;print([v['manifest']['versionCode'] for v in json.load(sys.stdin)['packages']['com.myweirdprompts.fm']['versions'].values()])"
```

## Toolchain

```bash
uv tool install fdroidserver --with 'setuptools<81'    # 2.4.5 used
```

The JDK and Android SDK are the ones Bubblewrap uses (`~/.bubblewrap/config.json`).
The script exports `JAVA_HOME`, `ANDROID_HOME` and build-tools 34.0.0 on `PATH`.

## Gotchas found while setting it up

- **`fdroid init` crashes with `No module named 'pkg_resources'`** on a plain
  `uv tool install fdroidserver` (2.4.5, Python 3.13). setuptools 81 removed
  `pkg_resources`; pin `setuptools<81` as above.
- **`fdroid init --keystore <path>` does not create a keystore at `<path>`** if the file is
  missing. It generates `keystore.p12` in the current directory and still writes `<path>`
  into `config.yml`. The keystore was moved to `~/.config/mwp-fm-android/` by hand.
- **`repo_icon` is resolved against the working directory (`fdroid/`), not
  `repo/icons/`**, even though the warning says `repo_icon "repo/icons/icon.png" does
  not exist`. Putting the file in `repo/icons/` does not help, because `fdroid update`
  overwrites it with an 833-byte placeholder. Keep it at `fdroid/icon.png`.
- **Do not put loose files in `repo/`.** `fdroid update -c` turned a stray `repo/icon.png`
  into a bogus package named after its sha256, complete with skeleton metadata.
- **No app icon is extracted from the TWA APK** (the `icons-*` dirs stay empty), so the
  icon comes from `metadata/com.myweirdprompts.fm/en-US/icon.png`.
- `fdroid lint` reports `Categories 'Multimedia' is not valid` and that `NonFreeNet` is not
  a valid anti-feature. Those lists are only defined in fdroiddata's `config/`. The index
  is generated correctly regardless, and clients render both.

## Why self-hosted rather than a store

The main F-Droid repo builds from source and signs with its own key. That build could
not upgrade over the release-signed APK, and its fingerprint would also have to go in
`assetlinks.json`. IzzyOnDroid's inclusion policy excludes "apps which are only
launching a website inside a webview", which describes a TWA. A self-hosted repo needs
nobody's approval, and it keeps the release key.

Obtainium is the other no-approval route. It tracks GitHub releases on this repo, which
has been public since 2026-10-18.
