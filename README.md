# GoAwayGo — App Frontend

Flutter app for **GoAwayGo**, a travel app: search flights, hotels and rentals, explore destinations, and share trips in the Wanderbook.

Backend: [goawaygoofficial/goawaygo_backend](https://github.com/goawaygoofficial/goawaygo_backend) (Spring Boot).

## Documentation

New here? Read these in order:

| File                    | What it's for                                                                           |
| ----------------------- | --------------------------------------------------------------------------------------- |
| `README.md` (this file) | What this part does and how to run it locally                                           |
| `CONTRIBUTING.md`       | Branches, commits, PRs and checks                                                       |
| `FOUNDATIONS.md`        | Every service and tool GoAwayGo uses, what it's for, free limits, where it's configured |
| `LINKS.md`              | Every dashboard and console, a weekly checklist, and how to give a new developer access |
| `CLAUDE.md`             | Project facts and conventions (also read by Claude Code)                                |
| `RELEASING.md`          | What happens after a merge, how to release, version numbers, rollbacks                  |
| `ROADMAP.md`            | What's done and what's next                                                             |
| `docs/`                 | Details for this repo (Android releases)                                                |

`CLAUDE.md`, `FOUNDATIONS.md`, `LINKS.md`, `RELEASING.md` and `ROADMAP.md` are the same in all three repos.

## Features

| Module              | Folder                                 | What it does                                                                         |
| ------------------- | -------------------------------------- | ------------------------------------------------------------------------------------ |
| Auth                | `lib/features/01_auth_register`        | Email sign up / sign in, Google Sign-In, forgot password                             |
| Home                | `lib/features/02_home`                 | Categories, place search with suggestions, recent searches, ideas (new every minute) |
| Flights             | `lib/features/03_flights`              | Flight search (airport suggestions), recent fares, "See all flights" on Aviasales    |
| Hotels              | `lib/features/04_hotels`               | Hotel search, partner cards opened on the place and dates (app-allowed partners)     |
| Rentals             | `lib/features/05_rentals`              | Car rental search (city or airport), rental partner cards                            |
| Book (shared)       | `lib/core/book`, `global_widgets/book` | Book API calls (`channel=app`), models, formatting; results layout and cards         |
| Destination info    | `lib/features/06_destinationInfo`      | Travel animation, spot photos, the 9 AI cards                                        |
| My Trips            | `lib/features/07_trips`                | Places saved from the ideas (sign-in needed)                                         |
| Discover (shared)   | `lib/core/discover`                    | Discover API calls, models, recent searches on the device                            |
| Wanderbook          | `lib/features/08_wanderbook`           | Feed, profiles, follow requests, posting original photos, likes, comments, reports   |
| Wanderbook (shared) | `lib/core/wanderbook`                  | Wanderbook API calls and models                                                      |
| Profile             | `lib/features/09_profile`              | My profile and other users' profiles                                                 |

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
