FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Cài gói cần thiết
RUN apt update && apt install -y \
    curl \
    wget \
    git \
    nano \
    htop \
    tmux \
    tmate \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Cài ttyd (web terminal)
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    -O /usr/bin/ttyd && chmod +x /usr/bin/ttyd

# Thêm CSS nền cầu vồng
RUN mkdir -p /opt/ttyd
COPY style.css /opt/ttyd/style.css

# Script start
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 10000

CMD ["/start.sh"]
