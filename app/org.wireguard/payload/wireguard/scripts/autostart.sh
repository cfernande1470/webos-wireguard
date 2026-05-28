#!/bin/sh
set -eu

BASE="/var/lib/webosbrew/wireguard"
INIT_DIR="/var/lib/webosbrew/init.d"
INIT_FILE="$INIT_DIR/90-wireguard"

case "${1:-status}" in
  enable)
    mkdir -p "$INIT_DIR"

    cat >"$INIT_FILE" <<'EOS'
#!/bin/sh
(
  # Fast startup: start WireGuard as soon as a default route exists.
  # Wait up to 20s, checking every 1s.
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    if ip route show default | grep -q default; then
      break
    fi
    sleep 1
  done

  /var/lib/webosbrew/wireguard/scripts/start.sh \
    >/var/lib/webosbrew/wireguard/run/autostart.log 2>&1
) &
exit 0
EOS

    chmod +x "$INIT_FILE"
    echo "Autostart: enabled"
    ;;

  disable)
    rm -f "$INIT_FILE"
    echo "Autostart: disabled"
    ;;

  status)
    if [ -x "$INIT_FILE" ]; then
      echo "Autostart: enabled"
    else
      echo "Autostart: disabled"
    fi
    exit 0
    ;;

  *)
    echo "Usage: $0 enable|disable|status"
    exit 2
    ;;
esac
