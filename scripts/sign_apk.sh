#!/usr/bin/env bash
# Align + sign the HackerLife Android APK (debug keystore, side-load ready).
# Usage: ./sign_apk.sh <in.apk> <out.apk>
# Requires: Android build-tools (zipalign, apksigner) + a keystore.
set -euo pipefail

IN="${1:?input apk}"
OUT="${2:?output apk}"
BT="${BUILD_TOOLS:?set BUILD_TOOLS to the Android build-tools dir}"
KS="${KEYSTORE:?set KEYSTORE to the .keystore file}"
KS_USER="${KS_USER:-androiddebugkey}"
KS_PASS="${KS_PASS:-android}"

echo "== zipalign =="
ALIGNED="${OUT}.aligned.tmp"
"$BT/zipalign" -f -p 4 "$IN" "$ALIGNED"

echo "== apksigner sign =="
"$BT/apksigner" sign \
  --ks "$KS" \
  --ks-key-alias "$KS_USER" \
  --ks-pass "pass:$KS_PASS" \
  --key-pass "pass:$KS_PASS" \
  --out "$OUT" \
  "$ALIGNED"
rm -f "$ALIGNED"

echo "== verify =="
"$BT/apksigner" verify --verbose "$OUT" | head -10
echo "== done: $OUT =="
