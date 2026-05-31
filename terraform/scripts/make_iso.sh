#!/bin/bash
set -e

CI_DIR="$1"
ISO_PATH="$2"
HOSTNAME="$3"

echo "==> Creating cloud-init ISO for $HOSTNAME..."

mkdir -p "$CI_DIR"

cat > "$CI_DIR/meta-data" << EOF
instance-id: $HOSTNAME
local-hostname: $HOSTNAME
EOF

genisoimage \
  -output "$ISO_PATH" \
  -volid cidata \
  -joliet \
  -rock \
  "$CI_DIR/user-data" \
  "$CI_DIR/meta-data"

echo "==> ISO created: $ISO_PATH"