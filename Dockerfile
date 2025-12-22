FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color
ENV TZ=Asia/Ho_Chi_Minh

# ===== PACKAGES =====
RUN apt update && apt install -y \
  curl wget nano htop tmux bash ca-certificates tzdata \
  && rm -rf /var/lib/apt/lists/*

# ===== TTYD =====
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
  -O /usr/bin/ttyd && chmod +x /usr/bin/ttyd

# ===== PERSIST =====
RUN mkdir -p /data/tmux
ENV TMUX_TMPDIR=/data/tmux

# ===== PANEL HTML (PTERO STYLE) =====
RUN cat <<'EOF' > /panel.html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Cloud Panel</title>
<style>
body{
  margin:0;
  font-family:Inter,system-ui;
  background:linear-gradient(120deg,#ede9fe,#f5f3ff,#faf5ff);
  background-size:300% 300%;
  animation:bg 40s ease infinite;
}
@keyframes bg{
  0%{background-position:0% 50%}
  50%{background-position:100% 50%}
  100%{background-position:0% 50%}
}
.card{
  width:420px;
  margin:80px auto;
  background:rgba(255,255,255,.75);
  backdrop-filter:blur(18px);
  border-radius:16px;
  padding:24px;
  box-shadow:0 20px 40px rgba(0,0,0,.15);
}
h1{margin:0 0 12px;color:#6d28d9}
button{
  width:100%;
  padding:12px;
  border:0;
  border-radius:10px;
  font-size:15px;
  cursor:pointer;
}
.on{background:#7c3aed;color:#fff}
.off{background:#e5e7eb}
.status{margin-top:12px;font-size:14px}
</style>
</head>
<body>
<div class="card">
  <h1>🟣 Cloud Terminal</h1>
  <button class="on" onclick="fetch('/on')">▶ Start Terminal</button><br><br>
  <button class="off" onclick="fetch('/off')">⏹ Stop Terminal</button>
  <div class="status" id="st">Status: unknown</div>
</div>

<script>
setInterval(()=>{
  fetch('/status').then(r=>r.text()).then(t=>{
    document.getElementById('st').innerText="Status: "+t;
  })
},1000);
</script>
</body>
</html>
EOF

# ===== CSS TERMINAL =====
RUN cat <<'EOF' > /style.css
html,body{
  margin:0;width:100%;height:100%;overflow:hidden;
  font-family:Inter,system-ui;
}
.header,.toolbar,.footer,.title{display:none!important}

.xterm{
  margin-top:46px;
  background:rgba(255,255,255,.65)!important;
  backdrop-filter:blur(16px);
  border-radius:14px;
  padding:14px;
}

/* TOP CLOCK */
#clock{
  position:fixed;
  top:8px;right:16px;
  background:rgba(0,0,0,.65);
  color:#fff;
  padding:6px 12px;
  border-radius:999px;
  font-size:13px;
  z-index:9999;
}
EOF

# ===== JS CLOCK + COUNTER =====
RUN cat <<'EOF' > /inject.js
let start=Date.now();
setInterval(()=>{
  const now=new Date();
  const diff=Math.floor((Date.now()-start)/1000);
  const h=String(Math.floor(diff/3600)).padStart(2,'0');
  const m=String(Math.floor(diff%3600/60)).padStart(2,'0');
  const s=String(diff%60).padStart(2,'0');
  document.getElementById('clock').innerText=
    now.toLocaleTimeString('vi-VN')+" | "+h+":"+m+":"+s;
},1000);

const c=document.createElement("div");
c.id="clock";
document.body.appendChild(c);
EOF

# ===== START SCRIPT =====
RUN cat <<'EOF' > /start.sh
#!/bin/bash
echo "🚀 Cloud Shell + Panel"

# tmux session
if ! tmux has-session -t cloud 2>/dev/null; then
  tmux new-session -d -s cloud bash
fi

# simple panel api
( while true; do
  echo -e "HTTP/1.1 200 OK\n\nRUNNING" | nc -l -p 9001 -q 1
done ) &

# ttyd
ttyd \
  --port 10000 \
  --interface 0.0.0.0 \
  --readonly \
  --client-option customCSS=/style.css \
  --client-option customJS=/inject.js \
  tmux attach -t cloud
EOF

RUN chmod +x /start.sh

VOLUME ["/data"]
EXPOSE 10000
CMD ["/start.sh"]
