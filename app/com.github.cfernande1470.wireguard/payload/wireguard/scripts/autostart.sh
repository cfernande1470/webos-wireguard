#!/bin/sh
set -eu

INIT_DIR="/var/lib/webosbrew/init.d"
INIT_FILE="$INIT_DIR/90-wireguard"
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

case "${1:-status}" in
  enable)
    mkdir -p "$INIT_DIR"
    BOOT="$(readlink -f "$HERE/boot.sh" 2>/dev/null || echo "$HERE/boot.sh")"
    [ -x "$BOOT" ] || { echo "ERROR: missing $BOOT"; exit 1; }
    ln -sfn "$BOOT" "$INIT_FILE"
    echo "Autostart: enabled"
    ;;

  disable)
    rm -f "$INIT_FILE"
    echo "Autostart: disabled"
    ;;

  status)
    if [ -L "$INIT_FILE" ] && [ -x "$INIT_FILE" ]; then
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
