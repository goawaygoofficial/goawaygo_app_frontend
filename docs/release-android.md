# Android release builds

How to build the Android app for testers and send it to them. Pre-launch, builds go to testers through
**Firebase App Distribution** (free, no Play Store needed); the Play Store comes at launch.

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
`com.goawayofficial.app`. The debug key has its own client for development.

## Build a staging release

```bash
flutter build apk --release --dart-define=ENV_FILE=env/staging.env
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Bump `version:` in `pubspec.yaml` (`1.0.0+2`, …: the number
after `+` must increase) for every build you send to testers, or phones won't install it as an update.

## Send it to testers (Firebase App Distribution)

1. Firebase console → project **goaway-483709** → Release & Monitor → **App Distribution**.
2. Drag the APK in, add release notes (what changed, what to test).
3. Add testers by email (or a tester group). They get an email with an install link; first time, they install the
   Firebase App Tester app and allow installs from it.

## At launch (Play Store)

Build an App Bundle instead (`flutter build appbundle --release --dart-define=ENV_FILE=env/production.env`), enrol
in Play App Signing, and register Play's **app signing** SHA-1 in the Android OAuth client too.
