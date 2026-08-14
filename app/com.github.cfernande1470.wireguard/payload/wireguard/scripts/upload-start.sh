#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BIN="$HERE/../bin/wg-upload"
RUN="$BASE/run"
PIDFILE="$RUN/wg-upload.pid"
LOGFILE="$RUN/wg-upload.log"
TOKENFILE="$RUN/wg-upload-token"
URLFILE="$RUN/wg-upload-url"

mkdir -p "$RUN"

[ -x "$BIN" ] || { echo "ERROR: does not exist $BIN"; exit 1; }

kill "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null || true
killall wg-upload 2>/dev/null || true
rm -f "$TOKENFILE"

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

WG_UPLOAD_TOKEN_FILE="$TOKENFILE" WG_UPLOAD_TIMEOUT=600 "$BIN" >"$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"

i=0
while [ ! -s "$TOKENFILE" ] && [ "$i" -lt 10 ]; do
  if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "ERROR: upload server stopped before creating its access code"
    cat "$LOGFILE" 2>/dev/null || true
    exit 1
  fi
  sleep 1
  i=$((i + 1))
done

[ -s "$TOKENFILE" ] || { echo "ERROR: timed out waiting for the upload access code"; exit 1; }
TOKEN="$(cat "$TOKENFILE")"
if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "ERROR: upload server stopped during startup"
  cat "$LOGFILE" 2>/dev/null || true
  exit 1
fi

echo "Upload server started"
echo
echo "URL: http://$IP:8088"
echo "CODE: $TOKEN"
echo "The server stops after 10 minutes, five wrong codes, or one successful upload."
echo
echo "Open that URL from your computer, enter the access code and upload wg0.conf."
