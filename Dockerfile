FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

ENV HOME=/config \
    WINEPREFIX=/config/comicrack/wineprefix \
    WINEARCH=win32 \
    PROTON_HOME=/opt/proton-ge \
    DISPLAY=:1 \
    GST_PLUGIN_SYSTEM_PATH_1_0=/opt/proton-ge/dist/lib/gstreamer-1.0:/opt/proton-ge/dist/lib64/gstreamer-1.0 \
    PATH=/opt/proton-ge/dist/bin:/opt/proton-ge/dist/bin32:$PATH \
    LD_LIBRARY_PATH=/opt/proton-ge/dist/lib64:/opt/proton-ge/dist/lib:/opt/proton-ge/dist/lib64/wine:/opt/proton-ge/dist/lib/wine:$LD_LIBRARY_PATH \
    DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | tee /etc/apt/keyrings/winehq-archive.key >/dev/null && \
    curl -fsSL https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources -o /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https gnupg ca-certificates \
        curl wget jq unzip tar cabextract \
        python3 python3-distutils \
        winehq-stable \
        libfaudio0 pulseaudio libpulse0 \
        gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-pulseaudio \
        gstreamer1.0-alsa \
        gamescope \
        libgl1 libglx-mesa0 libvulkan1 mesa-vulkan-drivers \
        dbus-x11 x11-apps x11-utils x11-xserver-utils \
        xdg-utils rsync && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p /opt/proton-ge /opt/comicrack /opt/scripts; \
    PROTON_URL=$(curl -fsSL https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
        | jq -r '.assets[] | select(.browser_download_url | endswith(".tar.gz")) | .browser_download_url' | head -n1); \
    curl -fsSL "$PROTON_URL" | tar -xzf - -C /opt/proton-ge --strip-components=1

RUN set -eux; \
    COMICRACK_URL=$(curl -fsSL https://api.github.com/repos/maforget/ComicRackCE/releases/latest \
        | jq -r '.assets[] | select(.browser_download_url | test("ComicRackCE_v[0-9]+\\.[0-9]+\\.[0-9]+\\.zip$")) | .browser_download_url' | head -n1); \
    curl -fsSL "$COMICRACK_URL" -o /tmp/comicrack.zip; \
    unzip -q /tmp/comicrack.zip -d /opt/comicrack; \
    rm -f /tmp/comicrack.zip

COPY root/ /
COPY Docker/start.sh /opt/scripts/start.sh
RUN chmod +x /opt/scripts/start.sh /root/defaults/autostart

EXPOSE 3000 3001 8080
