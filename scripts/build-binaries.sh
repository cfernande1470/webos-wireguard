#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP="$ROOT/app/com.github.cfernande1470.wireguard"
BIN="$APP/payload/wireguard/bin"

command -v go >/dev/null 2>&1 || {
  echo "ERROR: Go is required" >&2
  exit 1
}
command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1 || {
  echo "ERROR: arm-linux-gnueabihf-gcc is required" >&2
  exit 1
}

mkdir -p "$BIN"

echo "== building wg-upload for linux/armv7 =="
(
  cd "$ROOT/uploader"
  GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 \
    go build -trimpath -ldflags="-s -w" -o "$BIN/wg-upload" ./wg-upload.go
)

echo "== building wireguard-go for linux/armv7 =="
(
  cd "$ROOT/wireguard-go"
  GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 \
    go build -trimpath -ldflags="-s -w" -o "$BIN/wireguard-go" .
)

echo "== building static wg for linux/armv7 =="
(
  cd "$ROOT/wireguard-tools/src"
  make clean
  make -j2 \
    CC=arm-linux-gnueabihf-gcc \
    CFLAGS="-O3 -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard -isystem uapi/linux -std=gnu99 -D_GNU_SOURCE -Wall -Wextra -DRUNSTATEDIR=\\\"/var/run\\\"" \
    LDFLAGS="-static"
  cp wg "$BIN/wg"
)

chmod 755 "$BIN/wg" "$BIN/wireguard-go" "$BIN/wg-upload"
file "$BIN/wg" "$BIN/wireguard-go" "$BIN/wg-upload"
