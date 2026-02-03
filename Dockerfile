FROM ghcr.io/linuxserver/baseimage-selkies:arch

ENV HOME=/config \
    WINEPREFIX=/config/comicrack/wineprefix \
    WINEARCH=win32 \
    PIXELFLUX_WAYLAND=true \
    WAYLAND_DISPLAY=wayland-1 \
    DISPLAY=:1 \
    GST_PLUGIN_SYSTEM_PATH_1_0=/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0

RUN set -eux; \
    pacman-key --init; \
    pacman-key --populate archlinux; \
    \
    # Arch: the old [community] repo was merged into [extra]. Some images still ship a pacman.conf with [community]. \
    # If [community] is present, pacman sync fails with 404s, so we remove only that block. \
    perl -0777 -i -pe 's/\\n\\[community\\]\\n(?:[^\\n]*\\n)*?(?=\\n\\[|\\z)//s' /etc/pacman.conf; \
    \
    pacman -Syyu --noconfirm; \
    \
    # Keep this minimal: only what we need to run ComicRack in a Wayland session. \
    pacman -S --noconfirm --needed gamescope wine ca-certificates curl jq unzip; \
    pacman -Scc --noconfirm; \
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
