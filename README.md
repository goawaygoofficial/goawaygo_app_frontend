# GoAwayGo — App Frontend

Flutter app for **GoAwayGo**, a travel app: search flights, hotels and rentals, explore destinations, and share trips in the Wanderbook.

Backend: [goawaygoofficial/goawaygo_backend](https://github.com/goawaygoofficial/goawaygo_backend) (Spring Boot).

## Documents in this repo

| File          | What it holds                                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------------------------- |
| `README.md`   | Everything about this repo: features, how it works, setup, deployment, how we work, resources, roadmap, history |
| `LINKS.md`    | Every link for dev, test and prod, and the shared consoles                                                      |
| `RELEASES.md` | What each version brought and where it runs                                                                     |

These are the only Markdown files. Every change updates them in the same pull request (new feature, new service,
new setting, a release reaching prod).

## Contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Motion and shared widgets](#motion-and-shared-widgets)
- [Authentication](#authentication)
- [Getting started](#getting-started)
- [Useful commands](#useful-commands)
- [Files that are never committed](#files-that-are-never-committed)
- [Languages and currencies (4.7)](#languages-and-currencies-47)
- [Android releases](#android-releases)
- [Releasing](#releasing)
- [How we work](#how-we-work)
- [Conventions and decisions](#conventions-and-decisions)
- [Resources and outside services](#resources-and-outside-services)
- [Booking partners](#booking-partners)
- [Roadmap](#roadmap)
- [History](#history)

## Features

| Module              | Folder                                                    | What it does                                                                                                     |
| ------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Auth                | `lib/features/01_auth_register`                           | Email sign up / sign in, Google Sign-In, forgot password                                                         |
| Home                | `lib/features/02_home`                                    | Categories, place search with suggestions, recent searches, ideas (new every minute)                             |
| Flights             | `lib/features/03_flights`                                 | Flight search (airport suggestions), recent fares, "See all flights" on Aviasales                                |
| Hotels              | `lib/features/04_hotels`                                  | Hotel search, partner cards opened on the place and dates (app-allowed partners)                                 |
| Rentals             | `lib/features/05_rentals`                                 | Car rental search (city or airport), rental partner cards                                                        |
| Book (shared)       | `lib/core/book`, `global_widgets/book`                    | Book API calls (`channel=app`), models, formatting; results layout and cards                                     |
| Destination info    | `lib/features/06_destinationInfo`                         | Travel animation, spot photos, the 9 AI cards                                                                    |
| My Trips            | `lib/features/07_trips`                                   | Trip plans and places saved from the ideas (sign-in needed)                                                      |
| Trip planner (4.4)  | `lib/features/10_plans`, `lib/core/plans`                 | Plan form, plan with day cards, change a day, share by link (website page), delete                               |
| Notifications (4.5) | `lib/features/11_notifications`, `lib/core/notifications` | Bell with unread badge, list, settings switches; push (Firebase Cloud Messaging), permission asks, tapped pushes |
| Me (4.6)            | `lib/features/09_profile`, `lib/core/account`             | User Profile: photo, name, email, password, country, currency (sheets); delete account; Recently Viewed          |
| Languages (4.7)     | `lib/core/i18n`, `assets/i18n`                            | `tr()`, 7 languages (Arabic right to left), picker on Profile, the traveller's currency, local date formats      |
| Discover (shared)   | `lib/core/discover`                                       | Discover API calls, models, recent searches on the device                                                        |
| Wanderbook          | `lib/features/08_wanderbook`                              | Feed, profiles, follow requests, posting original photos, likes, comments, reports                               |
| Wanderbook (shared) | `lib/core/wanderbook`                                     | Wanderbook API calls and models                                                                                  |
| Profile             | `lib/features/09_profile`                                 | My profile and other users' profiles                                                                             |

## Tech stack

- Flutter 3.47 (Dart SDK `^3.13.0`)
- State management: [`provider`](https://pub.dev/packages/provider)
- HTTP: [`http`](https://pub.dev/packages/http)
- Auth: [`google_sign_in`](https://pub.dev/packages/google_sign_in) 7,
  [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) for the refresh token
- Config: [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv)

## Project structure

```
lib/
├── main.dart              # App entry: loads .env, configures the backend client, restores the session
├── splash_screen.dart
├── core/
│   ├── backend.dart       # Wires AuthSession + ApiClient (tests inject fakes)
│   ├── api/               # ApiClient (Bearer token, refresh-on-401), ApiException
│   └── auth/              # AuthSession (tokens), RefreshTokenStore (secure storage)
├── features/              # One folder per feature (screens / widgets / services / utils)
├── global_utils/          # Colors, bottom navigation bar
├── global_widgets/        # Shared widgets (dialogs incl. confirm, animations, backgrounds)
├── models/                # Data models (User)
└── providers/             # ChangeNotifier providers (UserProvider)
```

## Motion and shared widgets

Navigation moves the same way as on the website, and nothing moves when the system asks for less motion
(`MediaQuery.disableAnimationsOf`):

- **Pages pushed on top** slide in a little from the right and fade in while the page under them drifts left;
  Back plays it in reverse (`global_utils/page_transitions.dart`, set in `main.dart`; iOS keeps its own swipe-back
  transition).
- **Tabs** glide towards the tab you picked; the selected icon pops and an indicator grows under it
  (`global_utils/bottom_bar/`).
- **Photo flights** (Wanderbook): a post's photo flies from the grid or feed into the post, and a person's photo
  from a list into their profile header. Use `Hero` with `postHeroTag` / `avatarHeroTag`, and pass what the screen
  already shows as `preview` to `openPost` / `openProfile` so the next screen can draw it at once. A tag must be
  unique on its screen (no Hero on feed author photos or on your own profile header).

Buttons are `PillButton` (`global_widgets/pill_button.dart`): `quiet` for secondary actions, `large` for a
screen's main action. Don't style a new ElevatedButton per screen.

## Authentication

- **Access token** (20 min): kept **in memory only**, sent as `Authorization: Bearer` by `ApiClient`.
- **Refresh token** (30 days): stored in the platform's **encrypted storage** (Android Keystore / iOS Keychain,
  `first_unlock_this_device`, never backed up). Requests send `X-Client-Type: mobile`, so the backend returns it
  in the response body.
- **Startup:** the session is restored with one `POST /api/auth/refresh`. Nothing about the user is stored on the
  device (an old SharedPreferences `user` key from earlier versions is removed). Offline at startup → shown as
  signed out, but the token is kept for next time.
- **Expiry:** a 401 on an authenticated request triggers one refresh and a retry; if the refresh is rejected the
  session ends.
- **No overlapping refreshes:** the backend treats reuse of a rotated refresh token as theft, so concurrent
  callers share one refresh request.
- **Google:** `google_sign_in` 7 with the **Web** client as `serverClientId` (the ID token's audience the backend
  accepts). The ID token goes to `POST /api/auth/google-signin`.
- **Sign out** (Profile header icon or User Profile → Sign Out) asks for confirmation, revokes the session on the
  server, clears the device and returns to the sign-in screen.
- **Forgot password** only asks for the email; the reset link arrives by email (backend: email-provider work).

Android **debug** builds may use plain HTTP to `10.0.2.2` / `localhost` only
(`android/app/src/debug/res/xml/network_security_config.xml`); release builds are HTTPS-only.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47+ (Dart 3.13+)
- Android Studio / Xcode for emulators, or a physical device
- The [backend](https://github.com/goawaygoofficial/goawaygo_backend) running locally or deployed

### 1. Clone and install

```bash
git clone https://github.com/goawaygoofficial/goawaygo_app_frontend.git
cd goawaygo_app_frontend
flutter pub get
```

### 2. Create `.env`

Copy the example. It already contains the project's (public) Google client IDs:

```bash
cp .env.example .env
```

| Variable               | Description                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| `BASE_URL`             | Backend URL, no trailing slash. Default `http://localhost:8080` with `adb reverse` (see _Run_).         |
| `GOOGLE_WEB_CLIENT_ID` | Google **Web** OAuth client. The app requests ID tokens for this audience; the backend only accepts it. |
| `GOOGLE_IOS_CLIENT_ID` | Google **iOS** OAuth client for bundle ID `com.goawaygo.app`                                            |

> `.env` is bundled into the app as an asset, so anyone with the app can read it. Only put **public** config here — never real secrets.

### 3. Google Sign-In on your machine (Android)

App ID (Android package and iOS bundle ID): **`com.goawaygo.app`**. Google Cloud project: `goaway-483709`.

Android has no client ID in the app: Google recognises it by the package name **and the SHA-1 of the signing
key**. Each developer's debug key is different, so ask the project owner to add yours as an Android OAuth client
(package `com.goawaygo.app`). Get your SHA-1 with:

```bash
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

(PowerShell. On macOS/Linux use `~/.android/debug.keystore`.) Release builds signed by Google Play need their
own Android client with the SHA-1 from Play Console → _App integrity_.

Google Sign-In needs a device with a Google account and an up-to-date Google Play services: a real phone, or an
emulator built from a **Google Play** system image (the plain "Google APIs" images can't update Play services and
fail with "No credential available").

### 4. Run

Start the backend, connect a phone (USB debugging on) or start an emulator, then forward the backend port so
`localhost:8080` on the device reaches your PC:

```bash
adb reverse tcp:8080 tcp:8080
```

```bash
flutter run
```

`adb reverse` lasts until the device disconnects; run it again after reconnecting.

## Useful commands

```bash
flutter analyze     # Static analysis / lint
flutter test        # Run tests
flutter build apk   # Android release build
```

## Files that are never committed

`.env`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `android/local.properties`, keystores (`*.jks`, `*.keystore`) and `key.properties`. See `.gitignore`.

## Languages and currencies (4.7)

English, Hindi, Spanish, French, German, Arabic (right to left) and Japanese. Text is written in English and
wrapped in `tr('English sentence {0}', [value])` (`lib/core/i18n/i18n.dart`); `assets/i18n/<code>.json` holds the
translations (the same sentences as the website). After adding or changing text, run `python tool/i18n_keys.py`
and add the new sentences to every `assets/i18n/<code>.json`: `test/core/i18n_test.dart` fails while one is missing.

- The language: the traveller's choice (Profile tab), else the phone's, else English. Every API request sends it as
  `Accept-Language`, and a signed-in account follows it (its pushes and emails). Changing it rebuilds the app and
  opens the Profile tab.
- Dates, numbers and prices use the phone's locale for that language (`I18n.locale`).
- Prices: the account's currency, else the traveller's choice (Profile tab), else a guess from the phone's region.
- Text defined once (static or top-level lists) is translated where it is shown, with `tr(label)`; never store a
  translated string in a static field (it would keep the old language).

## Android releases

How to build the Android app for testers and send it to them. Pre-launch, builds go to testers through
**Firebase App Distribution** (free, no Play Store needed); the Play Store comes at launch.

### Supported phones

**Android 8.0 (API 26) or newer**, 32- and 64-bit; iOS 15.0 or newer. The minimum comes from `sentry_flutter` 10
(crash reporting); it is set in `android/app/build.gradle.kts` and the iOS project. Phones on Android 7 can't install
new builds (they keep the version they have).

### Environments

The app reads its settings from a bundled env file (public values only — never secrets):

| Build               | Env file                   | Backend                           |
| ------------------- | -------------------------- | --------------------------------- |
| `flutter run` (dev) | `.env` (local, gitignored) | your PC (`http://localhost:8080`) |
| Release (testers)   | `env/prod.env` (committed) | `https://api.goawaygo.com`        |

Pick the file with `--dart-define=ENV_FILE=...`; without it the app uses `.env`.

### Signing

Release builds are signed with the **upload key**, created once per machine that publishes builds:

```bash
bash scripts/create-upload-key.sh
```

It writes `~/.goawaygo/goawaygo-upload.jks` and `android/key.properties` (gitignored, random password) and prints the
key's SHA-1 / SHA-256 fingerprints (public). **Back up both** (password manager or encrypted drive) and never commit
them. Without them, release builds fall back to the debug key (fine for CI, not for testers).

Google Sign-In on Android checks the signing certificate: the upload key's **SHA-1** must be registered in Google
Cloud (project `goaway-483709`) → Google Auth Platform → Clients → an **Android** client for package
`com.goawaygo.app`. The debug key has its own client for development.

### Push notifications

Push (Firebase Cloud Messaging, 4.5) needs the Firebase Android API key in the build. It identifies the app and ships
inside every APK, but it stays out of git (secret scanning). Once per machine that publishes builds, signed in to
gcloud as a member of `goaway-483709`:

```bash
bash scripts/firebase-key.sh
```

It saves the key to `~/.goawaygo/firebase.env` without showing it; `release-android.sh` passes it with
`--dart-define=FIREBASE_ANDROID_API_KEY`. The other Firebase IDs are public values in `env/prod.env`. Builds without
the key (local runs, CI, tests) work normally without push, and the release script warns.

### Release a build

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

### Send it to beta testers (Firebase App Distribution)

1. Firebase console → project **goaway-483709** → App Distribution.
2. Drag in `build/release/goawaygo-<version>-<build>-universal.apk`, add the release notes.
3. Pick the **beta** group (people who signed up through the website's "Join the beta" invite link) and distribute.
   They get notified and update through the Firebase App Tester app.

### At launch (Play Store)

Build an App Bundle instead (`flutter build appbundle --release --dart-define=ENV_FILE=env/production.env`), enrol
in Play App Signing, and register Play's **app signing** SHA-1 in the Android OAuth client too.

## Releasing

What happens after a merge to `develop`, and how to publish a new Android build. Applies to all three repos
(`goawaygo_backend`, `goawaygo_web_frontend`, `goawaygo_app_frontend`). Setup details: each repo's `docs/`.

### After every merge to `develop`

Every merge whose CI passes becomes a **version** (MVP 2, 5.2): a `vMAJOR.MINOR.PATCH` tag and a GitHub Release
(a pre-release until it reaches production) listing the merged PRs. The PR title decides the number: `feat:` → minor,
`fix:` and everything else → patch, `feat!:` or `BREAKING CHANGE` → major (`.github/scripts/next-version.sh`). Each
repo has its own versions; all three started at `v1.5.0` (MVP 1).

| Part        | You do                                | Happens automatically                                                                                                                                 | Check                                                     |
| ----------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Backend     | Nothing                               | CI tests → version → image built once (tagged with the version) → deployed to **dev** (`api-dev.goawaygo.com`) → smoke test; Flyway migrates (~6 min) | GitHub → goawaygo_backend → Actions → **Release** ✅      |
| Website     | Nothing                               | CI → version → website built once, attached to the release, deployed to **dev** (`dev.goawaygo.com`) (**Release**)                                    | GitHub → goawaygo_web_frontend → Actions → **Release** ✅ |
| Android app | Release it (below) when worth testing | CI → version (**Release**). The APK is signed with the upload key that exists only on the release PC                                                  | `https://goawaygo.com/download` shows the new version     |

The app doesn't need a release after every merge: release at the end of a feature or when testers should try
something.

### Release a new Android build (~10 min)

Git Bash, one command per line:

```bash
cd /c/Users/priyesh/OneDrive/Desktop/Dev/Goaway/app_frontend
git switch develop
git pull
export PATH="$PATH:/c/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin"
bash scripts/release-android.sh 1.0.0 <next-build> "What changed in this version" --upload
```

- `<next-build>`: the last build number + 1. **It must always go up**, or phones refuse the update.
- Ends with `Live: https://goawaygo.com/download`. If it asks for Cloudflare, run
  `npx --yes wrangler@4.145.0 login` once and repeat.
- It refuses to run without the upload key (`android/key.properties`), so nothing debug-signed is ever published.
- Push notifications need the Firebase key on this PC: run `bash scripts/firebase-key.sh` once (gcloud signed in).
  Without it the script warns and that build has no push.
- Fails with `cannot find symbol ... Plugin` in `GeneratedPluginRegistrant.java` (usually after a dependency
  update): an old partial build of that plugin is left on this PC. Run `flutter clean` and run the command again.

Then send it to the beta testers:

1. Firebase console → project **goaway-483709** → **App Distribution**.
2. Drag in `app_frontend/build/release/goawaygo-<version>-<build>-universal.apk`, paste the same notes.
3. Testers → group **public-beta** → **Distribute**.

Check `https://goawaygo.com/download`, then install it on a phone over the previous build.

#### Version numbers

| Change          | Example                    |
| --------------- | -------------------------- |
| Every release   | build number +1, always    |
| Fixes           | keep the version (`1.0.0`) |
| New feature set | `1.1.0`                    |
| Big milestone   | `2.0.0`                    |

### Occasionally

| Situation                         | What to do                                                                                                                                                                        |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| New backend secret (API key etc.) | Stored with a hidden-input script into Google Secret Manager (`backend/scripts/gcp-secrets.sh`)                                                                                   |
| New website setting               | A change to `src/lib/env.ts` (one build serves every environment), merged like any other change                                                                                   |
| Database change                   | Nothing: Flyway migrates on deploy. Keep migrations additive so a rollback still works.                                                                                           |
| Broken in test or prod            | Roll back with **Controller** → Run workflow (above). Instant backend switch: `gcloud run services update-traffic <service> --region asia-southeast1 --to-revisions REVISION=100` |
| Website broken in prod (urgent)   | Cloudflare → goawaygo-web-prod → Deployments → earlier deployment → **Rollback**; then the Controller as above                                                                    |
| Bad app build                     | Release a fixed build with a higher build number; delete the bad files from R2 and purge their URLs in Cloudflare cache                                                           |

### Moving a version up: test, then prod (`controller.yaml`, MVP 2, 5.4)

dev gets every version automatically. test and prod get a version only through **Controller**
(`.github/workflows/controller.yaml` in each repo), with your approval twice: once for the merge, once for the deploy.

1. **To test:** a PR from `develop` into `test` (opened by the bot). You approve it; it's merged with a merge commit.
2. Controller starts on `test`. It picks the version whose files are exactly what `test` now holds, checks that the
   version passed dev (its GitHub Release shows **✅** for the dev deployment, **AT dev** and **PT dev**), then waits
   for you: Actions → **Controller** → the
   run → **Review deployments** → tick **test** → **Approve and deploy**.
3. The backend and website deploy that version's image and build to test (`api-test.goawaygo.com`,
   `test.goawaygo.com`) and check them. The app has nothing to deploy: the version is recorded as promoted.
4. The automation (AT) and performance (PT) tests run on test right after the deploy and write their result into the
   release; then test it yourself on test.
5. **To prod:** a PR from `test` into `main`, approved and merged the same way; Controller checks the version passed
   test (deployment, AT and PT), waits for your approval (**prod**), deploys, and makes the version the **latest full release** (no longer a
   pre-release). For the app, build the APK from that version (below).

Each step is written into the version's GitHub Release under **Deployments**, e.g.
`- **test**: ✅ deployed 2026-11-12 09:30 UTC · run`, so every release shows where it has run. If a version isn't
ready (Release on `develop` still running, or it failed below), Controller stops with the reason; fix it and re-run.

### Automated and performance tests (AT, PT; MVP 2, 5.5 and 5.6)

The tests live in their own repos, with the same branches and rules: **goawaygo_automation_tests** (API and website
with Playwright, the Android app with Maestro on an emulator) and **goawaygo_performance_tests** (API and website with
k6, the app's start-up time and scrolling). Each environment runs the tests from its own branch (dev: `develop`,
test: `test`, prod: `main`), so a test change is promoted like code.

| When                          | What runs                                                                    | Evidence                                    |
| ----------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------- |
| A pull request into `develop` | **Tests before merge**: the smoke tests against dev (app: built from the PR) | the report on the PR (not a required check) |
| After every deploy to dev     | **Release → Tests on dev**: all AT, and PT with limits that fail the run     | `AT dev` / `PT dev` ✅ or ❌ in the release |
| After a deploy to test        | **Controller → Tests on test**: the same                                     | `AT test` / `PT test` in the release        |
| After a deploy to prod        | **Controller → Tests on prod**: read-only smoke tests, never PT              | `AT prod` in the release                    |

A version goes to test only with ✅ for AT and PT in dev, and to prod only with ✅ for both in test. Every run keeps
its reports for 90 days: the run's page → **Artifacts** (Playwright HTML report, k6 HTML report, app screenshots and
timings). In dev and test the tests use the backend's fake outside services (no AI or partner quota is used) and skip
its rate limits; prod has neither. A failed run: open the report, fix the code or the test, and re-run (Actions →
the run → **Re-run failed jobs**); the release then shows the new result.

**Roll back or deploy again:** Actions → **Controller** → **Run workflow** → "Use workflow from" **main** (prod) or
**test** (test) → version, e.g. `v1.7.0` (empty = the branch's own version) → approve. Only a version that is merged
into that branch and passed the environment below can be deployed. Keep database migrations additive so an older
version still runs.

## How we work

These rules apply to all GoAwayGo repositories:
[app](https://github.com/goawaygoofficial/goawaygo_app_frontend) ·
[web](https://github.com/goawaygoofficial/goawaygo_web_frontend) ·
[backend](https://github.com/goawaygoofficial/goawaygo_backend).

### First-time setup

```bash
git clone <repo-url>
cd <repo>
git config core.hooksPath .githooks   # enable the shared git hooks (once per clone)
```

The hooks:

- **pre-commit** scans staged changes for secrets with [Gitleaks](https://github.com/gitleaks/gitleaks).
  Install it once: `winget install Gitleaks.Gitleaks` (Windows) or `brew install gitleaks` (macOS).
  Without it, the hook skips with a warning, and CI still scans.
- **pre-push** blocks pushing directly to `develop`, `test` or `main`, and branch names other than `feature/...`
  and `fix/...`.

Never bypass hooks with `--no-verify`.

### Branches

Every change takes the same path: `feature/...` or `fix/...` → `develop` → `test` → `main`.

| Branch              | Is for            | Deploys to        | Merges into                                 |
| ------------------- | ----------------- | ----------------- | ------------------------------------------- |
| `feature/<name>`    | A new feature     | Nowhere (CI only) | `develop`: squash merge, no approval needed |
| `fix/<name>`        | A bug fix         | Nowhere (CI only) | `develop`: squash merge, no approval needed |
| `develop` (default) | Development       | Dev environment   | `test`: merge commit, the owner approves    |
| `test`              | Testing a version | Test environment  | `main`: merge commit, the owner approves    |
| `main`              | Customers         | Production        | —                                           |

- Branch from the latest `develop`: `git switch develop && git pull && git switch -c feature/short-name`.
  Names: lowercase letters, digits, `.`, `_` and `-` after the prefix.
- GitHub rejects new branches with any other name (Dependabot's `dependabot/...` is the exception), direct pushes
  to `develop`, `test` and `main`, force pushes and deleting them.
- Keep branches short-lived (days, not weeks) and focused on one thing.

### Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Google sign-in button
fix: stop crash when profile picture is missing
docs: explain how to run the backend locally
chore(deps): bump http to 1.6.0
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `ci`, `build`.
The squash-merged PR title sets the next version: `feat` → minor, everything else → patch, `!` after the type
(`feat!:`) or a `BREAKING CHANGE:` line → major.
Write the subject in the imperative ("add", not "added"), lower case, no trailing period.

### Pull requests

1. Run this repo's checks locally (see **This repository** below). They must pass.
2. Push your branch and open a PR into `develop`. Fill in the template.
3. The required checks must be green ✅: **CI**, **Secret scan**, **Dependency scan** and **Branch guard**
   (the PR is on an allowed path).
4. **Squash merge** into `develop`. The PR title becomes the commit message, so it must follow Conventional Commits.
5. To move changes up: a PR **`develop` → `test`**, then **`test` → `main`**. Each needs the owner's approval
   (`goawaygoofficial`, the code owner) and is merged with a **merge commit**, never squash, so the branches keep
   the same history.

Rules:

- **Never merge a PR with a failing (❌) or pending check.**
- Every bug fix or feature includes tests, or the PR explains why not.
- No secrets in code. Config goes in `.env` / environment variables, with placeholders in `.env.example`.
- UI changes include before/after screenshots.

These rules are enforced by GitHub repository rulesets (the repos are public, so they are free) and the
**Branch guard** workflow.

### Bug fixes

A bug fix is a `fix/<name>` branch and follows the same path as everything else: `develop` → `test` → `main`.
There are no hotfix branches.

### Dependencies

Dependabot opens update PRs into `develop` every Monday. Minor and patch updates are grouped into one PR.
Review them like any other PR: CI must pass, and read the changelog for major updates.

### Security

- Never commit `.env`, keys, keystores, service-account files or passwords. `.gitignore` covers the usual ones.
- If a secret is committed, even on a branch, **rotate it immediately**. Deleting the commit is not enough.
  The repos are public: anything pushed can be read and copied at once.
- Report security issues privately to the repo owner, not in a public issue.

### This repository: App (Flutter)

```bash
flutter pub get
cp .env.example .env          # Google client IDs are pre-filled; check BASE_URL
flutter run
```

Checks to run before every PR (the same ones CI runs):

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Format code with `dart format lib test`. CI uses Flutter **3.47.7** (see `.github/workflows/ci.yml`).
Update it there when upgrading Flutter locally.

### Pull request description

Every pull request description follows this outline:

```markdown
## What

<!-- What does this PR change? Keep it short. -->

## Why

<!-- The problem it solves or the feature it adds. Link the issue if there is one: Closes #123 -->

## How tested

<!-- Commands you ran, screens you checked, devices/browsers. -->

- [ ] Checks pass locally (see **How we work** (README) for this repo's command)
- [ ] Added or updated tests for the change (or explained below why not)

## Screenshots

<!-- For UI changes: before / after. Delete this section if not relevant. -->

## Checklist

- [ ] PR targets `develop` (or `main` only for a release / hotfix)
- [ ] Title follows Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`)
- [ ] No secrets, keys or `.env` files committed
- [ ] `README.md`, `LINKS.md`, `RELEASES.md` and `.env.example` updated if behaviour, config or links changed
```

## Conventions and decisions

GoAwayGo is three product repos (plus the automation and performance test repos), cloned side by side in one folder (`Dev/Goaway` on the owner's PC):

| Folder          | Stack                                                                                                                        | GitHub repo (public)                     |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `app_frontend/` | Flutter 3.47 (Dart ^3.13), provider, http, google_sign_in, flutter_secure_storage, Sentry, PostHog                           | `goawaygoofficial/goawaygo_app_frontend` |
| `web_frontend/` | React 19, TypeScript (strict), Vite 8, react-router-dom 7, CSS Modules — web version of the app, mirrors it screen by screen | `goawaygoofficial/goawaygo_web_frontend` |
| `backend/`      | Spring Boot 4.1, Java 17, Maven (`mvnw`), PostgreSQL 17 (Docker Compose locally, Testcontainers in tests), Flyway, Sentry    | `goawaygoofficial/goawaygo_backend`      |

The parent folder is not a git repo: run git and gh inside each repo folder.

### GitHub

- Account: `goawaygoofficial` (not the global git identity on this PC — don't use that here).
- Each repo has local git config `user.name=goawaygoofficial` and GitHub's private no-reply `user.email` (the repos are public, decided 2026-11-11: the team email stays out of commits).
- `gh` CLI is logged in as `goawaygoofficial` with ADMIN on all repos.
- Default branch: `develop`.

### Branching (all repos)

Path for every change (MVP 2, decided 2026-11-11): `feature/<name>` or `fix/<name>` → `develop` → `test` → `main`.

| Branch               | Environment | Rules                                                                                        |
| -------------------- | ----------- | -------------------------------------------------------------------------------------------- |
| `feature/*`, `fix/*` | CI only     | Branch from latest `develop`; PR into `develop`; no other branch names (GitHub rejects them) |
| `develop` (default)  | Dev         | Squash-merge PRs from `feature/*`/`fix/*`/`dependabot/*`; no approval needed                 |
| `test`               | Test        | Only a PR from `develop`, approved by `goawaygoofficial`, merged with a **merge commit**     |
| `main`               | Production  | Only a PR from `test`, approved by `goawaygoofficial`, merged with a **merge commit**        |

- PRs are opened and merged by the bot account `goawaygo-bot` (`gh` is signed in as it; these repos push through
  `gh`). The user approves PRs into `test` and `main` as `goawaygoofficial` (CODEOWNERS); a PR author can't approve
  their own PR.
- No Claude attribution: no `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line, and always an
  explicit `commit_message` when squash-merging (otherwise GitHub copies old trailers into the commit).
- Merge via the API, `develop`:
  `gh api -X PUT repos/goawaygoofficial/<repo>/pulls/<n>/merge -f merge_method=squash -f sha=<head> -f commit_title="<PR title> (#<n>)" -f commit_message="<summary>"`;
  `test` and `main`: the same with `merge_method=merge`.
- A merge into `test` or `main` starts **Controller** (`.github/workflows/controller.yaml`, 5.4): it deploys the
  version whose files match the branch to test or prod, only if that version passed the environment below (its
  GitHub Release "Deployments" section shows ✅), after the owner approves the deploy. Rollback: run Controller by
  hand on `test` or `main` with a version (**Releasing** (README)).
- Tests as evidence (5.5, 5.6): `tests.yml` in each product repo runs the automation tests (repo
  `goawaygo_automation_tests`: Playwright API + website, Maestro app) and performance tests (`goawaygo_performance_tests`:
  k6 API + website, app start-up and scrolling) from the branch matching the environment, after every deploy (Release,
  Controller) and as smoke tests on pull requests (`tests-before.yml`). Results go into the release ("AT dev ✅",
  "PT dev ✅"); Controller needs both from the environment below. dev and test answer test runs (header
  `X-GoAwayGo-Test`, secret `TEST_FAKES_TOKEN`) with fake outside services and no rate limits; prod never.
- Enforced by GitHub repository rulesets (free on public repos): branch names, no direct or force pushes, no
  deleting `develop`/`test`/`main`, required checks, the owner's approval into `test` and `main`. The
  **Branch guard** check fails a PR on any other path; the `pre-push` hook gives the same answers locally.

### Workflow rules

- Per task: branch → code + tests → run checks locally → commit → push → open PR to `develop` → stop for the user's review.
- Show the changes and get the user's OK before any PR merge, release, or deploy.
- Never merge with failing or pending checks (`gh pr checks <n>`), even if asked — fix them first.
- Never bypass git hooks (`--no-verify`). Hooks live in `.githooks/`; enable per clone with `git config core.hooksPath .githooks`.
- **Conventions and decisions** (README) exists in this folder and as a copy in each repo — keep all copies in sync.

### CI (GitHub Actions, every repo)

- `CI` — app: dart format check, `flutter analyze`, `flutter test`, debug APK build · web: `npm run check` · backend: `./mvnw verify`
- `Secret scan` — Gitleaks over full history
- `Branch guard` — on every PR: only allowed merge paths (required check)
- Dependabot: weekly grouped update PRs into `develop` (deps + GitHub Actions)
- Free plan = 2,000 Actions minutes/month; avoid needless re-runs.

### Secrets — never commit

- App frontend: `.env` (bundled as a Flutter asset — public config only: `BASE_URL`, `WEBSITE_URL`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `SENTRY_DSN`, `POSTHOG_KEY`; keep `.env.example` in sync), `android/app/google-services.json` (if Firebase is ever added), `android/local.properties`, keystores, `key.properties`.
- Web frontend: `.env` / `.env.*` (`VITE_*` values end up in the JS bundle — public config only; keep `.env.example` in sync).
- Backend: `backend/.env` (gitignored; template `.env.example`) holds local DB passwords and is read by both Docker Compose and Spring Boot (`spring.config.import`). Deployed environments use env vars. Never put secrets in `application.properties`. Never print `.env` values in chat.

### Commands

- App frontend: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`
- Web frontend (Node 22.12+, `.nvmrc` = 24): `npm install`, `npm run dev`, `npm run check` (typecheck + lint + format check + build — run before every PR)
- Backend (JDK 17+, Docker Desktop): `docker compose up -d` (PostgreSQL 17 on 127.0.0.1:5433), `./mvnw spring-boot:run`, `./mvnw verify` (tests start their own PostgreSQL via Testcontainers)
- App CI pins Flutter 3.47.7 (matches local); update `.github/workflows/ci.yml` when upgrading.

### Database (backend)

- Roles: `postgres` (container superuser, setup only) · `goawaygo_owner` (owns schema; Flyway only) · `goawaygo_app` (runtime; SELECT/INSERT/UPDATE/DELETE, no DDL). Created by `docker/postgres/init/01-create-roles.sh`, reused by tests; `DatabaseSetupTests` verifies it.
- Schema changes only via new Flyway migrations `src/main/resources/db/migration/V<n>__<desc>.sql`; never edit a merged migration.
- Backend runs in UTC (`BackendApplication.main` + surefire `-Duser.timezone=UTC`): Windows reports the legacy zone `Asia/Calcutta`, which PostgreSQL 17 (Debian 13 image) rejects.
- Keep the `postgres:` image tag in `compose.yaml` and `PostgresIntegrationTest` in sync.

### Authentication (decided: short JWT + rotating refresh token)

- Access token: ES256 JWT, **20 min**, `Authorization: Bearer`; not stored. Keys: `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` (base64 DER) in `backend/.env`; each environment has its own pair; never print or commit them.
- Refresh token: random, **30 days**, stored only as SHA-256 in `refresh_tokens`; rotated on every use; reuse of a rotated token revokes the whole family.
- Mobile sends `X-Client-Type: mobile` → refresh token in JSON body (store in Keychain/Keystore). Web → refresh token only in `HttpOnly; Secure; SameSite=Strict` cookie `goawaygo_refresh` on `/api/auth`; keep access token in memory, never `localStorage`.
- Profile: `GET /api/users/me` (own profile only). There is no `GET /api/auth/users/{id}`: the old frontend code that calls it must be replaced.
- Errors: always `{status, error, message[, fieldErrors]}`; clients branch on `error`.
- Never trust identity from the client; derive the user from the access token (`jwt.getSubject()`).
- Password reset / email verification: single-use emailed links (`user_action_tokens`, SHA-256 hashes; reset 30 min, verify 24 h) opening the website (`/reset-password`, `/verify-email`). Forgot-password must not reveal whether an account exists (same 202 body; email sent after commit in the background). Never accept `{email, newPassword}`.
- Email: SMTP only (`EmailSender`/`EmailOutbox`). Local: Mailpit from `docker compose` (inbox http://localhost:8025). Deployed: Resend over SMTP (`MAIL_*` env vars; the API key is a secret). Never log email bodies (they contain one-time links).
- Rate limits (Bucket4j, in-memory per instance): per IP on public `/api/auth/*`, per email on signin/forgot-password; 429 + `Retry-After`. Tests disable it in `PostgresIntegrationTest`.

### Google Sign-In

- App ID (Android `applicationId`/`namespace`, iOS/macOS bundle ID): **`com.goawaygo.app`**. Permanent once on Google Play.
- App minimum OS: **Android 8.0** (API 26, `minSdk = 26` in `android/app/build.gradle.kts`), **iOS 15.0**, macOS 12.0, required by `sentry_flutter` 10. Don't lower them.
- Google Cloud project `goaway-483709` (number `1018541563002`), consent screen in **Testing** (only listed test users can sign in). OAuth clients (IDs are public; never handle client secrets):
  - Web `1018541563002-sft2jld5f3n6lnenvt0pk8hknk7hfq9n.apps.googleusercontent.com`: website, and the ID-token audience (`serverClientId`) for the mobile app. Origins: `http://localhost:5173`, `http://localhost`.
  - Android `1018541563002-s8eo8sn5e7dt9kaav6rm0mhgea6tgir9.apps.googleusercontent.com`: package + the user's debug SHA-1 `79:E2:F5:3A:AD:5E:E7:84:08:30:CE:07:1C:9A:F0:EC:FB:90:2F:C8`. Release / Play App Signing SHA-1 needs its own Android client later.
  - iOS `1018541563002-ss0dur7e8d4l9c2lb2o89edgouqrd2fv.apps.googleusercontent.com`
- Backend must verify Google ID tokens (signature via Google JWKs, `iss`, `exp`, `aud` ∈ configured client IDs, `email_verified`) and never trust user details sent alongside them.
- Mobile sends the ID token to `/api/auth/google-signin`. The website uses its own styled button + Google code client (popup) and sends the one-time code to `/api/auth/google-signin/code`; the backend exchanges it with `GOOGLE_CLIENT_SECRET` (backend `.env` only, entered by the user; never ask for it in chat, never print it).

### Discover, Wanderbook, Book, the trip planner, notifications and Me (4.1-4.6)

- **How we build:** MVP rounds. MVP 1 builds every Phase 4 sub-phase; fixes, changes and new ideas go into later MVPs (see **Roadmap** (README)).
- Outside services go through the backend's API toolkit (`com.goawaygo.backend.external`) with daily limits below free tiers: Gemini (destination cards, trip ideas), Geoapify (places, photo location → place name), Wikimedia and Unsplash (photos), OpenAI moderation (Wanderbook), Travelpayouts (Book: Aviasales prices, affiliate links). Keys: Secret Manager `goawaygo-api-<name>` + repo variable `EXTERNAL_API_PROVIDERS`. Never store Discover's AI answers or spot photos (asked fresh on every page open); a trip plan is the user's own content once saved (`trip_plans`).
- Wanderbook photos: originals (never resized), only location data removed by the backend; exact coordinates never stored. Stored in R2 `goawaygo-media` (`media.goawaygo.com`), key via `scripts/gcp-secrets.sh <project> r2` + repo variable `WANDERBOOK_PHOTOS=true`. Uploads stop at 9.5 GB.
- Moderation fails closed: if OpenAI can't check, nothing is posted. Reports email `team@goawaygo.com`; admins (`users.is_admin`, set by hand in Neon) review on the website's `/admin/reports`.
- Viewing Wanderbook is public (rate limited per IP); profiles/posts use random 12-character public ids, never user ids.
- Trip planner: Gemini (Lite models first) writes a day-by-day plan with rough costs (whole group, flights never included); signed-in users only, saved in My Trips, one day can be rewritten, a plan can be shared read-only by link after an OpenAI moderation check.
- Notifications: saved for the bell (90 days) on the app and website; pushed to Android through Firebase Cloud Messaging with the backend's own service account (no key); a switch per type; trip reminders run from a daily GitHub Actions call. The app's Firebase IDs are public values in `env/staging.env` (never commit `google-services.json`).
- Languages (4.7): en, hi, es, fr, de, ar (RTL), ja. Backend text the user sees goes through `T.t(lang, "English sentence {0}", args)` with translations in `src/main/resources/i18n/<code>.json` (the English sentence is the key; `LanguageTests` checks every file has the same keys and placeholders). New user-facing backend text needs all six translations. Requests carry `Accept-Language`; `users.language` is for pushes and emails. Legal pages stay English.
- Me: the account name and photo are also the Wanderbook name and photo. Changing the password or email and deleting the account first confirm it's you (password, or Google without one). Deleting hides the account for 30 days (signing in keeps it), then the daily GitHub Actions job deletes its R2 files and the account (every table cascades); queries that show people to others must skip `users.deletion_requested_at IS NOT NULL`. Phone sign-in waits for MVP 2 (SMS costs money).
- Book: affiliate model, travellers book and pay on the partner's site. Flights show Aviasales' recent prices (labelled "may change"); stays and cars are partner links. Every partner page becomes our tracked link via Travelpayouts (`goawaygo.book.*`); the app only shows brands that allow apps. Never load partner scripts (e.g. Travelpayouts Drive) on our site.

### Deployment

Domain `goawaygo.com` (Cloudflare Registrar + DNS). Website and API must stay on the same registrable domain (the refresh cookie is `SameSite=Strict`).

- Pre-launch (alpha/beta, all free): backend on Google Cloud Run `asia-southeast1` (prod: project `goawaygo-prod`, service `goawaygo-backend`, `api.goawaygo.com`; dev and test: project `goawaygo-staging`); database Neon PostgreSQL 17 (AWS Singapore); website on Cloudflare Pages (prod `goawaygo.com` since 2026-11-13 with `www` redirecting to it, dev `dev.goawaygo.com`, test `test.goawaygo.com`; no other addresses); email Resend; Android testers via Firebase App Distribution.
- Naming (MVP 2): **staging** = non-production (dev, test), **prod** = production. Neon projects `goawaygo-staging` (`goawaygo_dev`, `goawaygo_test`) and `goawaygo-prod` (`goawaygo`); Google Cloud projects `goawaygo-staging` (dev, test, the shared image registry) and `goawaygo-prod` (production, since 2026-11-12). A shared key (Google, Resend, R2, outside APIs) is changed in both projects.
- At launch (Phase 5): database moves to Google Cloud SQL; Play Console then. Company not registered yet.
- Backend: every version deploys to dev automatically after CI passes on `develop` (`.github/workflows/release.yml` → `deploy.yml`, keyless Workload Identity Federation); test and prod get the same image through `controller.yaml` (5.4). Environments: the backend README (**Deployment**). Secrets live only in Google Secret Manager; setup scripts and steps in the backend README (**Deployment**).
- Cloud Run: min 0 instances (cold start ~7–10 s after idle), max 1 (in-memory rate limits), request-based billing (CPU only during requests; emails sent inside the request). Health: `GET /actuator/health` (no DB check, so Neon can sleep).
- Google free trial ends 90 days after sign-up: upgrade billing before then or the project stops.
- After a merge: backend and website deploy themselves; Android builds are released by hand with `app_frontend/scripts/release-android.sh` (upload key on the release PC only). Step by step: **Releasing** (README) (copy in every repo). What's next: **Roadmap** (README) (copy in every repo; tick items as they ship).
- Shared docs, identical in the workspace root and every repo (edit the root copy, then copy it into the three repos with their `<!-- Copy of ... -->` header): **Conventions and decisions** (README), **Releasing** (README), **Roadmap** (README), **Resources and outside services** (README) (what each service is for) `LINKS.md` (dashboards, routine, onboarding) and **History** (README) (the goawaygo.com launch checklist, 5.7).

## Resources and outside services

Every service, library and tool GoAwayGo uses, what it does for us, and which part uses it: **B** = backend,
**W** = website, **A** = Android app. All on free tiers until launch. Links: `LINKS.md`.

### At a glance

```
 Users ──► goawaygo.com (W, Cloudflare Pages) ──────────┐
       └─► GoAwayGo app (A, APK from downloads.goawaygo.com / Firebase) ──┤
                                                          ▼
                              api.goawaygo.com (B, Google Cloud Run) ──► Neon Postgres (database)
                                     │          │            │
                                Resend (email)  Secret Manager   outside APIs (via the API toolkit):
                                                                 Gemini, Geoapify, Wikimedia, Unsplash, OpenAI
                                     │
                                     └──► Cloudflare R2 goawaygo-media ──► media.goawaygo.com (Wanderbook photos)

 Watching it: Sentry (errors) · Cloud Logging (logs) · Better Stack (uptime + status page)
              Cloudflare Web Analytics (traffic) · PostHog (product analytics, with consent)
 Guarding it: GitHub Actions CI · Gitleaks (secrets) · OSV-Scanner (vulnerable dependencies) · Dependabot
```

### 1. Running the product

| Resource                                                    | What it does for us                                                                                                                | Used by              | Free limit / cost                                                                   | Set up in                                                            |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Google Cloud Run** (`goawaygo-backend`, Singapore)        | Runs the backend container; serves `api.goawaygo.com`. Scales to 0 when idle, max 1 instance; billed only while handling requests. | B                    | 180k vCPU-s, 360k GiB-s, 2M requests/month free; $300 trial credit until 2027-01-14 | `backend/.github/workflows/deploy.yml`, **Deployment** (README)      |
| **Neon Postgres 17** (AWS Singapore)                        | The database: users, sessions, email links, API cache, searches, saved places, Wanderbook. Sleeps when idle.                       | B                    | 0.5–1 GB storage, 100 compute-hours/month                                           | `backend/scripts/setup-hosted-db.sh`; tables in `db/migration`       |
| **Flyway**                                                  | Creates and updates database tables on every deploy (V1–V7), as the owner role; the app uses a limited role.                       | B                    | open source                                                                         | `backend/src/main/resources/db/migration`                            |
| **Cloudflare Pages** (`goawaygo-web-dev`, `-test`, `-prod`) | Hosts the website: one project per environment, uploaded by GitHub Actions (one build per version).                                | W                    | unlimited static requests, 500 builds/month                                         | Cloudflare dashboard; the website README (**Deployment**)            |
| **Cloudflare R2** (`goawaygo-downloads`)                    | Stores the Android APKs and `latest.json` behind `downloads.goawaygo.com`.                                                         | A, W (download page) | 10 GB, no download fees                                                             | `app_frontend/scripts/release-android.sh`                            |
| **Firebase App Distribution** (project `goaway-483709`)     | Sends beta builds to testers; public sign-up link.                                                                                 | A                    | free                                                                                | the app README (**Android releases**)                                |
| **Cloudflare DNS + Registrar** (`goawaygo.com`)             | The domain and all its records (web, api, downloads, status, email).                                                               | B, W, A              | at-cost domain renewal (yearly)                                                     | Cloudflare dashboard                                                 |
| **Resend**                                                  | Sends account emails (verify email, reset password) as `no-reply@goawaygo.com`.                                                    | B                    | 3,000 emails/month, 100/day                                                         | Secret `goawaygo-resend-api-key`, repo variable `MAIL_FROM`          |
| **Google Sign-In** (OAuth clients in `goaway-483709`)       | "Continue with Google" on the website and in the app.                                                                              | B, W, A              | free                                                                                | Repo variables + `goawaygo-google-client-secret`; app `env/prod.env` |

### 2. Keeping it secure

| Resource                                             | What it does for us                                                                                                                                      | Used by     | Set up in                                                   |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------- |
| **Google Secret Manager**                            | Holds every secret (DB passwords, JWT keys, Google client secret, Resend key, future API keys); the backend reads them at start. GitHub never sees them. | B           | `backend/scripts/gcp-secrets.sh`                            |
| **Workload Identity Federation**                     | GitHub Actions deploys to Google Cloud without any stored key.                                                                                           | B (deploys) | `backend/scripts/gcp-bootstrap.sh`                          |
| **Android upload key** (`~/.goawaygo`, this PC only) | Signs every APK so phones accept updates; its SHA-1 lets Google Sign-In trust the app. Back it up; never share it.                                       | A           | `app_frontend/scripts/create-upload-key.sh`                 |
| **Gitleaks** (pre-commit hook + CI)                  | Blocks commits and PRs that contain passwords or keys. `.gitleaks.toml` allows only the public PostHog key.                                              | B, W, A     | `.githooks/pre-commit`, `.github/workflows/secret-scan.yml` |
| **OSV-Scanner** (CI, also every Monday)              | Checks every dependency against known vulnerabilities (osv.dev); a finding fails the check.                                                              | B, W, A     | `.github/workflows/dependency-scan.yml`                     |
| **Dependabot**                                       | Weekly PRs that update libraries (grouped minor/patch; majors separate).                                                                                 | B, W, A     | `.github/dependabot.yml`                                    |
| **Rate limits** (Bucket4j, in memory)                | Limits repeated sign-in, sign-up and refresh attempts per IP and per email.                                                                              | B           | `goawaygo.rate-limit.*` in `application.properties`         |
| **Security headers**                                 | Stops the website being framed by other sites, limits referrers, turns off unused browser features.                                                      | W           | `web_frontend/public/_headers`                              |

### 3. Knowing when something breaks (Foundations 4.0a–4.0b)

| Resource                                                                                 | What it does for us                                                                                                                                 | Used by | Free limit                 | Set up in                                                                                                            |
| ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Sentry** (EU, org `goawaygo`; projects goawaygo-backend / goawaygo-web / goawaygo-app) | Catches crashes and errors with the release and environment; emails us; no personal data (scrubbers on, IPs not stored, tokens cut from URLs).      | B, W, A | 5k errors/month            | `SENTRY_DSN` (backend var), `web_frontend/src/lib/monitoring.ts`, `app_frontend/lib/core/monitoring/monitoring.dart` |
| **Google Cloud Logging + Error Reporting**                                               | Backend logs as structured JSON (severity, request ID, trace), kept 30 days; groups backend exceptions.                                             | B       | 50 GiB/month               | `logging/CloudLoggingFormatter.java`, `RequestIdFilter.java`                                                         |
| **Request IDs** (`X-Request-Id`)                                                         | One ID per API request in the response, every log line and Sentry — to follow one request end to end.                                               | B       | —                          | `logging/RequestIdFilter.java`                                                                                       |
| **Health endpoint** `/actuator/health`                                                   | "Is the backend running?" for uptime checks; never touches the database (so Neon can sleep).                                                        | B       | —                          | `application.properties` (management.*)                                                                              |
| **Better Stack**                                                                         | Checks the API and website every 3 min and `latest.json` every 30 min from 4 regions; emails on downtime; public status page `status.goawaygo.com`. | B, W, A | 10 monitors, 1 status page | Better Stack dashboard                                                                                               |

### 4. Understanding usage (Foundation 4.0d)

| Resource                               | What it does for us                                                                                                                                                                                                                                                                               | Used by | Free limit      | Set up in                                                                             |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | --------------- | ------------------------------------------------------------------------------------- |
| **Cloudflare Web Analytics**           | Page views and visitors for the website; no cookies, no consent needed.                                                                                                                                                                                                                           | W       | free            | Cloudflare Pages → Web Analytics (automatic)                                          |
| **PostHog** (EU, project 315148)       | Product analytics — only after the user taps "Allow": page views and 6 events (sign-up, sign-in, travel category, destination search, app download, beta join), anonymous. **Feature flags** are available here but switched off until we first need one (a one-line change each in web and app). | W, A    | 1M events/month | `web_frontend/src/lib/analytics.ts`, `app_frontend/lib/core/analytics/analytics.dart` |
| **Consent banner / "Privacy choices"** | Asks once (equal "No thanks" / "Allow"); the choice can be changed any time; "No thanks" deletes PostHog's ID.                                                                                                                                                                                    | W, A    | —               | `ConsentBanner.tsx`, `analytics_consent_sheet.dart`                                   |

### 5. Legal and contact (Foundation 4.0c)

| Resource                                         | What it does for us                                                                                                                                                                                  | Used by | Set up in                                             |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ----------------------------------------------------- |
| **Privacy Policy, Terms of Use, Delete my data** | International (GDPR, US state laws, India DPDP, Brazil LGPD); linked from footers, sign-up and the app. Delete-my-data is also Google Play's required deletion URL. **Lawyer review before launch.** | W, A    | `web_frontend/src/features/legal`, `src/lib/legal.ts` |
| **Cloudflare Email Routing**                     | `privacy@` and `support@goawaygo.com` forward to the team Gmail (free; receive only).                                                                                                                | all     | Cloudflare → Email Routing                            |

### 6. Calling outside services safely (Foundation 4.0e)

| Resource                                          | What it does for us                                                                                                                                                                                                   | Used by | Set up in                                |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------------------------------- |
| **API toolkit** (`com.goawaygo.backend.external`) | The one way the backend calls outside APIs (places, photos, prices, AI from 4.1): timeouts, retries for temporary failures, circuit breaker, daily/monthly limits **below free tiers**, database cache with fallback. | B       | **Deployment** (README) → "Outside APIs" |
| **Resilience4j**                                  | The retry and circuit-breaker engine inside the toolkit.                                                                                                                                                              | B       | `pom.xml`                                |
| **Usage counters** (`external_api_usage`)         | Calls per provider per day/month; refuses calls at the limit, so no surprise bills.                                                                                                                                   | B       | Flyway V4                                |
| **API cache** (`external_api_cache`)              | Reuses answers instead of spending quota; serves the last answer if a provider is down.                                                                                                                               | B       | Flyway V4                                |

### 7. Building and shipping

| Resource                                                        | What it does for us                                                                               | Used by |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------- |
| **GitHub** (org `goawaygoofficial`, private repos)              | Code, PRs, reviews; `develop` → dev, `test` → test, `main` → prod.                                | B, W, A |
| **GitHub Actions**                                              | CI on every PR (build, tests, lint, format), secret and dependency scans, and the backend deploy. | B, W, A |
| **Docker + Artifact Registry** (`goawaygo` repo, newest 3 kept) | Packages the backend and stores the images Cloud Run runs.                                        | B       |
| **Wrangler** (Cloudflare CLI, logged in on this PC)             | Uploads APKs and `latest.json` to R2 during an Android release.                                   | A       |
| **Testcontainers + Docker**                                     | Real Postgres in backend tests.                                                                   | B       |

### 8. Main frameworks and libraries

| Part    | Main pieces                                                                                                                                                  |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Backend | Java 17, Spring Boot 4.1 (web, security, JPA, validation, mail, actuator), Flyway, PostgreSQL driver, JWT (ES256), Bucket4j + Caffeine, Resilience4j, Sentry |
| Website | React 19, TypeScript, Vite, React Router, Sentry, PostHog (loaded only after consent), Roboto (bundled)                                                      |
| App     | Flutter 3.47, provider, http, google_sign_in, flutter_secure_storage, shared_preferences, url_launcher, flutter_dotenv, Sentry 10, PostHog                   |

### 9. Feature services (4.1 Discover, 4.2 Wanderbook, 4.3 Book, 4.4 Trip planner, 4.5 Notifications)

All called by the backend through the API toolkit (section 6), with daily limits below the free tiers. Keys live in
Secret Manager (`goawaygo-api-<name>`); the repo variable `EXTERNAL_API_PROVIDERS` lists the ones the deploy passes.

| Resource                                                            | What it does for us                                                                                                                    | Used by                  | Free limit / cost                                                           | Set up in                                                                                 |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Google Gemini API** (key in "Default Gemini Project", no billing) | Writes the 9 destination cards, the hourly trip ideas and trip plans (plans: Lite models first). Cards: 3 Flash → 3.1 Lite → 3.5 Lite. | B                        | free tier (3 Flash about 20 requests/day; Lite models more); paid at launch | **Discover: destination pages, photos and ideas** (backend README), `goawaygo.discover.*` |
| **Geoapify**                                                        | Place search while typing, place details, and the place name for a photo's location.                                                   | B                        | 3,000 credits/day                                                           | `goawaygo.external.providers.geoapify.*`                                                  |
| **Wikipedia, Wikidata, Wikimedia Commons**                          | Tourist-spot photos and their credits; confirms trip ideas are real places.                                                            | B (W, A load the photos) | free, no key (User-Agent required)                                          | `SpotPhotos`, `Ideas`                                                                     |
| **Unsplash**                                                        | Backup spot photos (credited, with referral links).                                                                                    | B (W, A load the photos) | demo app: 50 requests/hour                                                  | `goawaygo.external.providers.unsplash.*`                                                  |
| **OpenAI moderation** (`omni-moderation-latest`)                    | Checks every Wanderbook photo and text before it appears; nothing is posted if it can't check.                                         | B                        | free                                                                        | Secret `goawaygo-api-openai`, `ContentModeration`                                         |
| **Cloudflare R2** (`goawaygo-media`)                                | Stores Wanderbook photos (originals, location removed) behind `media.goawaygo.com`.                                                    | B (W, A show them)       | 10 GB; uploads stop at 9.5 GB                                               | Secrets `goawaygo-r2-*`, repo variable `WANDERBOOK_PHOTOS`, **Deployment** (README)       |
| **Travelpayouts** (marker 798632, project 597168)                   | Recent flight prices (Aviasales Data API) and affiliate links for flights, hotels and car rentals (links API).                         | B (W, A open the links)  | free; we earn commission on bookings                                        | Secret `goawaygo-api-travelpayouts`, `goawaygo.book.*`                                    |
| **KAYAK API** (sandbox)                                             | Live flight, hotel and car prices once production is approved (not used yet).                                                          | B (later)                | free sandbox; production by approval                                        | Secret `goawaygo-api-kayak`                                                               |
| **Firebase Cloud Messaging** (project `goaway-483709`)              | Push notifications to the Android app (Wanderbook activity, trip reminders, shared plans, announcements).                              | B (A receives)           | free                                                                        | Repo variable `FCM_PROJECT`; runtime account's FCM role (**Deployment** (README))         |
| **Admin flag** (`users.is_admin`)                                   | Who may review Wanderbook reports on `/admin/reports`; reports are also emailed to `team@goawaygo.com`.                                | B, W                     | —                                                                           | Set by hand in Neon (**Deployment** (README))                                             |

### Deadlines and limits to watch

| When            | What                                                                                                                                                                          |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **~2027-01-04** | Upgrade Google Cloud billing before the free trial ends **2027-01-14** (otherwise the backend stops).                                                                         |
| Monthly         | Neon compute hours (100), Resend emails (3,000), Sentry errors (5k), PostHog events (1M).                                                                                     |
| Daily / storage | Gemini free requests, Geoapify 3,000 credits/day, Unsplash 50/hour; R2 `goawaygo-media` 10 GB (Wanderbook uploads stop at 9.5 GB).                                            |
| Before launch   | Lawyer review of legal pages; company registration; Play Console + Android developer verification (rule reaching India in 2027); production on `goawaygo.com` with Cloud SQL. |
| DPDP            | India's substantive obligations apply from **13 May 2027**.                                                                                                                   |
| Yearly          | `goawaygo.com` renewal (Cloudflare Registrar).                                                                                                                                |

## Booking partners

Oct 31, 2026 · @GoAway

- Prices today: Aviasales only (recent flight fares, free).
- Live prices: KAYAK (flights, hotels, cars) and Agoda (hotels), both after approval.
- Everyone else: affiliate links only. Travelpayouts also gives a links API that turns any brand page into our tracked link.
- Commissions via Travelpayouts, read 31 Oct 2026.

### 1. Allowed in our app and website

| Brand               | Booking services (our commission)                               | Via Travelpayouts                           | Direct program?                             | Direct gives                                     | To join directly                    |
| ------------------- | --------------------------------------------------------------- | ------------------------------------------- | ------------------------------------------- | ------------------------------------------------ | ----------------------------------- |
| **Aviasales**       | Flights 1.1–1.3%                                                | **Recent flight prices** (Data API) + links | No: Travelpayouts is Aviasales' own program | —                                                | —                                   |
| **Trip.com**        | Hotels 5.5%, flights 1%, cars 4.5%, trains 1.8%, transfers 4.5% | Links                                       | Yes (trip.com/partners)                     | Links, search box, banners; no API, no prices    | Free sign-up; up to 7% with volume  |
| **DiscoverCars**    | Cars: 54% of their revenue; 365-day cookie                      | Links                                       | Yes (discovercars.com/affiliate)            | Links, widget; XML API with prices case by case  | Free sign-up; API by agreement      |
| **EconomyBookings** | Cars \~5.5%                                                     | Links                                       | Yes (economybookings.com/affiliate)         | Links; API and white label for advanced partners | Free sign-up; API by agreement      |
| Traveloka           | Hotels 3.6%, flights 0.36–0.7%, activities 3.6%                 | Links                                       | Via networks only (Involve Asia, Impact)    | Links                                            | Free; any website or social account |
| QEEQ                | Cars 5%                                                         | Links                                       | No official program found                   | —                                                | —                                   |
| GetRentacar         | Cars from private owners 10%                                    | Links                                       | No official program found                   | —                                                | —                                   |
| Localrent           | Cars 7.5–10% (\~25 countries)                                   | Links                                       | No official program found                   | —                                                | —                                   |

### 2. Allowed on our website only

| Brand           | Booking services (our commission)                                               | Via Travelpayouts          | Direct program?                              | Direct gives                                                                     | To join directly                             |
| --------------- | ------------------------------------------------------------------------------- | -------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------- |
| **Agoda**       | Hotels 6% (7% to 31 Dec), flights 1% and activities 4% in Asia-Pacific; no cars | Links (site 2+ months old) | Yes (partners.agoda.com): **applied 31 Oct** | Links, search box, banners, hotel data file; **Lite API with live hotel prices** | Original travel content; \~7-day review      |
| **Booking.com** | Stays 4% (5% to 31 Dec), cars 3–5%, flights €1.5 each, attractions 3%           | Links (site 2+ months old) | Only through CJ network                      | Links, banners; Demand API with live prices only for contracted partners         | CJ sign-up; signed contract for the API      |
| **Expedia**     | Hotels 3.6%, cars 1.35%, packages 1.8%; flights 0%                              | Links                      | Yes (Expedia Group creator program)          | Links, widgets; no API (Rapid API is for business partners)                      | Free; pays 4% hotels; India site not covered |
| Hotels.com      | Hotels 3.6%, rentals 1.8%, cars 1.35%                                           | Links                      | Yes (same Expedia Group program)             | As Expedia                                                                       | As Expedia                                   |
| Vrbo            | Holiday rentals 1.8% (4.5% to 31 Dec)                                           | Links                      | Yes (same Expedia Group program)             | As Expedia                                                                       | As Expedia                                   |
| Vio.com         | Hotel price comparison: 40–64% of Vio's revenue                                 | Links                      | No public program found                      | —                                                                                | —                                            |
| Kiwi.com        | Flights 3%                                                                      | Links                      | Yes (partners.kiwi.com)                      | Links; live flight API needs 50,000 monthly users                                | Complete travel site                         |
| Hostelworld     | Hostels \~5–7%                                                                  | Links                      | Yes (via Partnerize)                         | Links (API not checked)                                                          | Free; travel website or account              |
| Klook           | Activities 5%, hotels (8% to 31 Dec)                                            | Links                      | Yes (affiliate.klook.com)                    | Links, widgets (API not checked)                                                 | Free; travel-focused audience                |
| AutoEurope      | Cars 4.4–8%                                                                     | Links                      | Yes (autoeurope.co.uk)                       | Links (API not checked)                                                          | From 5% direct                               |

### 3. Not on Travelpayouts

| Brand     | Booking services                                  | Via Travelpayouts | Direct program?                                           | Direct gives                                                                                          | To join directly                                                   |
| --------- | ------------------------------------------------- | ----------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **KAYAK** | Flights, hotels, cars, packages (app and website) | Not available     | Yes, the only route: **applied 31 Oct, sandbox received** | Links, search box, widgets, white label (limited); **API with live prices** for flights, hotels, cars | Production API by case-by-case approval; no user minimum published |

## Roadmap

Where the project stands and what comes next. Tick items as they ship (merged to `develop` and live on dev).
Shared by all three repos; how to ship is in **Releasing** (README).

### Done

- [x] **Phase 1 — Foundation:** repos, branching (`develop`/`main`), CI, secret scanning, Dependabot.
- [x] **Phase 2 — Backend and login:** PostgreSQL, JWT + rotating refresh tokens, Google Sign-In, rate limits,
      email verification and password reset, website and app connected, UI matched across web and app.
- [x] **Phase 3 — Staging:** `api.goawaygo.com` (Cloud Run + Neon), `staging.goawaygo.com` (Cloudflare Pages),
      Resend email, Android builds via `staging.goawaygo.com/download` and Firebase beta (1.0.0 build 4).

### Phase 4 — Features

Direction (confirmed 2026-10-25): **free resources only** until launch · **global market** (English first, every
currency) · bookings through **affiliate partners** (commission; users book on the partner's site) · Wanderbook like
Instagram · phone sign-in with SMS (MVP 2). Each sub-phase's own choices (providers, limits) are decided when it
starts and recorded in its section below.

| Sub-phase                 | What users get                                                                                                                                           | Status |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| **4.0 Foundations**       | Error tracking, uptime alerts, analytics with consent, legal pages, API toolkit                                                                          | Done   |
| **4.1 Discover**          | Real destination pages (info, attractions, photos, weather, currency, visa, map), AI search, "Recently searched", rotating suggestions, Save to My Trips | Done   |
| **4.2 Wanderbook**        | Instagram-style posts with photos, comments, likes, follow, profiles (photo, bio, cover); report, block and moderation                                   | Done   |
| **4.3 Book (affiliates)** | Flights, Stays, Rentals search with prices; "Book" opens the partner; commission disclosure                                                              | Done   |
| **4.4 AI trip planner**   | Day-by-day itinerary, saved to My Trips                                                                                                                  | Done   |
| **4.5 Notifications**     | Push notifications and the bell on Home                                                                                                                  | Done   |
| **4.6 Me**                | My Trips, Recently viewed, edit profile and photo, delete account (phone sign-in with SMS moved to MVP 2)                                                | Done   |
| **4.7 Global readiness**  | More languages, currencies and regions; accessibility, speed, security review before launch                                                              | Done   |

**How we build (decided 2026-10-31):** in MVP rounds. **MVP 1** builds every sub-phase below (4.1 to 4.7) without
stopping for fix rounds; fixes, changes and new ideas are collected for **MVP 2, 3, 4, ...** after that.

#### 4.0 Foundations

Accounts (team Gmail, free): Sentry, PostHog, Better Stack. Existing: Cloudflare (Web Analytics, Email Routing),
Google Cloud.

- [x] **4.0a Error tracking** — Sentry in backend (Spring Boot), website (React) and app (Flutter): one
      organisation, a project per part, `staging` environment, release = version/commit, no personal data sent
      (`sendDefaultPii` off, emails/tokens scrubbed). Backend: JSON logs that Google Cloud Logging understands,
      request IDs in every log line and error.
- [x] **4.0b Health and uptime** — `GET /actuator/health` (status only, nothing else exposed); Better Stack checks
      the API and the website every 3 min and emails on downtime; public status page `status.goawaygo.com`.
- [x] **4.0c Legal and privacy** — Privacy Policy, Terms of Use, and Delete-my-data page on the website (DPDP Act
      2023 / Rules 2025 based: notice, consent, purposes, rights, retention, grievance contact); links in the website
      footer, the sign-up screens and the app's Profile. Contact addresses `privacy@` and `support@goawaygo.com` via
      Cloudflare Email Routing (forward to the team Gmail). Written for international law (GDPR, US state laws, DPDP,
      LGPD). **Still to do before launch: lawyer review.**
- [x] **4.0d Analytics with consent** — Cloudflare Web Analytics on the website (cookieless, aggregate, no consent
      needed); PostHog (product analytics + feature flags) in website and app, **only after the user agrees**, with a
      short event list and no personal data in events; consent choice changeable in Profile.
- [x] **4.0e API toolkit (backend)** — one way to call outside APIs: timeouts, retries and circuit breaker
      (Resilience4j), a database cache table with expiry, per-provider usage counters that stop before a free limit
      is exceeded, keys from Secret Manager. Plus a vulnerability scan of dependencies in CI (OSV-Scanner) for all
      repos.

#### 4.1 Discover

Decided 2026-10-26. Design and reasons: `backend/**Discover: destination pages, photos and ideas** (backend README).

- **Search:** type a place (country, region, city, landmark), pick or search, open its destination page. Place
  search: **Geoapify** (free, worldwide OpenStreetMap data). Unknown places: "We couldn't find that place".
- **Destination page:** shown all at once when ready (a travel animation until then). A sliding banner of up to 8
  tourist spots: the AI's top attractions with their **Wikipedia/Wikimedia Commons** photos (same name and nearby,
  so a wrong place can't appear), plus spots **Wikidata** lists nearby with **Unsplash** photos (only if the photo's
  description names the spot). Credit on every photo; fetched live, never stored.
- **9 info cards** (Quick Facts, Visa & Entry Rules, Best Time to Visit, Top Attractions, Best Areas to Stay, Food &
  Dining, Getting Around, Travel Insurance, Money & Connectivity): **one AI request per page open** returning the 9
  cards as separate JSON fields; nothing stored. Models in order: **Gemini 3 Flash** (free: 5/min, 20/day) →
  **Gemini 3.1 Flash Lite** (15/min) → **Gemini 3.5 Flash Lite** (15/min, 500/day), from a no-billing Google
  project; paid Gemini at launch. Temperature 0.1, fixed seed, response schema; each card checked on its own;
  changing details tagged "may vary"; links checked before showing; tap a card to expand.
- **Home banner:** the user's own last searches, up to 5 (account when signed in, the device otherwise), each with a
  live tourist-spot photo, sliding; tap to open. None yet: "No recent searches".
- **Ideas for your next trip:** every hour the AI suggests 30 varied places worldwide (beaches, mountains, heritage,
  cities, hidden gems and popular places), each confirmed on Wikipedia, kept in memory only; a random 6 every
  minute with category and "hidden gem" tags, **Save to My Trips**; tap to open.
- **My Trips:** saved places (sign-in needed).
- [x] Accounts: billing-free Google project + Gemini key, Geoapify key, Unsplash app (keys in Secret Manager)
- [x] Backend: place search, recent searches, AI cards, tourist spots and photos, random ideas, saved places
- [x] Website · [x] App · [x] Privacy Policy (stored search history, place names sent to Google for AI)

#### 4.2 Wanderbook

Decided 2026-10-28.

- **Viewing:** anyone can view public profiles and posts, signed in or not (rate limited per IP against scraping);
  posting, liking, commenting and following need an account.
- **Profiles:** account name and photo, cover photo, bio, home town, counts, post grid; a random public id in links.
  **Public or private:** following a private profile sends a request the owner approves or declines; only approved
  followers see its posts and lists; making it public approves waiting requests.
- **Posts:** 1-10 photos, caption, place tag filled in from the photo's location (place, state, country; editable,
  or added by hand; opens the destination page); edit caption, delete. Likes and comments (delete your own, and
  comments on your posts).
- **Feed:** one shared timeline of the newest posts from all public profiles, private profiles you follow, and yours.
- **People search** by name.
- **Safety:** every photo and text checked by **OpenAI omni-moderation** (free) before it appears; report posts,
  comments and users; block (hides both ways, removes follows); reports emailed to the team plus an admin page on
  the website.
- **Photos:** originals, never resized or recompressed (a scrapbook of memories), shown as they are everywhere.
  Exact coordinates are never published or stored: the backend turns the photo's GPS into the place tag and removes
  the GPS from the file without touching the picture. iPhone HEIC photos become full-size JPEGs on the phone
  (browsers can't show HEIC). Uploaded one by one through the backend (checked first) into Cloudflare R2
  (`goawaygo-media`, `media.goawaygo.com`); uploads stop before the free 10 GB (about 2,000 photos) is used up.
- **Legal:** Terms (rules for user content), Community Guidelines page, Privacy Policy and Delete my data updated.
- [x] Accounts: OpenAI key, R2 bucket `goawaygo-media` and access key (Secret Manager)
- [x] Backend: profiles, follows and requests, private profiles, blocks, people search
- [x] Backend: photos and moderation, posts, likes, comments, feed, reports, admin
- [x] Website · [x] App · [x] Legal pages (Terms, Community Guidelines, Privacy Policy, Delete my data)

#### 4.3 Book

Decided 2026-11-01 ("option E"): build now with what is open to a pre-launch app; each category moves to live
prices when a partner approves us, without new screens. Full comparison: the founders' findings doc.

- **Flights:** Aviasales' recent prices (Travelpayouts Data API, free): the cheapest fare on the date asked, cheaper
  dates that month, a price calendar, and "See all flights" (Aviasales' live search). Labelled "recent, may change".
- **Stays and cars:** partner cards opened on the traveller's search (no free price source exists). App: brands that
  allow apps only (Trip.com; DiscoverCars, EconomyBookings, QEEQ); website: those plus website-only brands later.
- **Links:** every partner page becomes our affiliate link (Travelpayouts links API, marker 798632, project
  597168); a partner that hasn't approved us yet gets its plain page. Commission disclosure on every results page.
- **Live prices later:** KAYAK (flights, hotels, cars; sandbox received, production pending) and Agoda (hotels;
  rejected 2026-11-07, reapply once `goawaygo.com` is the real site with crawlable travel content).
- [x] Accounts: Travelpayouts (Aviasales, EconomyBookings connected; Trip.com, DiscoverCars in review), KAYAK sandbox
- [x] Backend: airports, recent flight prices and calendar, partner links, stays and cars partners
- [x] Website · [x] App · [x] Legal pages (affiliate disclosure in Terms and Privacy Policy) · [x] Released in 1.2.0 build 8

#### 4.4 AI trip planner

Decided 2026-11-08.

- **Plan:** from a destination page or a saved place in My Trips: start date, 1-10 days, travellers (solo, couple,
  family, friends), pace, budget level and interests. Each day has a morning, afternoon and evening (place, what to
  do, rough cost), food picks and a tip; plus a title, summary and trip tips.
- **Budget estimate:** about X a day for food, transport and activities and Y a night for stays, for the whole group;
  labelled an AI estimate, flights never included.
- **Change a day:** rewrite one day, optionally with a wish ("more street food"); the other days stay.
- **Share by link:** read-only page anyone can open, after an OpenAI moderation check (also for changes to a
  shared plan).
- **Booking shortcuts:** Stays and Car rentals open for the plan's place and dates; Flights opens with the destination.
- **AI:** Gemini (3.1 Flash Lite → 3.5 Flash Lite → 3 Flash), like Discover; a better model later. Signed-in users
  only: 5 new plans and 20 day changes a day per account, 50 saved plans.
- [x] Backend: plans, change a day, share, budget estimate
- [x] Website · [x] App · [x] Legal pages (trip plans in Privacy Policy and Terms) · [x] Released in 1.3.0 build 9

#### 4.5 Notifications

Decided 2026-11-09.

- **Events:** Wanderbook (new follower, follow request, request accepted, likes on your post grouped per post,
  comments on your post); trip reminders (a saved plan starts in 3 days, and tomorrow); someone opened your shared
  plan (at most once a day per plan); GoAwayGo announcements (sent by an admin from the website).
- **Where:** the bell on Home lists them on the app and the website (unread count, mark as read, open the post,
  profile or plan). Push only on the Android app, through Firebase Cloud Messaging (free); no browser push.
- **Permission (Android 13+):** asked once after sign-in; if dismissed, once more at a useful moment (after following
  someone, posting or saving a plan); always a switch in Profile.
- **Settings:** a switch per type (Wanderbook, trip reminders, shared plans, announcements) turns off its push; the
  bell still lists everything. Notifications are kept 90 days.
- **How it runs:** the backend sends pushes with its own Google service account (no key file; it needs the Firebase
  Cloud Messaging role in project `goaway-483709`, then the repo variable `FCM_PROJECT`). Trip reminders: a daily
  GitHub Actions job at 09:00 IST calls the backend's reminder run. The app reads its Firebase settings from
  `env/staging.env` (public IDs; no `google-services.json`).
- [x] Backend: notifications, device tokens, settings, push, reminders, announcements
- [x] Website · [x] App · [x] Legal pages (device tokens and notifications in the Privacy Policy) · [x] Released in 1.4.0 build 10

#### 4.6 Me

Decided 2026-11-09.

- **Edit your account** (User Profile): name and photo (the same as on Wanderbook), password (change it with the
  current one, or set one on a Google account), email (the new address must be confirmed by a link first; the old
  one is told), country and currency (used later to show prices in your currency, 4.7). Changing the password, the
  email or deleting the account first asks to confirm it's you: your password, or Google for accounts without one.
- **Delete account** (app and website, as Google Play requires, plus the Delete my data page): 30 days to change your
  mind. At once: signed out everywhere, pushes stopped, profile, posts and comments hidden from others, and an email
  with the date. Signing in again within 30 days keeps the account. After 30 days the daily job deletes its photo
  files, then the account and everything in it, and sends a last email.
- **Recently viewed:** places and trip plans opened (your own and shared ones), newest first, the latest 30; saved
  for signed-in accounts, on the device otherwise; can be cleared. My Trips was already done in 4.1 and 4.4.
- **Phone sign-up and sign-in with SMS: moved to MVP 2.** SMS can't be kept at $0: Firebase sends real SMS only with
  billing on, its free allowance may cover only test numbers, India costs about $0.07 a text, and Google Cloud
  budgets only alert, they can't stop charges.
- [x] Backend: account details, password, email change, delete with 30 days, daily deletion job, Recently viewed
- [x] Website · [x] App · [x] Legal pages (Delete my data, Privacy Policy)

#### 4.7 Global readiness

Decided 2026-11-10.

- **Languages:** English, Hindi, Spanish, French, German, Arabic (right to left) and Japanese, on the app and the
  website. The user picks one (or the phone or browser's language is used); the apps send it as
  `Accept-Language`, and the account keeps it for pushes and emails. Translations written with AI help: **a native
  speaker checks each language before launch.** Legal pages (Privacy Policy, Terms, Delete my data, Community
  Guidelines) stay in English, the version that counts.
- **AI content** (destination cards, trip plans, ideas) is written in the user's language. Place names stay in their
  usual international form, so photos and Wikipedia checks keep working. A trip plan keeps the language it was made
  in.
- **Currencies:** prices in the user's currency everywhere (flight fares from Aviasales, trip plan costs, the
  exchange rate on destination pages). Signed in: the currency in User Profile; signed out: guessed from the phone or
  browser's region, changeable.
- **Regions and formats:** dates, numbers and prices shown the local way for the user's language and region.
- **Reviews before launch:** accessibility (WCAG 2.2 AA), speed (website bundle, images, app startup), security
  (OWASP Top 10 across the three repos, website security headers). Each ends with fixes and a short report.
- [x] Backend: languages and currencies · [x] Website · [x] App
- [x] Accessibility · [x] Speed · [x] Security · [x] Regions and formats

#### Later sub-phases

A detailed checklist (and that sub-phase's decisions) is added when it starts. Notes so far:

- **Phone sign-in (MVP 2, carried over):** SMS is never free (Firebase: billing required, billed per SMS by country): cap it then.
- Wanderbook photos: R2 bucket `goawaygo-user-media`. Push: Firebase Cloud Messaging (free).

### MVP 2 — Release pipeline and website launch

Decided 2026-11-10 and 2026-11-11. The website launches for customers on `goawaygo.com` from `main`. The Android
app stays an APK download with beta testing; a store launch comes in a later MVP. The beta app uses production.
Every change ships through versions that move up through three environments, with automated and performance tests
as evidence.

| Branch        | Purpose                                   | Deploys to                                    | Merges to                       |
| ------------- | ----------------------------------------- | --------------------------------------------- | ------------------------------- |
| `feature/...` | A new feature                             | nowhere (tested inside CI)                    | → `develop` only, no approval   |
| `fix/...`     | A bug fix                                 | nowhere (tested inside CI)                    | → `develop` only, no approval   |
| `develop`     | Development: every change, a new version  | **dev** (`api-dev`, `dev.goawaygo.com`)       | → `test` only, owner's approval |
| `test`        | Testing a version before customers see it | **test** (`api-test`, `test.goawaygo.com`)    | → `main` only, owner's approval |
| `main`        | Customers                                 | **prod** (`api.goawaygo.com`, `goawaygo.com`) | —                               |

Any other branch name is rejected (Dependabot's `dependabot/...` is allowed). Pull requests are opened by the bot
account `goawaygo-bot` and approved by `goawaygoofficial`; deployments to test and prod need the same approval. The
repos are public (2026-11-11): free branch rules, protected environments and Actions minutes.

- [x] **5.1 Branches and rules** — `test` branch; branch name rules; only `feature`/`fix` → `develop` → `test` →
      `main`; approvals on `test` and `main`; branch guard as a required check.
- [x] **5.2 Versions** — every merge into `develop` makes a version (`feat:` raises the minor number, `fix:` the
      patch) with a GitHub Release and artifacts built once: the backend image and the website build. The website reads
      its settings when it starts, so one build runs in every environment.
- [x] **5.3 Three environments** — dev, test, prod on free tiers: Cloud Run ×3, Neon projects `goawaygo-staging` (dev, test) and `goawaygo-prod`, production in its own Google Cloud project `goawaygo-prod`, Cloudflare Pages
      domains, secrets per environment, Google sign-in origins, Sentry and PostHog environments. Done 2026-11-11/12: dev
      (`api-dev`, `dev.goawaygo.com`), test (`api-test`, `test.goawaygo.com`), production moved to the Google Cloud
      project `goawaygo-prod` (`api.goawaygo.com`, 2026-11-12).
- [x] **5.4 `controller.yaml`** — deploys a version to test or prod, only if it is merged there and passed AT and PT
      in the environment below; deployment status per version; rollback to an earlier version. Done 2026-11-12:
      first promotions to test and prod (backend v1.9.0, website and app v1.8.0); the AT and PT condition comes with
      5.5 and 5.6.
- [x] **5.5 Automation tests** (repo `goawaygo_automation_tests`) — API and website (Playwright), app (Maestro on an
      Android emulator); a short run on every pull request, the full run after each deployment. Done 2026-11-12/13:
      22 API, 9 website and 3 app tests pass in dev and test; read-only smoke tests in prod. They found a real bug
      (a tap between a tab's icon and label was ignored; fixed).
- [x] **5.6 Performance tests** (repo `goawaygo_performance_tests`) — API and website (k6), app start-up and
      scrolling; limits that fail the run; fake AI and partner services in dev and test. Done 2026-11-12/13: limits
      on the backend's own time (Server-Timing on test runs: reads ~3 ms, destination ~31 ms p95), Core Web Vitals,
      app start-up ~1 s and scrolling on the emulator. A version moves up only with AT and PT ✅ below.
- [ ] **5.7 Website launch** — pre-rendered public pages (search engines and partners can read them), sitemap,
      production monitoring and alerts, database backups, Google sign-in in production mode, launch checklist; then
      apply to Agoda again.
- [ ] **5.8 Product changes** — from the MVP 1 testing, added here as they are sorted.

Carried over: phone sign-in with SMS (only if it can be capped), Booking.com through Travelpayouts (late December),
KAYAK, smaller copies of Wanderbook photos, a native speaker's check of the translations.

### Phase 5 — Launch

App store launch (a later MVP) · company registration · Play Console + Android developer verification (before the
2027 rule reaches India) · production database on Cloud SQL (the website launched on Neon in MVP 2, 2026-11-13) · Google billing upgraded before the
trial ends (2027-01-14) · DPDP compliance review (substantive obligations from 13 May 2027).

## History

### Website launch (MVP 2, 5.7)

The website goes live for customers on `goawaygo.com`, served from `main` (the `prod` environment). Decided
2026-11-13: launch now; the lawyer review of the legal pages and the native-speaker check of the 6 other languages
come right after launch. Work through the parts in order and tick each box. Commands run in Git Bash; console steps
name the exact menus.

#### A. Before the switch

**Website build** (done in code, 5.7)

- [x] Public pages pre-rendered with their own titles and descriptions; `sitemap.xml` and `robots.txt`; dev, test,
      staging and `pages.dev` copies send `X-Robots-Tag: noindex` (website PR #70).
- [x] 50 destination pages rendered from prod's data during each prod website deploy (#71).
- [x] A website version with both is in prod (v1.11.2, 13 Nov 2026: 50 of 50 destination pages, 59 sitemap entries).

**Database backups** (backend **Deployment** (README), "Database backups")

- [x] Key pair made (`scripts/backup-keys.sh`) and an offline copy of the private key kept.
- [x] R2 bucket `goawaygo-backups` with a 30-day lifecycle rule; its token stored as `R2_BACKUP_ACCESS_KEY_ID` /
      `R2_BACKUP_SECRET_ACCESS_KEY`; the deployer may read `goawaygo-db-owner-password`.
- [x] First backup run green (Actions → Database backup → Run workflow); the copy is in R2.
- [x] Practice restore into a scratch database (`scripts/restore-backup.sh`) worked.

**Monitoring and alerts**

- [x] Better Stack → Monitors: **GoAwayGo website (goawaygo.com)** checks `https://goawaygo.com/home` for the keyword
      "GoAwayGo" every 3 minutes (follows redirects, so it works before and after the switch) → email the primary
      responder. It shows as "Goaway website" on `status.goawaygo.com`, with the API and App Downloads monitors; the
      old staging website monitor is off the status page (pause it after the switch, part C).
- [x] Sentry → Monitors → Alerts (all email the suggested assignees, else recently active members):
      "Prod new error (backend + web)" and "App new error" (a new issue, an escalating issue or a regression;
      backend and web in environment `production`, the app in all environments), and "Prod error burst (backend +
      web)" and "App error burst" (an issue seen more than 50 times in an hour, at most one email an hour).
- [x] Google Cloud (project goawaygo-prod) → Monitoring: policy "GoAwayGo prod API errors (5xx)" (Cloud Run
      `goawaygo-backend` 5xx responses over 10 in 5 minutes) → email channel "GoAwayGo owner". Free within the
      Cloud Monitoring allowance.
- [x] Budget alert on the billing account still set ("goaway-auth-budget", ₹100 a month, whole billing account,
      alerts at 50, 90, 100 and 150%).

**Google sign-in in production mode** (Google Cloud project `goaway-483709`)

- [x] Google Auth Platform → **Audience** → Publishing status: **Publish app** (from "Testing" to "In production").
      With only the basic scopes (email, profile, openid) no Google review is needed; the consent screen shows the
      app name and `goawaygo.com`.
- [x] Google Auth Platform → **Branding**: home page `https://goawaygo.com`, privacy policy
      `https://goawaygo.com/privacy`, terms `https://goawaygo.com/terms`, authorised domain `goawaygo.com`.
- [x] Clients → **GoAwayGo Web** → Authorised JavaScript origins: add `https://goawaygo.com` and
      `https://www.goawaygo.com` (keep staging, dev and test for now).

#### B. The switch (about 30 minutes; pick a quiet time)

1. [x] **Backend allows the new address.** Repository variables of goawaygo_backend (Settings → Secrets and variables
       → Actions → Variables): `CORS_ALLOWED_ORIGINS` = `https://goawaygo.com,https://www.goawaygo.com,https://staging.goawaygo.com`
       and `WEB_BASE_URL` = `https://goawaygo.com` (links in emails). Then redeploy prod with the same version:
       Actions → Controller → Run workflow → branch `main` → (version empty) → approve **prod**.
2. [x] **Cloudflare → Rules**: turn off the Redirect Rule "goawaygo.com to website".
3. [x] **Cloudflare → DNS → Records**: delete the two placeholder A records `@` and `www` (`192.0.2.1`). (Done by
       step 4: adding the custom domains replaced them with CNAMEs to `goawaygo-web-prod.pages.dev`.)
4. [x] **Cloudflare → Workers & Pages → goawaygo-web-prod → Custom domains**: add `goawaygo.com`, then
       `www.goawaygo.com`. Cloudflare creates the DNS records and the certificate (a few minutes).
5. [x] **www to the main address**: Rules → Redirect Rules → Create: when hostname equals `www.goawaygo.com`, redirect
       301 to `https://goawaygo.com${path}` with the query string kept.
6. [x] **GitHub variables**: website environment `prod`: `WEB_URL` = `https://goawaygo.com`; website repository
       variable `PROD_WEB_URL` = `https://goawaygo.com` (the prod smoke tests).
7. [x] **Check**: `https://goawaygo.com/home` loads, sign-in with email and with Google works, a destination page
       loads, `https://goawaygo.com/sitemap.xml` and `/robots.txt` answer, `https://www.goawaygo.com` redirects.
8. [x] **staging.goawaygo.com**: Redirect Rule "staging.goawaygo.com to goawaygo.com": hostname
       `staging.goawaygo.com` → 301 to `https://goawaygo.com${path}` with the query string kept. The custom domain
       stays on `goawaygo-web-frontend` for now (removing it can remove its DNS record, and the redirect needs one);
       it goes when that project is retired (part C). The beta app's legal links (`WEBSITE_URL`) keep working
       through the redirect; the next app build points at goawaygo.com directly.

Switched on 13 Nov 2026 (after a Cloudflare Workers API outage delayed steps 2–8). Checked: `/`, `/home`,
`/privacy`, `/terms` and a destination page answer 200 with their own titles, no `X-Robots-Tag`; `sitemap.xml`
(59 entries) and `robots.txt` answer; http, `www` and `staging` redirect 301 with the path and query kept; the API
accepts `https://goawaygo.com`; the Google button loads. Still to try by hand: signing in with email and with Google.

#### C. After the switch

- [x] Google Search Console: property `goawaygo.com` (domain) → Sitemaps → `https://goawaygo.com/sitemap.xml`
      submitted 13 Nov 2026: Success, 59 pages found.
- [ ] Apply to Agoda again (the partner application), now that the site is readable without JavaScript.
- [ ] Lawyer review of the Privacy Policy, Terms and Community Guidelines (decided: right after launch).
- [ ] Native-speaker check of the 6 other languages (decided: right after launch).
- [x] `staging.goawaygo.com` removed from the backend's `CORS_ALLOWED_ORIGINS` and the Google origins (it only
      redirects); the old Pages project `goawaygo-web-frontend` deleted (14 Nov; **History** (README)).
- [x] The disabled Redirect Rule "goawaygo.com to website" deleted.
- [x] Better Stack: the old staging website monitor deleted; status page logo links to `https://goawaygo.com`.
- [x] App: `WEBSITE_URL=https://goawaygo.com` (app PR #76), and release builds use `env/prod.env` reporting as
      `production` (**History** (README) 7.3). Both arrive with the next app build.
- [ ] **Roadmap** (README): tick 5.7 (after Agoda, the lawyer review and the native-speaker check).

### Clean-up after launch

Done 13–14 Nov 2026, after the website launched on `goawaygo.com`. Rule: everything **dev**, **test** and **prod**
use stays; everything else from before (the pre-launch "staging" setup) is deleted. The only website addresses are
`goawaygo.com` (+ `www` redirecting to it), `dev.goawaygo.com` and `test.goawaygo.com`.

#### What stays (who uses what)

| Service            | dev                                                           | test                                                 | prod                                                  |
| ------------------ | ------------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------- |
| Website            | Pages `goawaygo-web-dev`, dev.goawaygo.com                    | Pages `goawaygo-web-test`, test.goawaygo.com         | Pages `goawaygo-web-prod`, goawaygo.com (+ www → 301) |
| API (Cloud Run)    | `goawaygo-backend-dev` (goawaygo-staging), api-dev            | `goawaygo-backend-test` (goawaygo-staging), api-test | `goawaygo-backend` (goawaygo-prod), api               |
| Database (Neon)    | `goawaygo_dev`, project goawaygo-staging                      | `goawaygo_test`, project goawaygo-staging            | `goawaygo`, project goawaygo-prod                     |
| Secrets            | `goawaygo-dev-*` + shared `goawaygo-api-*` (goawaygo-staging) | `goawaygo-test-*` + shared (goawaygo-staging)        | goawaygo-prod                                         |
| GitHub environment | `dev`                                                         | `test`                                               | `prod`, `backup`                                      |
| Sentry environment | `dev`                                                         | `test`                                               | `production`                                          |

"goawaygo-staging" (Google Cloud and Neon project names) is the home of dev **and** test, decided at the start of
MVP 2; project IDs can't be renamed. Shared on purpose: the image registry (goawaygo-staging), the outside-API keys
(incl. KAYAK, kept for later), Google sign-in clients (web, Android release + debug, iOS), Firebase (Android app),
Resend, R2 (`goawaygo-downloads` → downloads.goawaygo.com, `goawaygo-media` → media.goawaygo.com,
`goawaygo-backups`), email forwarding (support@, privacy@), Better Stack (status.goawaygo.com), PostHog, Search
Console, Travelpayouts, Gemini (project "GoAwayGo Gemini"), Geoapify, Unsplash, OpenAI. Developer tools stay:
localhost origins for sign-in, the AI GitHub apps.

#### What was deleted or changed

- **Google Cloud:** old v1.6.0 service `goawaygo-backend` in goawaygo-staging (it was still connected to the prod
  database) and its 6 secrets (copies of prod's database passwords, JWT keys, R2 keys); projects
  `goawaygo-prod-514417` (the duplicate) and "My First Project" shut down (gone for good after 30 days); the unused
  Firebase "Browser key" (no web app in Firebase); the Gemini project renamed "GoAwayGo Gemini".
- **Cloudflare:** Pages project `goawaygo-web-frontend` (111 old deployments first); `staging.goawaygo.com` (DNS
  record and redirect rule); the old "goawaygo.com to website" rule (the www rule is now named "www.goawaygo.com to
  goawaygo.com"); the unused "Cloudflare Agent Token" (26 permissions); app builds 5–9 in downloads (10–12 kept);
  downloads CORS now allows only the 3 sites + localhost. Added: monitor-only DMARC record.
- **Google sign-in, backend CORS, Sentry:** staging removed from the web client's origins and from prod's
  `CORS_ALLOWED_ORIGINS` (prod redeployed: the API refuses staging); Sentry environments `staging` and
  `local-verification` hidden; the website's Sentry project accepts only the 3 sites.
- **Neon:** the empty `goawaygo-staging` database and role in the prod project; the unused default `neondb` and role in
  the dev/test project.
- **Better Stack:** the staging website monitor; the website monitor checks `goawaygo.com/home`; the status page logo
  links to goawaygo.com.
- **GitHub:** the empty `staging` environment and its 60 old deployment records; every environment now holds all of
  its own variables and only shared ones are repository variables (backend #90; the image build has its own
  `IMAGE_*`); the old repository-level variables.
- **Code and docs:** the staging site out of the website (#80) and app (#77: `env/prod.env`, Sentry `production`);
  `dev:dev-api` instead of the staging API; package name `goawaygo-web`; LINKS, FOUNDATIONS, RELEASING, ROADMAP,
  **Conventions and decisions** (README), deployment docs updated.
- **This PC:** stray `dbg.png`, `backend/Artifact`, `backend/Enabling`.

- **Accounts (signed in by the owner):** GitHub app "Cloudflare Workers and Pages" uninstalled and its authorization
  revoked; PostHog project "GoAwayGo Staging" renamed "GoAwayGo" (same project and token; no authorized URLs, no
  integrations); Resend API key "goaway-staging" renamed "goawaygo" (same key; one domain, no webhooks); the last old
  backend repository variable `WEB_BASE_URL` deleted (the prod smoke test falls back to `https://goawaygo.com`).
- **KAYAK:** no portal account yet (sandbox only); nothing to clean. Its key stays for when KAYAK approves.

#### Still to happen

- The testers' installed app (build 12) still links to staging.goawaygo.com (now gone) for Privacy, Terms, Delete my
  data and shared plans; build 13 links to goawaygo.com and reports to Sentry as `production`.
