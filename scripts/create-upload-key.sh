#!/usr/bin/env bash
# Creates the Android upload key that signs Goaway release builds (see docs/release-android.md). Run once.
#
#   Usage:  bash scripts/create-upload-key.sh
#   Needs:  keytool (part of the JDK), openssl (Git Bash has it).
#
# Writes, outside the repository:
#   ~/.goaway/goaway-upload.jks              the keystore (private key)
# and android/key.properties (gitignored) pointing at it, with a random password.
# Prints only the certificate's SHA-1 / SHA-256 fingerprints, which are public.
#
# BACK UP ~/.goaway/ and android/key.properties (password manager or an encrypted drive). Lose them and you can't
# sign updates with this key; with Google Play App Signing the upload key can be reset, but only through Google.
set -euo pipefail

cd "$(dirname "$0")/.."
KEY_DIR="$HOME/.goaway"
KEYSTORE="$KEY_DIR/goaway-upload.jks"
PROPS="android/key.properties"
ALIAS=upload

if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "An upload key already exists ($KEYSTORE or $PROPS). Not overwriting it." >&2
  exit 1
fi
command -v keytool >/dev/null || { echo "keytool not found: install JDK 17 or add its bin folder to PATH." >&2; exit 1; }

mkdir -p "$KEY_DIR"
# PKCS12 keystores use one password for the store and the key.
GOAWAY_KEY_PASSWORD="$(openssl rand -base64 30 | tr '+/' '-_' | tr -d '=')"
export GOAWAY_KEY_PASSWORD

keytool -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Goaway, O=Goaway, C=IN" \
  -storepass:env GOAWAY_KEY_PASSWORD -keypass:env GOAWAY_KEY_PASSWORD >/dev/null 2>&1

# Forward slashes work in Gradle on Windows too.
store_path="$(cd "$KEY_DIR" && pwd -W 2>/dev/null || pwd)/goaway-upload.jks"
umask 077
cat >"$PROPS" <<EOF
# Upload key for release builds (scripts/create-upload-key.sh). NEVER commit or share this file.
storeFile=${store_path}
storePassword=${GOAWAY_KEY_PASSWORD}
keyAlias=${ALIAS}
keyPassword=${GOAWAY_KEY_PASSWORD}
EOF
unset GOAWAY_KEY_PASSWORD

echo "Upload key created:"
echo "  keystore:   $KEYSTORE"
echo "  properties: $PROPS (gitignored)"
echo
echo "Public fingerprints (needed for Google Sign-In and Firebase):"
grep_password="$(sed -n 's/^storePassword=//p' "$PROPS")"
GOAWAY_KEY_PASSWORD="$grep_password" keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env GOAWAY_KEY_PASSWORD 2>/dev/null | grep -E "SHA1:|SHA256:" | sed 's/^[[:space:]]*/  /'
echo
echo "Back up $KEY_DIR and $PROPS now (password manager / encrypted drive)."
