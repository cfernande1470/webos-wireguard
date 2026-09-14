#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
WG="$HERE/../bin/wg"
WGGO="$HERE/../bin/wireguard-go"
IFACE="wg0"

CONF="$BASE/conf/wg0.conf"
ADDRESS_FILE="$BASE/conf/address"
ROUTES_EXTRA_FILE="$BASE/conf/routes-extra"

RUN="$BASE/run"
PIDFILE="$RUN/wireguard-go.pid"
LOGFILE="$RUN/wireguard-go.log"
GWFILE="$RUN/original-gateway"
DEVFILE="$RUN/original-dev"
ENDPOINTS_FILE="$RUN/endpoint-routes"
APPLIED_ROUTES_FILE="$RUN/applied-routes"
SETCONF_FILE="$RUN/wg0.setconf"
IPV6_STATE_FILE="$RUN/original-ipv6-disabled"
OPERATION_LOCK="$RUN/operation.lock"
START_OK=0

mkdir -p "$RUN" /var/run/wireguard

acquire_operation_lock() {
  if mkdir "$OPERATION_LOCK" 2>/dev/null; then
    echo "$$" > "$OPERATION_LOCK/pid"
    return 0
  fi

  lock_pid="$(cat "$OPERATION_LOCK/pid" 2>/dev/null || true)"
  if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
    echo "ERROR: another WireGuard start/stop operation is running (PID $lock_pid)"
    exit 1
  fi

  rm -rf "$OPERATION_LOCK"
  mkdir "$OPERATION_LOCK"
  echo "$$" > "$OPERATION_LOCK/pid"
}

restore_ipv6_after_failed_start() {
  [ "$START_OK" -eq 0 ] || return 0
  [ -f "$DEVFILE" ] && [ -f "$IPV6_STATE_FILE" ] || return 0

  restore_dev="$(cat "$DEVFILE")"
  restore_value="$(cat "$IPV6_STATE_FILE")"
  if [ -n "$restore_dev" ] && [ -n "$restore_value" ]; then
    sysctl -w "net.ipv6.conf.$restore_dev.disable_ipv6=$restore_value" >/dev/null 2>&1 || true
  fi
  rm -f "$IPV6_STATE_FILE"
}

release_operation_lock() {
  rc=$?
  restore_ipv6_after_failed_start
  rm -rf "$OPERATION_LOCK"
  exit "$rc"
}

acquire_operation_lock
trap release_operation_lock EXIT HUP INT TERM

[ -x "$WG" ] || { echo "ERROR: does not exist $WG"; exit 1; }
[ -x "$WGGO" ] || { echo "ERROR: does not exist $WGGO"; exit 1; }
[ -f "$CONF" ] || { echo "ERROR: missing $CONF"; exit 1; }

trim() {
  echo "$1" | sed 's/\r$//;s/[[:space:]]*#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//'
}

lower() {
  echo "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'
}

get_key() {
  echo "$1" | sed 's/[[:space:]]*=.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

get_value() {
  echo "$1" | sed 's/^[^=]*=//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

extract_addresses_from_conf() {
  section=""
  found=""

  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(trim "$raw")"
    [ -z "$line" ] && continue

    case "$line" in
      \[*\])
        section="$(lower "$line")"
        continue
        ;;
    esac

    if [ "$section" = "[interface]" ]; then
      case "$line" in
        *=*)
          key="$(lower "$(get_key "$line")")"
          if [ "$key" = "address" ]; then
            value="$(get_value "$line")"
            echo "$value" | tr ',' '\n' | while read -r addr; do
              addr="$(trim "$addr")"
              [ -n "$addr" ] && echo "$addr"
            done > "$ADDRESS_FILE.tmp"
            found="1"
            break
          fi
          ;;
      esac
    fi
  done < "$CONF"

  if [ -f "$ADDRESS_FILE.tmp" ]; then
    mv -f "$ADDRESS_FILE.tmp" "$ADDRESS_FILE"
    chmod 600 "$ADDRESS_FILE"
    echo "Address detected in wg0.conf:"
    cat "$ADDRESS_FILE"
  fi
}

