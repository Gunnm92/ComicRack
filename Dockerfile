FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

ENV HOME=/config \
    WINEPREFIX=/config/comicrack/wineprefix \
    WINEARCH=win32 \
    PIXELFLUX_WAYLAND=true \
    WAYLAND_DISPLAY=wayland-1 \
    DISPLAY=:1 \
    GST_PLUGIN_SYSTEM_PATH_1_0=/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0 \
    DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | tee /etc/apt/keyrings/winehq-archive.key >/dev/null && \
    curl -fsSL https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources -o /etc/apt/sources.list.d/winehq.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https gnupg ca-certificates \
        curl wget jq unzip tar cabextract \
        python3 \
        winehq-stable \
        libfaudio0 pulseaudio libpulse0 \
        gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-pulseaudio \
        gstreamer1.0-alsa \
        libgl1 libglx-mesa0 libvulkan1 mesa-vulkan-drivers \
        dbus-x11 x11-apps x11-utils x11-xserver-utils \
        xdg-utils rsync \
        gamescope && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p /opt/comicrack /opt/scripts; \
    COMICRACK_URL=$(curl -fsSL https://api.github.com/repos/maforget/ComicRackCE/releases/latest \
        | jq -r '.assets[] | select(.browser_download_url | test("ComicRackCE_v[0-9]+\\.[0-9]+\\.[0-9]+\\.zip$")) | .browser_download_url' | head -n1); \
    curl -fsSL "$COMICRACK_URL" -o /tmp/comicrack.zip; \
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/comicrack.zip').extractall('/opt/comicrack')"; \
    rm -f /tmp/comicrack.zip

COPY root/ /root/
COPY ressources/start.sh /opt/scripts/start.sh
RUN chmod +x /opt/scripts/start.sh /root/defaults/autostart

EXPOSE 3000 3001
