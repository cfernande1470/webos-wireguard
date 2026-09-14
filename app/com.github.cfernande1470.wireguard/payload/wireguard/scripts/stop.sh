#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
IFACE="wg0"

PIDFILE="$BASE/run/wireguard-go.pid"
ENDPOINTS_FILE="$BASE/run/endpoint-routes"
APPLIED_ROUTES_FILE="$BASE/run/applied-routes"
GWFILE="$BASE/run/original-gateway"
DEVFILE="$BASE/run/original-dev"
IPV6_STATE_FILE="$BASE/run/original-ipv6-disabled"

echo "== deleting applied WireGuard routes =="
if [ -f "$APPLIED_ROUTES_FILE" ]; then
  while read -r route; do
    [ -n "$route" ] && ip route del "$route" dev "$IFACE" 2>/dev/null || true
  done < "$APPLIED_ROUTES_FILE"
  rm -f "$APPLIED_ROUTES_FILE"
fi

echo "== deleting endpoint routes =="
if [ -f "$ENDPOINTS_FILE" ]; then
  while read -r host; do
    [ -n "$host" ] && ip route del "$host" 2>/dev/null || true
  done < "$ENDPOINTS_FILE"
  rm -f "$ENDPOINTS_FILE"
fi

echo "== restoring original default route if needed =="
if [ -f "$GWFILE" ] && [ -f "$DEVFILE" ]; then
  GW="$(cat "$GWFILE")"
  DEV="$(cat "$DEVFILE")"
  if [ -n "$GW" ] && [ -n "$DEV" ]; then
    ip route replace default via "$GW" dev "$DEV" 2>/dev/null || true
  fi
fi

echo "== restoring original IPv6 state =="
if [ -f "$DEVFILE" ] && [ -f "$IPV6_STATE_FILE" ]; then
  DEV="$(cat "$DEVFILE")"
  PREV_DISABLE_V6="$(cat "$IPV6_STATE_FILE")"
  if [ -n "$DEV" ] && [ -n "$PREV_DISABLE_V6" ]; then
    sysctl -w "net.ipv6.conf.$DEV.disable_ipv6=$PREV_DISABLE_V6" >/dev/null 2>&1 || \
      echo "WARNING: could not restore IPv6 state on $DEV"
  fi
  rm -f "$IPV6_STATE_FILE"
fi

echo "== removing interface =="
ip link del "$IFACE" 2>/dev/null || true

echo "== stopping wireguard-go =="
if [ -f "$PIDFILE" ]; then
  kill "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
fi

killall wireguard-go 2>/dev/null || true
rm -f "/var/run/wireguard/$IFACE.sock"

echo "OK: WireGuard stopped"
