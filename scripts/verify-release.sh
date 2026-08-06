#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP_ID="com.github.cfernande1470.wireguard"
VERSION="1.0.1"
APP="$ROOT/app/$APP_ID"
IPK="$ROOT/dist/${APP_ID}_${VERSION}_all.ipk"
MANIFEST="$ROOT/dist/$APP_ID.manifest.json"

test -f "$IPK" || { echo "ERROR: missing $IPK" >&2; exit 1; }
test -f "$MANIFEST" || { echo "ERROR: missing $MANIFEST" >&2; exit 1; }

if grep -R -n -E 'org\.webosbrew\.wireguard|org\.wireguard' \
  "$APP" "$ROOT/README.md" "$ROOT/$APP_ID.manifest.json"; then
  echo "ERROR: stale package id found" >&2
  exit 1
fi

for binary in wg wireguard-go wg-upload; do
  description="$(file "$APP/payload/wireguard/bin/$binary")"
  echo "$description"
  echo "$description" | grep -q 'ELF 32-bit LSB.*ARM' || {
    echo "ERROR: $binary is not a 32-bit ARM ELF" >&2
    exit 1
  }
done

CONTROL="$(ar p "$IPK" control.tar.gz | tar xzO control)"
echo "$CONTROL" | grep -qx "Package: $APP_ID"
echo "$CONTROL" | grep -qx "Version: $VERSION"
echo "$CONTROL" | grep -qx 'Architecture: all'

ar p "$IPK" data.tar.gz | tar tzf - | grep -q "^usr/palm/applications/$APP_ID/appinfo.json$"
ar p "$IPK" data.tar.gz | tar tzf - | grep -q "^usr/palm/packages/$APP_ID/packageinfo.json$"
ar p "$IPK" data.tar.gz | tar xzO "usr/palm/applications/$APP_ID/appinfo.json" | grep -q "\"id\": \"$APP_ID\""
grep -q "\"id\": \"$APP_ID\"" "$MANIFEST"
grep -q "${APP_ID}_${VERSION}_all.ipk" "$MANIFEST"

echo "Release verification passed for $APP_ID $VERSION"
