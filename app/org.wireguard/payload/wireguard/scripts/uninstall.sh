#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"

echo "== stopping VPN =="
"$BASE/scripts/stop.sh" 2>/dev/null || true

echo "== stopping processes =="
killall wireguard-go 2>/dev/null || true
killall wg-upload 2>/dev/null || true

echo "== cleaning interface and routes =="
ip link del wg0 2>/dev/null || true
ip route del 0.0.0.0/1 dev wg0 2>/dev/null || true
ip route del 128.0.0.0/1 dev wg0 2>/dev/null || true

echo "== removing autostart =="
rm -f /var/lib/webosbrew/init.d/90-wireguard

echo "== removing sockets =="
rm -f /var/run/wireguard/wg0.sock
rm -f /var/run/wireguard/--help.sock

echo "== removing runtime data =="
rm -rf "$BASE"

echo
echo "OK: WireGuard runtime removed"
echo "You can now uninstall the app."
