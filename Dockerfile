FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# Mode X11 : Selkies lance svc-xorg (Xvfb) + svc-de (Openbox via startwm.sh).
# Wine se connecte sur DISPLAY=:1 comme sur une machine normale.
ENV HOME=/config \
    WINEPREFIX=/config/.wine \
    WINEARCH=win64 \
    DISPLAY=:1 \
    GST_PLUGIN_SYSTEM_PATH_1_0=/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget jq unzip tar cabextract \
        python3 \
        wine wine64 wine32:i386 winetricks \
        libc6:i386 libgcc-s1:i386 libstdc++6:i386 \
        x11-utils x11-xserver-utils xcursor-themes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG PROTON_GE_VERSION=latest
RUN set -eux; \
    if [ "$PROTON_GE_VERSION" = "latest" ]; then \
      PROTON_GE_API="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"; \
    else \
      PROTON_GE_API="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/tags/${PROTON_GE_VERSION}"; \
    fi; \
    PROTON_GE_URL=$(curl -fsSL "$PROTON_GE_API" | jq -r '.assets[].browser_download_url | select(test("\\.tar\\.gz$"))' | head -n1); \
    if [ -z "$PROTON_GE_URL" ]; then \
      echo "Proton-GE download URL not found for ${PROTON_GE_VERSION}" >&2; \
      exit 1; \
    fi; \
    curl -fsSL "$PROTON_GE_URL" -o /tmp/proton-ge.tar.gz; \
    GE_DIR=$(tar -tzf /tmp/proton-ge.tar.gz 2>/dev/null | head -n1 | cut -d/ -f1 || true); \
    tar -xzf /tmp/proton-ge.tar.gz -C /opt; \
    rm -f /tmp/proton-ge.tar.gz; \
    if [ -z "$GE_DIR" ]; then \
      GE_DIR=$(ls -1 /opt | grep -E '^GE-Proton' | sort | tail -n1); \
    fi; \
    ln -s "/opt/${GE_DIR}" /opt/proton

RUN set -eux; \
    mkdir -p /opt/comicrack /opt/scripts; \
    COMICRACK_URL=$(curl -fsSL https://api.github.com/repos/maforget/ComicRackCE/releases/latest \
        | jq -r '.assets[] | select(.browser_download_url | test("ComicRackCE_v[0-9]+\\.[0-9]+\\.[0-9]+\\.zip$")) | .browser_download_url' | head -n1); \
    curl -fsSL "$COMICRACK_URL" -o /tmp/comicrack.zip; \
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/comicrack.zip').extractall('/opt/comicrack')"; \
    rm -f /tmp/comicrack.zip

# svc-de lit /defaults/ pour startwm.sh et autostart
COPY root/defaults/ /defaults/
COPY ressources/start.sh /opt/scripts/start.sh
RUN chmod +x /opt/scripts/start.sh \
         /defaults/autostart \
         /defaults/startwm.sh

EXPOSE 3000 3001
