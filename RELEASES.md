# GoAwayGo App — releases

Every merge into `develop` whose CI passes becomes a version (Release workflow) and goes to **dev**; a version
moves to **test** and **prod** only through the Controller, after it passed below and with the owner's
approval. Newest first. Each entry: the changes (pull requests) and where it ran. Update this file in the PR
that records a release reaching prod (README → Releasing).

## v1.9.9 — 2026-11-13

- CLEANUP.md: accounts done ([#79](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/79))

## v1.9.8 — 2026-11-13

- Clean-up record: only dev, test and prod remain ([#78](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/78))

## v1.9.7 — 2026-11-13

- Clean-up: release builds are production, not staging ([#77](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/77))

## v1.9.6 — 2026-11-13

- Website links: goawaygo.com ([#76](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/76))

## v1.9.5 — 2026-11-13

- LAUNCH.md: part A done ([#74](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/74))
- LAUNCH.md: part B done (goawaygo.com is live) ([#75](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/75))

## v1.9.4 — 2026-11-13

- docs: launch checklist for goawaygo.com ([#73](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/73))

## v1.9.3 — 2026-11-12

- docs: 5.5 and 5.6 done ([#72](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/72))

## v1.9.2 — 2026-11-12

Ran in: test ✅ 2026-11-12 · prod ✅ 2026-11-12

- fix: the whole bottom-bar tab is tappable ([#69](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/69))

## v1.9.1 — 2026-11-12

- fix: no secrets in test reports ([#68](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/68))

## v1.9.0 — 2026-11-12

- feat: automated and performance tests after every deployment, required to move a version up ([#67](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/67))

## v1.8.1 — 2026-11-12

- docs: production runs in goawaygo-prod; 5.4 done ([#66](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/66))

## v1.8.0 — 2026-11-11

Ran in: test ✅ 2026-11-11 · prod ✅ 2026-11-12

- feat: controller.yaml moves a version to test and prod ([#63](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/63))

## v1.7.0 — 2026-11-11

- feat: dev, test and prod environments ([#62](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/62))

## v1.6.0 — 2026-11-11

- feat: a version and GitHub Release for every merge into develop ([#61](https://github.com/goawaygoofficial/goawaygo_app_frontend/pull/61))

## Before versioned releases (MVP 1, up to v1.5.0)

Versions started with MVP 2 (v1.6.0, Release workflow). What shipped before, all three parts together:

- **Phase 1 — Foundation:** repos, branching, CI, secret scanning, Dependabot.
- **Phase 2 — Backend and login:** PostgreSQL, JWT + rotating refresh tokens, Google Sign-In, rate limits, email
  verification and password reset, website and app connected, UI matched across web and app.
- **Phase 3 — First hosted version:** API on Cloud Run + Neon, the website on Cloudflare Pages, Resend email, Android
  builds for download and Firebase beta (app 1.0.0 build 4).
- **Phase 4 — Features:** 4.0 foundations (monitoring, analytics with consent, legal pages, the outside-API toolkit),
  4.1 Discover, 4.2 Wanderbook, 4.3 Book, 4.4 AI trip planner, 4.5 notifications, 4.6 Me, 4.7 global readiness
  (7 languages, currencies, accessibility). Details per feature: README → Roadmap.

## Android builds (testers)

Every build published for testers (Firebase App Distribution and goawaygo.com/download). The build number always goes up.

| Date       | Version | Build | Notes                                                                                                                                                                                                                                                                  |
| ---------- | ------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-10-17 | 1.0.0   | 4     | First public beta (build 3 withdrawn: version-code bug)                                                                                                                                                                                                                |
| 2026-10-24 | 1.0.0   | 6     | First GoAwayGo build: new name and app ID `com.goawaygo.app` (testers install it, then remove the old Goaway app); legal links, optional usage statistics, Sentry 10, Android 8.0+. Build 5 skipped (an untracked upload with placeholder notes, 2026-10-17, replaced) |
| 2026-10-31 | 1.1.0   | 7     | Discover (search any place: photos and nine travel info cards) and Wanderbook (share trip photos, follow travellers, like and comment); smoother navigation and photo animations                                                                                       |
| 2026-11-07 | 1.2.0   | 8     | Book: flight search with recent prices (Aviasales), hotel and car rental partners opened with your dates, airport and city suggestions while typing                                                                                                                    |
| 2026-11-08 | 1.3.0   | 9     | AI trip planner: day-by-day plans from any destination or saved place, cost estimate, booking shortcuts, change a day, share by link                                                                                                                                   |
| 2026-11-09 | 1.4.0   | 10    | Notifications: a bell on Home with an unread count; push for new followers, likes, comments, trip reminders and opened shared plans; notification settings with a switch per type                                                                                      |
| 2026-11-10 | 1.5.0   | 11    | Me: edit name, photo, password, email, country and currency; recently viewed; delete account. 7 languages (en, hi, es, fr, de, ar, ja) and prices in your currency; accessibility (contrast, 48dp buttons, labels) and faster start                                    |
| 2026-11-10 | 1.5.0   | 12    | Updated crash reporting (Sentry) and usage statistics (PostHog) libraries                                                                                                                                                                                              |
| 2026-11-14 | 1.5.0   | 13    | Privacy, Terms, Delete my data and shared trip plans open on goawaygo.com (staging.goawaygo.com is gone); crash reports go to production                                                                                                                               |

Add a row for every Android build.
