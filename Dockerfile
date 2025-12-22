FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color
ENV TZ=Asia/Ho_Chi_Minh

# ====== CÀI GÓI ======
RUN apt update && apt install -y \
    curl wget nano htop tmux bash ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

# ====== CÀI TTYD ======
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    -O /usr/bin/ttyd && chmod +x /usr/bin/ttyd

# ====== THƯ MỤC LƯU SESSION (PERSIST) ======
RUN mkdir -p /data/tmux
ENV TMUX_TMPDIR=/data/tmux

# ====== CSS + AWS FAKE DASHBOARD ======
RUN cat <<'EOF' > /style.css
/* ===== AUTO LIGHT / DARK THEO GIỜ VN ===== */
:root {
  --bg-light: #f4f6f8;
  --bg-dark: #0f172a;
  --glass-light: rgba(255,255,255,0.65);
  --glass-dark: rgba(15,23,42,0.7);
}

html, body {
  margin: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  font-family: Inter, system-ui, Arial, sans-serif;
  background: var(--bg-light);
  transition: background 1.5s ease;
}

/* dark mode tự động */
body.dark {
  background: var(--bg-dark);
}

/* Ẩn UI ttyd gốc */
.header,.toolbar,.footer,.title { display:none!important }

/* ===== AWS STYLE TERMINAL ===== */
.xterm {
  margin-top: 48px;
  background: var(--glass-light) !important;
  backdrop-filter: blur(18px) saturate(160%);
  -webkit-backdrop-filter: blur(18px) saturate(160%);
  border-radius: 12px;
  padding: 14px;
  box-shadow: 0 20px 40px rgba(0,0,0,.15);
}

body.dark .xterm {
  background: var(--glass-dark) !important;
  color: #cbd5e1 !important;
}

/* ===== FAKE AWS DASHBOARD TOP BAR ===== */
#awsbar {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 42px;
  background: linear-gradient(90deg,#232f3e,#1b2635);
  color: #fff;
  display: flex;
  align-items: center;
  padding: 0 14px;
  font-size: 13px;
  z-index: 9999;
}

#awsbar span {
  margin-right: 18px;
  opacity: 0.9;
}

#awsbar b {
  color: #ff9900;
}
EOF

# ====== JS AUTO DARK MODE THEO GIỜ VN ======
RUN cat <<'EOF' > /inject.js
(function () {
  const hour = new Date().getHours(); // giờ VN do TZ
  if (hour >= 18 || hour < 6) {
    document.body.classList.add("dark");
  }

  const bar = document.createElement("div");
  bar.id = "awsbar";
  bar.innerHTML = `
    <span><b>AWS</b> CloudShell</span>
    <span>Region: ap-southeast-1</span>
    <span>Session: shared</span>
    <span>Status: Running</span>
  `;
  document.body.appendChild(bar);
})();
EOF

# ====== START SCRIPT ======
RUN cat <<'EOF' > /start.sh
#!/bin/bash
echo "☁️ AWS-Style CloudShell booting (shared session)..."

# ---- TMUX SESSION LƯU LÂU DÀI ----
if ! tmux has-session -t cloud 2>/dev/null; then
  tmux new-session -d -s cloud bash
fi

# ---- CHẠY TTYD (1 PHIÊN CHUNG) ----
ttyd \
  --port 10000 \
  --interface 0.0.0.0 \
  --writable \
  --client-option theme=light \
  --client-option fontSize=14 \
  --client-option rendererType=canvas \
  --client-option customCSS=/style.css \
  --client-option customJS=/inject.js \
  tmux attach -t cloud
EOF

RUN chmod +x /start.sh

# ====== VOLUME LƯU SESSION ======
VOLUME ["/data"]

EXPOSE 10000
CMD ["/start.sh"]
