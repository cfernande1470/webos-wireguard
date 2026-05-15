#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
BIN="$BASE/bin/wg-upload"
RUN="$BASE/run"
PIDFILE="$RUN/wg-upload.pid"
LOGFILE="$RUN/wg-upload.log"
TOKENFILE="$RUN/wg-upload-token"
URLFILE="$RUN/wg-upload-url"

mkdir -p "$RUN"

[ -x "$BIN" ] || { echo "ERROR: does not exist $BIN"; exit 1; }

kill "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null || true
killall wg-upload 2>/dev/null || true

RAW="$(
  {
    date +%s 2>/dev/null
    cat /proc/uptime 2>/dev/null
    ps 2>/dev/null
  } | sha256sum | awk '{print $1}'
)"

TOKEN="$(echo "$RAW" | tr -cd '0-9' | cut -c1-4)"

if [ ${#TOKEN} -lt 4 ]; then
  TOKEN="$(date +%s | awk '{printf "%04d", $1 % 10000}')"
fi

echo "$TOKEN" > "$TOKENFILE"
chmod 600 "$TOKENFILE"

DEFAULT_DEV="$(
  ip route show default 2>/dev/null \
    | awk '$1 == "default" && $0 !~ / dev wg0 / {
        for (i = 1; i <= NF; i++) {
          if ($i == "dev") {
            print $(i + 1)
            exit
          }
        }
      }'
)"

IP=""

if [ -n "$DEFAULT_DEV" ]; then
  IP="$(
    ip addr show dev "$DEFAULT_DEV" 2>/dev/null \
      | sed -n 's/.*inet \([^/]*\).*/\1/p' \
      | head -1
  )"
fi

if [ -z "$IP" ]; then
  IP="$(
    ip addr show 2>/dev/null \
      | awk '
          /^[0-9]+: / {
            dev=$2
            sub(/:.*/, "", dev)
          }
          /^[[:space:]]*inet / && dev != "wg0" && $2 !~ /^127\./ {
            ip=$2
            sub(/\/.*/, "", ip)
            print ip
            exit
          }
        '
  )"
fi

if [ -z "$IP" ]; then
  echo "ERROR: cannot detect the LAN IP for the upload server"
  ip addr show 2>/dev/null || true
  exit 1
fi

echo "http://$IP:8088" > "$URLFILE"

WG_UPLOAD_TOKEN="$TOKEN" "$BIN" >"$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"

echo "Upload server started"
echo
echo "URL: http://$IP:8088"
echo "PIN: $TOKEN"
echo
echo "Open that URL from your computer, enter the PIN and upload wg0.conf."
