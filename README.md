# Goaway — App Frontend

Flutter app for **Goaway**, a travel app: search flights, hotels and rentals, explore destinations, and share trips in the Wanderbook.

Backend: [goawayofficial/goaway_backend](https://github.com/goawayofficial/goaway_backend) (Spring Boot).

## Features

| Module           | Folder                            | What it does                                             |
| ---------------- | --------------------------------- | -------------------------------------------------------- |
| Auth             | `lib/features/01_auth_register`   | Email sign up / sign in, Google Sign-In, forgot password |
| Home             | `lib/features/02_home`            | Category buttons and card carousel                       |
| Flights          | `lib/features/03_flights`         | Flight search form                                       |
| Hotels           | `lib/features/04_hotels`          | Hotel search form                                        |
| Rentals          | `lib/features/05_rentals`         | Rental search form                                       |
| Destination info | `lib/features/06_destinationInfo` | Destination details                                      |
| Wanderbook       | `lib/features/08_wanderbook`      | Travel profile, tabs and photo grid                      |
| Profile          | `lib/features/09_profile`         | My profile and other users' profiles                     |

## Tech stack

- Flutter (Dart SDK `^3.7.0`)
- State management: [`provider`](https://pub.dev/packages/provider)
- HTTP: [`http`](https://pub.dev/packages/http)
- Auth: [`google_sign_in`](https://pub.dev/packages/google_sign_in)
- Config: [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv)
- Local storage: [`shared_preferences`](https://pub.dev/packages/shared_preferences)

## Project structure

```
lib/
├── main.dart              # App entry: loads .env, restores user, starts app
├── splash_screen.dart
├── features/              # One folder per feature (screens / widgets / services / utils)
├── global_utils/          # Colors, bottom navigation bar
├── global_widgets/        # Shared widgets (dialogs, animations, backgrounds)
├── models/                # Data models (User)
├── providers/             # ChangeNotifier providers (UserProvider)
└── services/              # API clients (UserService)
```

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.7+)
- Android Studio / Xcode for emulators, or a physical device
- The [backend](https://github.com/goawayofficial/goaway_backend) running locally or deployed

### 1. Clone and install

```bash
git clone https://github.com/goawayofficial/goaway_app_frontend.git
cd goaway_app_frontend
flutter pub get
```

### 2. Create `.env`

Copy the example. It already contains the project's (public) Google client IDs:

```bash
cp .env.example .env
```

| Variable               | Description                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| `BASE_URL`             | Backend URL, no trailing slash. Android emulator → your PC's localhost: `http://10.0.2.2:8080`          |
| `GOOGLE_WEB_CLIENT_ID` | Google **Web** OAuth client. The app requests ID tokens for this audience; the backend only accepts it. |
| `GOOGLE_IOS_CLIENT_ID` | Google **iOS** OAuth client for bundle ID `com.goawayofficial.app`                                      |

> `.env` is bundled into the app as an asset, so anyone with the app can read it. Only put **public** config here — never real secrets.

### 3. Google Sign-In on your machine (Android)

App ID (Android package and iOS bundle ID): **`com.goawayofficial.app`**. Google Cloud project: `goaway-483709`.

Android has no client ID in the app: Google recognises it by the package name **and the SHA-1 of the signing
key**. Each developer's debug key is different, so ask the project owner to add yours as an Android OAuth client
(package `com.goawayofficial.app`). Get your SHA-1 with:

```bash
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

(PowerShell. On macOS/Linux use `~/.android/debug.keystore`.) Release builds signed by Google Play need their
own Android client with the SHA-1 from Play Console → _App integrity_.

### 4. Run

```bash
flutter run
```

## Useful commands

```bash
flutter analyze     # Static analysis / lint
flutter test        # Run tests
flutter build apk   # Android release build
```

## Files that are never committed

`.env`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `android/local.properties`, keystores (`*.jks`, `*.keystore`) and `key.properties`. See `.gitignore`.
