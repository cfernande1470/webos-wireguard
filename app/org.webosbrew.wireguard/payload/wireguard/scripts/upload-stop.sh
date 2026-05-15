#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
PIDFILE="$BASE/run/wg-upload.pid"

kill "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null || true
killall wg-upload 2>/dev/null || true
rm -f "$PIDFILE"

echo "OK: upload server stopped"
