#!/bin/bash

echo "☁️ Cloud Shell booting..."

# tmate SSH
tmate -F &
sleep 2

echo "🔐 TMATE SESSION:"
tmate show-messages || true
echo ""

# ttyd không UI, full screen
ttyd \
  --port 10000 \
  --interface 0.0.0.0 \
  --index /opt/ttyd/index.html \
  --writable \
  bash
