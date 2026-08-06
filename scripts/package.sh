#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP_ID="com.github.cfernande1470.wireguard"
VERSION="1.0.1"
APP="$ROOT/app/$APP_ID"
DIST="$ROOT/dist"
WORK="$(mktemp -d)"

cleanup() {
  rm -rf "$WORK"
}
trap cleanup EXIT HUP INT TERM

DATA="$WORK/data"
CONTROL="$WORK/control"
APP_DST="$DATA/usr/palm/applications/$APP_ID"
PACKAGE_DST="$DATA/usr/palm/packages/$APP_ID"

mkdir -p "$APP_DST" "$PACKAGE_DST" "$CONTROL" "$DIST"
cp -R "$APP/." "$APP_DST/"

cat > "$PACKAGE_DST/packageinfo.json" <<EOF
{
  "id": "$APP_ID",
  "version": "$VERSION",
  "app": "$APP_ID"
}
EOF

INSTALLED_SIZE="$(du -sb "$DATA" | awk '{print $1}')"
cat > "$CONTROL/control" <<EOF
Package: $APP_ID
Version: $VERSION
Section: misc
Priority: optional
Architecture: all
Installed-Size: $INSTALLED_SIZE
Maintainer: cfernande1470
Description: WireGuard client for rooted LG webOS with Homebrew Channel.
webOS-Package-Format-Version: 2
webOS-Packager-Version: webos-wireguard
EOF

rm -f "$DIST/${APP_ID}_${VERSION}_all.ipk"
printf '2.0\n' > "$WORK/debian-binary"
tar -C "$CONTROL" -czf "$WORK/control.tar.gz" control
tar -C "$DATA" -czf "$WORK/data.tar.gz" usr
(
  cd "$WORK"
  ar crD "$DIST/${APP_ID}_${VERSION}_all.ipk" debian-binary control.tar.gz data.tar.gz
)
cp "$ROOT/$APP_ID.manifest.json" "$DIST/$APP_ID.manifest.json"

echo "Created $DIST/${APP_ID}_${VERSION}_all.ipk"
echo "Created $DIST/$APP_ID.manifest.json"