extract_mtu_from_conf() {
  section=""
  mtu=""

  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(trim "$raw")"
    [ -z "$line" ] && continue

    case "$line" in
      \[*\])
        section="$(lower "$line")"
        continue
        ;;
    esac

    if [ "$section" = "[interface]" ]; then
      case "$line" in
        *=*)
          key="$(lower "$(get_key "$line")")"
          if [ "$key" = "mtu" ]; then
            mtu="$(get_value "$line")"
            break
          fi
          ;;
      esac
    fi
  done < "$CONF"

  case "$mtu" in
    ""|*[!0-9]*)
      mtu="1420"
      ;;
  esac

  echo "$mtu"
}

make_wg_setconf_file() {
  section=""
  : > "$SETCONF_FILE"

  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(trim "$raw")"

    [ -z "$line" ] && continue

    case "$line" in
      \[*\])
        section="$(lower "$line")"
        echo "$line" >> "$SETCONF_FILE"
        continue
        ;;
    esac

    if [ "$section" = "[interface]" ]; then
      case "$line" in
        *=*)
          key="$(lower "$(get_key "$line")")"

          case "$key" in
            address|dns|mtu|table|preup|postup|predown|postdown|saveconfig)
              continue
              ;;
          esac
          ;;
      esac
    fi

    echo "$line" >> "$SETCONF_FILE"
  done < "$CONF"
}

add_route() {
  route="$1"

  case "$route" in
    ""|\#*) return ;;
  esac

  case "$route" in
    *:*)
      echo "WARNING: IPv6 route ignored for now: $route"
      return
      ;;
  esac

  if [ "$route" = "0.0.0.0/0" ]; then
    add_route "0.0.0.0/1"
    add_route "128.0.0.0/1"
    return
  fi

  if ! grep -qx "$route" "$APPLIED_ROUTES_FILE" 2>/dev/null; then
    echo "$route" >> "$APPLIED_ROUTES_FILE"
  fi
}

echo "== detecting original default route =="
DEFAULT_LINE="$(ip route show default | grep -v " dev $IFACE " | head -1 || true)"

ORIG_GW="$(echo "$DEFAULT_LINE" | sed -n 's/.*default via \([^ ]*\).*/\1/p')"
ORIG_DEV="$(echo "$DEFAULT_LINE" | sed -n 's/.* dev \([^ ]*\).*/\1/p')"

if [ -n "${ORIG_DEV:-}" ]; then
  echo "$ORIG_DEV" > "$DEVFILE"
  [ -n "${ORIG_GW:-}" ] && echo "$ORIG_GW" > "$GWFILE" || : > "$GWFILE"

  if [ -n "${ORIG_GW:-}" ]; then
    echo "original default: via $ORIG_GW dev $ORIG_DEV"
  else
    echo "original default: dev $ORIG_DEV"
  fi
else
  echo "WARNING: cannot find original default route outside $IFACE"
fi

echo "== preparing configuration =="
extract_addresses_from_conf

[ -f "$ADDRESS_FILE" ] || {
  echo "ERROR: missing Address. Add Address = x.x.x.x/xx to wg0.conf or create $ADDRESS_FILE"
  exit 1
}

MTU="$(extract_mtu_from_conf)"
echo "MTU: $MTU"

make_wg_setconf_file

if [ -n "${ORIG_DEV:-}" ]; then
  echo "== disabling IPv6 on $ORIG_DEV to prevent leaks outside the tunnel =="
  if [ -f "$IPV6_STATE_FILE" ]; then
    echo "Keeping previously saved IPv6 state"
  else
    CUR_DISABLE_V6="$(sysctl -n "net.ipv6.conf.$ORIG_DEV.disable_ipv6" 2>/dev/null || true)"
    if [ -n "$CUR_DISABLE_V6" ]; then
      echo "$CUR_DISABLE_V6" > "$IPV6_STATE_FILE"
    else
      echo "WARNING: could not read IPv6 state for $ORIG_DEV, leaving it untouched"
    fi
  fi

  if [ -f "$IPV6_STATE_FILE" ]; then
    if ! sysctl -w "net.ipv6.conf.$ORIG_DEV.disable_ipv6=1" >/dev/null 2>&1; then
      echo "WARNING: could not disable IPv6 on $ORIG_DEV"
      rm -f "$IPV6_STATE_FILE"
    fi
  fi
