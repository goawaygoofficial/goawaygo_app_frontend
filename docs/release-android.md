# Android release builds

How to build the Android app for testers and send it to them. Pre-launch, builds go to testers through
**Firebase App Distribution** (free, no Play Store needed); the Play Store comes at launch.

## Supported phones

**Android 8.0 (API 26) or newer**, 32- and 64-bit; iOS 15.0 or newer. The minimum comes from `sentry_flutter` 10
(crash reporting); it is set in `android/app/build.gradle.kts` and the iOS project. Phones on Android 7 can't install
new builds (they keep the version they have).

## Environments

The app reads its settings from a bundled env file (public values only — never secrets):

| Build                | Env file                     | Backend                         |
| -------------------- | ---------------------------- | ------------------------------- |
| `flutter run` (dev)  | `.env` (local, gitignored)   | your PC (`http://localhost:8080`) |
| Staging (testers)    | `env/staging.env` (committed) | `https://api.goawaygo.com`      |

Pick the file with `--dart-define=ENV_FILE=...`; without it the app uses `.env`.

## Signing

Release builds are signed with the **upload key**, created once per machine that publishes builds:

```bash
bash scripts/create-upload-key.sh
```

It writes `~/.goaway/goaway-upload.jks` and `android/key.properties` (gitignored, random password) and prints the
key's SHA-1 / SHA-256 fingerprints (public). **Back up both** (password manager or encrypted drive) and never commit
them. Without them, release builds fall back to the debug key (fine for CI, not for testers).

Google Sign-In on Android checks the signing certificate: the upload key's **SHA-1** must be registered in Google
Cloud (project `goaway-483709`) → Google Auth Platform → Clients → an **Android** client for package
`com.goawaygo.app`. The debug key has its own client for development.

## Release a staging build

One command builds both APKs, writes `latest.json` and (with `--upload`) publishes them:

```bash
bash scripts/release-android.sh 1.0.0 3 "What's new in this build" --upload
```

- The build number (`3`) must be higher than every earlier release, or phones won't install it as an update.
- Output in `build/release/`: `goawaygo-<version>-<build>-arm64.apk` (64-bit phones, ~20 MB),
  `goawaygo-<version>-<build>-universal.apk` (all Android 8.0+ phones, 32- and 64-bit) and `latest.json`.
- `--upload` puts them in the Cloudflare R2 bucket `goawaygo-downloads` → `https://downloads.goawaygo.com/android/`
  (APKs first, then `latest.json`). The website's `/download` page reads `latest.json`, so it shows the new version
  without a website change. First time only: `npx wrangler login` (Cloudflare sign-in in the browser).
- The script refuses to run without the upload key, so a debug-signed build can never be published.

## Send it to beta testers (Firebase App Distribution)

1. Firebase console → project **goaway-483709** → App Distribution.
2. Drag in `build/release/goaway-<version>-<build>-universal.apk`, add the release notes.
3. Pick the **beta** group (people who signed up through the website's "Join the beta" invite link) and distribute.
   They get notified and update through the Firebase App Tester app.

## At launch (Play Store)

Build an App Bundle instead (`flutter build appbundle --release --dart-define=ENV_FILE=env/production.env`), enrol
in Play App Signing, and register Play's **app signing** SHA-1 in the Android OAuth client too.
