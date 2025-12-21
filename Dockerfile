FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ====== CÀI GÓI CẦN THIẾT ======
RUN apt update && apt install -y \
    curl wget nano htop tmux tmate bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ====== CÀI TTYD ======
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    -O /usr/bin/ttyd && chmod +x /usr/bin/ttyd

# ====== CSS CLOUD SHELL (KHÔNG PHÁ JS GỐC) ======
RUN cat <<'EOF' > /style.css
html, body {
  margin: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: linear-gradient(
    120deg,
    #0f0c29,
    #302b63,
    #24243e
  );
  background-size: 300% 300%;
  animation: gradient 25s ease infinite;
}

@keyframes gradient {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

/* Ẩn UI ttyd */
.header,
.toolbar,
.footer,
.title {
  display: none !important;
}

/* Cloud shell glass effect */
.xterm {
  background: rgba(0,0,0,0.6) !important;
  backdrop-filter: blur(6px);
  border-radius: 10px;
  padding: 10px;
}
EOF

# ====== START SCRIPT ======
RUN cat <<'EOF' > /start.sh
#!/bin/bash
echo "☁️ Cloud Shell starting..."

# start tmate SSH
tmate -F &
sleep 2
tmate show-messages || true
echo ""

# start ttyd (FULL SCREEN, KHÔNG UI)
ttyd \
  --port 10000 \
  --interface 0.0.0.0 \
  --writable \
  --client-option theme=dark \
  --client-option fontSize=14 \
  --client-option rendererType=canvas \
  bash
EOF

RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