fi

echo
echo "== generated wg setconf file =="
sed -E 's#^(PrivateKey[[:space:]]*=[[:space:]]*).*#\1REDACTED#;s#^(PresharedKey[[:space:]]*=[[:space:]]*).*#\1REDACTED#' "$SETCONF_FILE"

echo "== previous cleanup =="
killall wireguard-go 2>/dev/null || true
ip link del "$IFACE" 2>/dev/null || true
rm -f "/var/run/wireguard/$IFACE.sock"

echo "== starting wireguard-go =="
# Keep the daemon in foreground mode under this shell's background job so $!
# remains the real long-lived PID instead of the short-lived launcher PID.
LOG_LEVEL=info "$WGGO" -f "$IFACE" >"$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"

sleep 2

if ! ip link show "$IFACE" >/dev/null 2>&1; then
  echo "ERROR: interface was not created: $IFACE"
  cat "$LOGFILE" 2>/dev/null || true
  exit 1
fi

echo "== applying WireGuard configuration =="
"$WG" setconf "$IFACE" "$SETCONF_FILE"

echo "== pinning endpoint routes outside the tunnel =="
: > "$ENDPOINTS_FILE"

if [ -n "${ORIG_DEV:-}" ]; then
  "$WG" show "$IFACE" endpoints | while read -r peer endpoint; do
    [ -z "$endpoint" ] && continue
    [ "$endpoint" = "(none)" ] && continue

    host="$(echo "$endpoint" | sed 's/:.*$//')"

    case "$host" in
      ""|0.0.0.0|*:*) continue ;;
    esac

    if [ -n "${ORIG_GW:-}" ]; then
      echo "endpoint $host via $ORIG_GW dev $ORIG_DEV"
      ip route replace "$host" via "$ORIG_GW" dev "$ORIG_DEV"
    else
      echo "endpoint $host dev $ORIG_DEV"
      ip route replace "$host" dev "$ORIG_DEV"
    fi

    echo "$host" >> "$ENDPOINTS_FILE"
  done
fi

echo "== assigning IP address =="
while IFS= read -r addr || [ -n "$addr" ]; do
  addr="$(trim "$addr")"
  [ -z "$addr" ] && continue

  case "$addr" in
    *:*)
      echo "WARNING: IPv6 Address ignored for now: $addr"
      continue
      ;;
  esac

  echo "addr: $addr dev $IFACE"
  ip addr add "$addr" dev "$IFACE" 2>/dev/null || true
done < "$ADDRESS_FILE"

ip link set mtu "$MTU" up dev "$IFACE"

echo "== generating routes from AllowedIPs =="
: > "$APPLIED_ROUTES_FILE"

grep -i '^[[:space:]]*AllowedIPs[[:space:]]*=' "$CONF" \
  | sed 's/^[^=]*=//' \
  | tr ',' '\n' \
  | sed 's/[[:space:]]*#.*$//;s/^[[:space:]]*//;s/[[:space:]]*$//' \
  | while read -r route; do
      add_route "$route"
    done

if [ -f "$ROUTES_EXTRA_FILE" ]; then
  echo "== adding extra routes =="
  while IFS= read -r route || [ -n "$route" ]; do
    route="$(trim "$route")"
    add_route "$route"
  done < "$ROUTES_EXTRA_FILE"
fi

echo "== applying routes =="
while IFS= read -r route || [ -n "$route" ]; do
  [ -z "$route" ] && continue
  echo "route: $route dev $IFACE"
  ip route replace "$route" dev "$IFACE"
done < "$APPLIED_ROUTES_FILE"

echo "== status =="
"$WG" show "$IFACE"
ip addr show "$IFACE"

echo
echo "== relevant routes =="
ip route | grep -E "$IFACE|default" || ip route

echo
echo "OK: WireGuard started"
START_OK=1
