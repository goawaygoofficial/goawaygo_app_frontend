#!/usr/bin/env bash
# Runs inside the emulator step of tests.yml (MVP 2, 5.5/5.6): installs the test build, runs the app flows (AT), then the
# start-up and scrolling limits (PT, not in prod or smoke runs). Each result is written to reports/<at|pt>.result
# (success or failure) for the workflow to record; the script itself never stops early, so every report is kept.
set -uo pipefail

mkdir -p reports
adb install -r build/app/outputs/flutter-apk/app-release.apk

if OUT="$PWD/reports" bash at/app/run.sh; then echo success > reports/at.result; else echo failure > reports/at.result; fi

if [ "${SCOPE:-full}" = full ] && [ "$GOAWAYGO_ENV" != prod ]; then
  pt=success
  OUT="$PWD/reports" bash pt/app/startup.sh || pt=failure
  OUT="$PWD/reports" bash pt/app/scroll.sh || pt=failure
  echo "$pt" > reports/pt.result
fi
exit 0
