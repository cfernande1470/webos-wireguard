#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
INIT_FILE="/var/lib/webosbrew/init.d/90-wireguard"
SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"
HERE="$(CDPATH= cd -- "$(dirname -- "$SELF")" && pwd)"

cleanup_stale_state() {
  echo "WireGuard payload is missing; removing stale runtime and private configuration"
  killall wireguard-go 2>/dev/null || true
  killall wg-upload 2>/dev/null || true
  ip link del wg0 2>/dev/null || true
  rm -f /var/run/wireguard/wg0.sock
  rm -f "$INIT_FILE"
  rm -rf "$BASE"
}

if [ ! -x "$HERE/start.sh" ] || [ ! -x "$HERE/../bin/wg" ] || [ ! -x "$HERE/../bin/wireguard-go" ]; then
  cleanup_stale_state
  exit 0
fi

mkdir -p "$BASE/run"

(
  # Some TVs restore networking late after a cold boot. Wait up to 60 seconds.
  i=0
  while [ "$i" -lt 60 ]; do
    if ip route show default | grep -q default; then
      break
    fi
    sleep 1
    i=$((i + 1))
  done

  if ! ip route show default | grep -q default; then
    echo "ERROR: no default route after 60 seconds"
    exit 1
  fi

  "$HERE/start.sh"
) >"$BASE/run/autostart.log" 2>&1 &

exit 0
