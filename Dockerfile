FROM ghcr.io/linuxserver/baseimage-selkies:arch

ENV HOME=/config \
    WINEPREFIX=/config/comicrack/wineprefix \
    WINEARCH=win32 \
    PIXELFLUX_WAYLAND=true \
    WAYLAND_DISPLAY=wayland-1 \
    DISPLAY=:1 \
    GST_PLUGIN_SYSTEM_PATH_1_0=/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0

RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    python3 -c 'from pathlib import Path; import re; p=Path("/etc/pacman.conf"); s=p.read_text(); s=re.sub(r"^#\\[(multilib)\\]$", r"[\\1]", s, flags=re.M); s=re.sub(r"^#Include = /etc/pacman.d/mirrorlist$", "Include = /etc/pacman.d/mirrorlist", s, flags=re.M); p.write_text(s)' && \
    pacman -Syyu --noconfirm && \
    pacman -S --noconfirm \
        ca-certificates curl wget jq unzip tar cabextract \
        python \
        wine \
        libpulse lib32-libpulse \
        gstreamer \
        gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
        gst-libav \
        libglvnd mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader \
        xorg-xset xdg-utils rsync \
        gamescope && \
    pacman -Scc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

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
