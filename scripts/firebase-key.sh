#!/usr/bin/env bash
# Saves the Firebase Android API key that release builds need for push notifications in ~/.goawaygo/firebase.env
# (next to the upload key), without showing it. Run once per PC, signed in to gcloud as a Firebase project member:
#
#   bash scripts/firebase-key.sh
#
# The key identifies the app to Firebase and ships inside every APK; it is kept out of git so secret scanning stays
# clean. scripts/release-android.sh passes it to the build.
set -euo pipefail

PROJECT=goaway-483709
APP_ID=1:1018541563002:android:6330e2e35a5248e8a02fc3
PACKAGE=com.goawaygo.app
OUT="$HOME/.goawaygo/firebase.env"

token="$(gcloud auth print-access-token)"
config="$(curl -sSf -H "Authorization: Bearer $token" -H "x-goog-user-project: $PROJECT" \
  "https://firebase.googleapis.com/v1beta1/projects/$PROJECT/androidApps/$APP_ID/config")"
key="$(printf '%s' "$config" | python -c '
import base64, json, sys
files = json.loads(base64.b64decode(json.load(sys.stdin)["configFileContents"]))
client = next(c for c in files["client"] if c["client_info"]["android_client_info"]["package_name"] == sys.argv[1])
print(client["api_key"][0]["current_key"])
' "$PACKAGE")"
[[ -n "$key" ]] || { echo "No API key in the Firebase config" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
umask 077
printf 'FIREBASE_ANDROID_API_KEY=%s\n' "$key" > "$OUT"
echo "Saved the Firebase key to $OUT (not shown). Release builds now include push notifications."
