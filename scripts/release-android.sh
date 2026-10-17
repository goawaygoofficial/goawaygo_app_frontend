#!/usr/bin/env bash
# Builds a staging Android release and publishes it for direct download (docs/release-android.md).
#
#   Usage:  bash scripts/release-android.sh <version> <build-number> "<release notes>" [--upload]
#   e.g.    bash scripts/release-android.sh 1.0.0 3 "Wanderbook photos, bug fixes" --upload
#
# Builds, signed with the upload key (android/key.properties; refuses to run without it):
#   build/release/goaway-<version>-<build>-arm64.apk       64-bit phones (nearly all), smaller
#   build/release/goaway-<version>-<build>-universal.apk   every phone; also the file for Firebase App Distribution
#   build/release/latest.json                              what the website's /download page reads
# With --upload, puts them in the Cloudflare R2 bucket behind https://downloads.goawaygo.com (APKs first, then
# latest.json, so the website never points at a file that isn't there yet). Needs `npx wrangler login` once.
set -euo pipefail

VERSION="${1:?Usage: release-android.sh <version> <build-number> \"<notes>\" [--upload]}"
BUILD="${2:?Usage: release-android.sh <version> <build-number> \"<notes>\" [--upload]}"
NOTES="${3:-}"
UPLOAD="${4:-}"
ENV_FILE=env/staging.env
BUCKET=goaway-downloads
BASE_URL=https://downloads.goawaygo.com/android
WRANGLER="npx --yes wrangler@4.145.0"

cd "$(dirname "$0")/.."
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Version must look like 1.2.3" >&2; exit 1; }
[[ "$BUILD" =~ ^[0-9]+$ ]] || { echo "Build number must be a whole number" >&2; exit 1; }
[[ -f android/key.properties ]] || {
  echo "android/key.properties not found: run scripts/create-upload-key.sh first (never publish debug-signed builds)." >&2
  exit 1
}

OUT=build/release
mkdir -p "$OUT"
NAME="goaway-${VERSION}-${BUILD}"
common=(--release "--dart-define=ENV_FILE=$ENV_FILE" "--build-name=$VERSION" "--build-number=$BUILD")

echo "==> Building $NAME (64-bit phones)"
# --target-platform without --split-per-abi: only the 64-bit native code, and the plain build number as Android's
# version code. (--split-per-abi would make it 2000 + build, and phones with that installed would refuse every
# later universal or Firebase build as a "downgrade".)
flutter build apk "${common[@]}" --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk "$OUT/$NAME-arm64.apk"

echo "==> Building $NAME (all phones)"
flutter build apk "${common[@]}"
cp build/app/outputs/flutter-apk/app-release.apk "$OUT/$NAME-universal.apk"

file_json() { # path -> {"url":..,"size":..,"sha256":..}
  local path="$1" name size sha
  name="$(basename "$path")"
  size="$(wc -c <"$path" | tr -d ' ')"
  sha="$(sha256sum "$path" | cut -d' ' -f1)"
  printf '{"url": "%s/%s", "size": %s, "sha256": "%s"}' "$BASE_URL" "$name" "$size" "$sha"
}

# JSON-escape the notes (quotes and backslashes); keep them on one line.
notes_json="$(printf '%s' "$NOTES" | tr '\n' ' ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
cat >"$OUT/latest.json" <<EOF
{
  "version": "$VERSION",
  "build": $BUILD,
  "date": "$(date -u +%Y-%m-%d)",
  "notes": "$notes_json",
  "files": {
    "arm64": $(file_json "$OUT/$NAME-arm64.apk"),
    "universal": $(file_json "$OUT/$NAME-universal.apk")
  }
}
EOF

echo "==> Built:"
ls -l "$OUT/$NAME-arm64.apk" "$OUT/$NAME-universal.apk" "$OUT/latest.json" | awk '{print "    " $5 "\t" $NF}'

if [[ "$UPLOAD" == "--upload" ]]; then
  echo "==> Uploading to R2 bucket $BUCKET"
  for apk in "$OUT/$NAME-arm64.apk" "$OUT/$NAME-universal.apk"; do
    $WRANGLER r2 object put "$BUCKET/android/$(basename "$apk")" --file "$apk" --remote \
      --content-type application/vnd.android.package-archive --cache-control "public, max-age=31536000, immutable"
  done
  $WRANGLER r2 object put "$BUCKET/android/latest.json" --file "$OUT/latest.json" --remote \
    --content-type application/json --cache-control "no-cache"
  echo "==> Live: https://staging.goawaygo.com/download"
else
  echo "Not uploaded (add --upload to publish)."
fi
echo "For Firebase App Distribution, upload: $OUT/$NAME-universal.apk"
