FROM ubuntu:24.04

LABEL maintainer="comicrack@example.com"

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=C.UTF-8
ENV WINEPREFIX=/root/.comicrack
ENV WINEARCH=win32
ENV PROTON_HOME=/opt/proton-ge
ENV PATH=$PROTON_HOME/dist/bin:$PROTON_HOME/dist/bin32:$PATH
ENV LD_LIBRARY_PATH=$PROTON_HOME/dist/lib64:$PROTON_HOME/dist/lib:$PROTON_HOME/dist/lib64/wine:$PROTON_HOME/dist/lib/wine:$LD_LIBRARY_PATH
ENV GST_PLUGIN_SYSTEM_PATH_1_0=$PROTON_HOME/dist/lib/gstreamer-1.0:$PROTON_HOME/dist/lib64/gstreamer-1.0
ENV DISPLAY=:0

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget jq unzip tar cabextract \
        supervisor xvfb x11vnc x11-utils dbus-x11 \
        xfce4 xfce4-panel xfce4-terminal \
        gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-pulseaudio \
        gstreamer1.0-alsa pulseaudio libpulse0 \
        libgl1 libgl1-mesa-glx libglx-mesa0 libvulkan1 mesa-vulkan-drivers \
        libfaudio0 libfaudio0:i386 libgssapi-krb5-2 python3 \
        dbus-x11 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/proton-ge /opt/comicrack /opt/scripts /opt/novnc/utils && \
    NO_VNC_TAG=v1.6.0 && \
    curl -fsSL https://github.com/novnc/noVNC/archive/refs/tags/${NO_VNC_TAG}.tar.gz | \
        tar -xz -C /opt && \
    mv /opt/noVNC-${NO_VNC_TAG#v} /opt/novnc && \
    WEB_TAG=v0.13.0 && \
    curl -fsSL https://github.com/novnc/websockify/archive/refs/tags/${WEB_TAG}.tar.gz | \
        tar -xz -C /opt && \
    mv /opt/websockify-${WEB_TAG#v} /opt/novnc/utils/websockify

RUN set -eux; \
    PROTON_URL=$(curl -fsSL https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | \
        jq -r '.assets[] | select(.browser_download_url | endswith(".tar.gz")) | .browser_download_url' | head -n1); \
    curl -fsSL "$PROTON_URL" | tar -xzf - -C /opt/proton-ge --strip-components=1

RUN set -eux; \
    COMICRACK_URL=$(curl -fsSL https://api.github.com/repos/maforget/ComicRackCE/releases/latest | \
        jq -r '.assets[] | select(.browser_download_url | test("ComicRackCE_v[0-9]+\.[0-9]+\.[0-9]+\.zip$")) | .browser_download_url' | head -n1); \
    curl -fsSL "$COMICRACK_URL" -o /tmp/comicrack.zip; \
    unzip /tmp/comicrack.zip -d /opt/comicrack; \
    rm -f /tmp/comicrack.zip

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /opt/scripts/start.sh
RUN chmod +x /opt/scripts/start.sh

EXPOSE 8080 5900
WORKDIR /root
ENTRYPOINT ["/opt/scripts/start.sh"]
