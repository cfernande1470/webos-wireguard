#!/bin/sh
set -eu

APPID="org.webosbrew.wireguard"
DST="/var/lib/webosbrew/wireguard"

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

copy_exec() {
  src="$1"
  dst="$2"
  tmp="${dst}.new.$$"

  rm -f "$tmp"
  cp "$src" "$tmp"
  chmod 755 "$tmp"
  mv -f "$tmp" "$dst"
}

copy_file() {
  src="$1"
  dst="$2"
  tmp="${dst}.new.$$"

  rm -f "$tmp"
  cp "$src" "$tmp"
  mv -f "$tmp" "$dst"
}

APPDIR="$(find_appdir)"
SRC="$APPDIR/payload/wireguard"

echo "== installing/updating WireGuard components =="
echo "APPDIR=$APPDIR"
echo "SRC=$SRC"
echo "DST=$DST"

echo
echo "== payload contents =="
find "$SRC" -maxdepth 4 -type f -print 2>/dev/null || true

echo
echo "== checking binaries =="
for f in wg wireguard-go wg-upload; do
  if [ ! -f "$SRC/bin/$f" ]; then
    echo "ERROR: missing $SRC/bin/$f"
    exit 1
  fi
done

echo
echo "== checking scripts =="
for f in start.sh stop.sh status.sh upload-start.sh upload-stop.sh autostart.sh uninstall.sh; do
  if [ ! -f "$SRC/scripts/$f" ]; then
    echo "ERROR: missing $SRC/scripts/$f"
    exit 1
  fi
done

mkdir -p "$DST/bin" "$DST/scripts" "$DST/conf" "$DST/run" "$DST/uploads"
chmod 700 "$DST/conf"
chmod 700 "$DST/uploads"

echo
echo "== stopping old runtime before replacing binaries =="
if [ -x "$DST/scripts/stop.sh" ]; then
  sh "$DST/scripts/stop.sh" 2>&1 || true
fi

killall wireguard-go 2>/dev/null || true
killall wg-upload 2>/dev/null || true
rm -f "$DST/run/wg-upload.pid"
rm -f /var/run/wireguard/wg0.sock
sleep 1

echo
echo "== copying binaries =="
copy_exec "$SRC/bin/wg" "$DST/bin/wg"
copy_exec "$SRC/bin/wireguard-go" "$DST/bin/wireguard-go"
copy_exec "$SRC/bin/wg-upload" "$DST/bin/wg-upload"

echo
echo "== copying scripts =="
for f in "$SRC/scripts/"*.sh; do
  name="$(basename "$f")"
  copy_exec "$f" "$DST/scripts/$name"
done

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
echo "== installed binary versions =="
"$DST/bin/wg" --version 2>&1 || true
"$DST/bin/wireguard-go" --version 2>&1 || true

echo
echo "OK: components installed/updated"
