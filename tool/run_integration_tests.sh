#!/usr/bin/env bash
set -euo pipefail

# Percorso al binario Flutter (override con FLUTTER_BIN se serve)
FLUTTER_BIN_DEFAULT="/Users/andreea/StudioProjects/development/flutter_honoo/bin/flutter"
FLUTTER_BIN="${FLUTTER_BIN:-$FLUTTER_BIN_DEFAULT}"

DRIVER="integration_test/driver/device_driver.dart"
TARGET="${1:-integration_test/app_boot_placeholder_test.dart}"

# Lista dispositivi/selettori (override con INTEGRATION_DEVICES="macos chrome" ecc.)
DEVICES="${INTEGRATION_DEVICES:-chrome}"

for device in $DEVICES; do
  echo "==> flutter drive -d $device ($TARGET)"
  "$FLUTTER_BIN" drive \
    --driver "$DRIVER" \
    --target "$TARGET" \
    -d "$device"
  echo ""
 done
