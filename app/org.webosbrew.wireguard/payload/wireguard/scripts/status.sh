#!/bin/sh

BASE="/var/lib/webosbrew/wireguard"
WG="$BASE/bin/wg"
IFACE="wg0"

echo "== process =="
ps | grep wireguard-go | grep -v grep || true

echo
echo "== interface =="
ip addr show "$IFACE" 2>/dev/null || echo "$IFACE does not exist"

echo
echo "== WireGuard =="
"$WG" show "$IFACE" 2>/dev/null || true

echo
echo "== wg0 routes =="
ip route | grep "$IFACE" || true

echo
echo "== log =="
tail -40 "$BASE/run/wireguard-go.log" 2>/dev/null || true
