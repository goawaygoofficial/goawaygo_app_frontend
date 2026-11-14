#!/usr/bin/env bash
# Creates the Android upload key that signs GoAwayGo release builds (see README.md, Android releases). Run once.
#
#   Usage:  bash scripts/create-upload-key.sh
#   Needs:  keytool (part of the JDK), openssl (Git Bash has it).
#
# Writes, outside the repository:
#   ~/.goawaygo/goawaygo-upload.jks              the keystore (private key)
# and android/key.properties (gitignored) pointing at it, with a random password.
# Prints only the certificate's SHA-1 / SHA-256 fingerprints, which are public.
#
# BACK UP ~/.goawaygo/ and android/key.properties (password manager or an encrypted drive). Lose them and you can't
# sign updates with this key; with Google Play App Signing the upload key can be reset, but only through Google.
set -euo pipefail

cd "$(dirname "$0")/.."
KEY_DIR="$HOME/.goawaygo"
KEYSTORE="$KEY_DIR/goawaygo-upload.jks"
PROPS="android/key.properties"
ALIAS=upload

if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "An upload key already exists ($KEYSTORE or $PROPS). Not overwriting it." >&2
  exit 1
fi
command -v keytool >/dev/null || { echo "keytool not found: install JDK 17 or add its bin folder to PATH." >&2; exit 1; }

mkdir -p "$KEY_DIR"
# PKCS12 keystores use one password for the store and the key.
GOAWAYGO_KEY_PASSWORD="$(openssl rand -base64 30 | tr '+/' '-_' | tr -d '=')"
export GOAWAYGO_KEY_PASSWORD

keytool -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=GoAwayGo, O=GoAwayGo, C=IN" \
  -storepass:env GOAWAYGO_KEY_PASSWORD -keypass:env GOAWAYGO_KEY_PASSWORD >/dev/null 2>&1

# Forward slashes work in Gradle on Windows too.
store_path="$(cd "$KEY_DIR" && pwd -W 2>/dev/null || pwd)/goawaygo-upload.jks"
umask 077
cat >"$PROPS" <<EOF
# Upload key for release builds (scripts/create-upload-key.sh). NEVER commit or share this file.
storeFile=${store_path}
storePassword=${GOAWAYGO_KEY_PASSWORD}
keyAlias=${ALIAS}
keyPassword=${GOAWAYGO_KEY_PASSWORD}
EOF
unset GOAWAYGO_KEY_PASSWORD

echo "Upload key created:"
echo "  keystore:   $KEYSTORE"
echo "  properties: $PROPS (gitignored)"
echo
echo "Public fingerprints (needed for Google Sign-In and Firebase):"
grep_password="$(sed -n 's/^storePassword=//p' "$PROPS")"
GOAWAYGO_KEY_PASSWORD="$grep_password" keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env GOAWAYGO_KEY_PASSWORD 2>/dev/null | grep -E "SHA1:|SHA256:" | sed 's/^[[:space:]]*/  /'
echo
echo "Back up $KEY_DIR and $PROPS now (password manager / encrypted drive)."
