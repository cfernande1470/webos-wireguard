#!/bin/sh
set -eu

APPID="com.github.cfernande1470.wireguard"
DST="/var/lib/webosbrew/wireguard"
INIT_FILE="/var/lib/webosbrew/init.d/90-wireguard"

find_appdir() {
  for d in \
    "/media/developer/apps/usr/palm/applications/$APPID" \
    "/media/cryptofs/apps/usr/palm/applications/$APPID" \
    "/media/internal/apps/usr/palm/applications/$APPID"
  do
    if [ -d "$d/payload/wireguard" ]; then
      echo "$d"
      return 0
    fi
  done

  find /media -type d -path "*/applications/$APPID" 2>/dev/null | head -1
}

APPDIR="$(find_appdir)"
SRC="$APPDIR/payload/wireguard"

echo "== preparing WireGuard state =="
echo "APPDIR=$APPDIR"
echo "SRC=$SRC"
echo "DST=$DST"

echo
echo "== payload contents =="
find "$SRC" -maxdepth 4 -type f -print 2>/dev/null || true

echo
echo "== checking binaries =="
for f in wg wireguard-go wg-upload; do
  if [ ! -x "$SRC/bin/$f" ]; then
    echo "ERROR: missing executable $SRC/bin/$f"
    exit 1
  fi
done

echo
echo "== checking scripts =="
for f in start.sh stop.sh status.sh upload-start.sh upload-stop.sh autostart.sh boot.sh uninstall.sh; do
  if [ ! -x "$SRC/scripts/$f" ]; then
    echo "ERROR: missing executable $SRC/scripts/$f"
    exit 1
  fi
done

mkdir -p "$DST" "$DST/conf" "$DST/run" "$DST/uploads"
chmod 700 "$DST/conf" "$DST/uploads"

AUTOSTART_WAS_ENABLED=0
if [ -e "$INIT_FILE" ] || [ -L "$INIT_FILE" ]; then
  AUTOSTART_WAS_ENABLED=1
fi

echo
echo "== stopping old runtime before migrating =="
if [ -x "$DST/scripts/stop.sh" ]; then
  sh "$DST/scripts/stop.sh" 2>&1 || true
fi

killall wireguard-go 2>/dev/null || true
killall wg-upload 2>/dev/null || true
rm -f "$DST/run/wg-upload.pid"
rm -f /var/run/wireguard/wg0.sock
sleep 1

echo
echo "== linking packaged components =="
rm -rf "$DST/bin" "$DST/scripts"
ln -s "$SRC/bin" "$DST/bin"
ln -s "$SRC/scripts" "$DST/scripts"
echo "bin -> $SRC/bin"
echo "scripts -> $SRC/scripts"

echo
echo "== preparing configuration =="
if [ ! -f "$DST/conf/wg0.conf" ]; then
  cat >"$DST/conf/wg0.conf" <<'EOS'
[Interface]
PrivateKey = REPLACE_THIS_KEY
Address = 10.0.0.2/32
ListenPort = 51820

[Peer]
PublicKey = REPLACE_SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = example.com:51820
PersistentKeepalive = 25
EOS
  chmod 600 "$DST/conf/wg0.conf"
  echo "Created sample wg0.conf. Upload your real configuration from the app."
else
  echo "Keeping existing wg0.conf"
fi

if [ ! -f "$DST/conf/address" ]; then
  awk '
    BEGIN { section="" }
    /^[[:space:]]*\[/ { section=tolower($0) }
    section ~ /^\[interface\]/ && /^[[:space:]]*[Aa][Dd][Dd][Rr][Ee][Ss][Ss][[:space:]]*=/ {
      sub(/^[^=]*=/, "")
      gsub(/^[ \t]+|[ \t]+$/, "")
      print
      exit
    }
  ' "$DST/conf/wg0.conf" > "$DST/conf/address" 2>/dev/null || true

  if [ ! -s "$DST/conf/address" ]; then
    echo "10.0.0.2/32" > "$DST/conf/address"
  fi

  chmod 600 "$DST/conf/address"
  echo "Created sample address"
else
  echo "Keeping existing address"
fi

echo
echo "== packaged binary versions =="
"$SRC/bin/wg" --version 2>&1 || true
"$SRC/bin/wireguard-go" --version 2>&1 || true

if [ "$AUTOSTART_WAS_ENABLED" -eq 1 ]; then
  echo
  echo "== migrating autostart hook =="
  "$SRC/scripts/autostart.sh" enable
fi

echo
echo "OK: state prepared and packaged components linked"
