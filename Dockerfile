FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# ====== CÀI GÓI CẦN THIẾT ======
RUN apt update && apt install -y \
    curl wget nano htop tmux bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ====== CÀI TTYD ======
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    -O /usr/bin/ttyd && chmod +x /usr/bin/ttyd

# ====== CSS GLASS macOS ======
RUN cat <<'EOF' > /style.css
html, body {
  margin: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;

  /* macOS light gradient */
  background: linear-gradient(
    135deg,
    #fdfbfb,
    #ebedee,
    #dfe9f3,
    #fdfbfb
  );

  background-size: 400% 400%;
  animation: macFlow 80s ease-in-out infinite;
}

/* chuyển màu rất nhẹ */
@keyframes macFlow {
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

/* Glass trắng kiểu macOS */
.xterm {
  background: rgba(255, 255, 255, 0.55) !important;
  backdrop-filter: blur(18px) saturate(160%);
  -webkit-backdrop-filter: blur(18px) saturate(160%);
  border-radius: 16px;
  padding: 14px;
  box-shadow:
    0 20px 40px rgba(0,0,0,0.12),
    inset 0 1px 0 rgba(255,255,255,0.6);
}

/* chữ terminal rõ trên nền sáng */
.xterm-screen {
  color: #1e1e1e !important;
}
EOF

# ====== START SCRIPT ======
RUN cat <<'EOF' > /start.sh
#!/bin/bash
echo "🧊 macOS Glass Cloud Shell booting..."

# tạo tmux session duy nhất (không reset cmd)
if ! tmux has-session -t cloud 2>/dev/null; then
  tmux new-session -d -s cloud bash
fi

# chạy ttyd attach vào tmux
ttyd \
  --port 10000 \
  --interface 0.0.0.0 \
  --writable \
  --client-option theme=light \
  --client-option fontSize=14 \
  --client-option rendererType=canvas \
  tmux attach -t cloud
EOF

RUN chmod +x /start.sh

EXPOSE 10000
CMD ["/start.sh"]
