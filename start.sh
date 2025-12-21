#!/bin/bash

echo "🚀 Container started"

# Khởi động tmate (SSH)
tmate -F &
sleep 2

# Chạy web terminal
ttyd \
  --port 10000 \
  --index /opt/ttyd/style.css \
  bash
