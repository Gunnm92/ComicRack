# ============================================================================
# Base Image
# ============================================================================
FROM linuxserver/webtop:ubuntu-mate

# ============================================================================
# Environment Variables
# ============================================================================
ENV HOME=/config \
    WINEPREFIX=/config/.wine \
    WINEARCH=win64

# ============================================================================
# System Dependencies Installation
# ============================================================================
RUN set -eux; \
    # Add i386 architecture for Wine 32-bit support
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        # Build essentials
        ca-certificates \
        curl \
        wget \
        jq \
        gnupg \
        software-properties-common \
        # Archive tools (zip, rar, 7z, etc)
        unzip \
        zip \
        p7zip-full \
        p7zip-rar \
        unrar \
        tar \
        cabextract \
        # PDF tools
        poppler-utils \
        # Image tools
        imagemagick \
        # File manager with archive support
        engrampa \
        # Python for extraction script
        python3 \
        python3-pip \
        # Wine 32-bit libraries
        libc6:i386 \
        libgcc-s1:i386 \
        libstdc++6:i386 && \
    # Clean up
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# Wine 11 Installation from WineHQ
# ============================================================================
RUN set -eux; \
    # Add WineHQ repository key
    mkdir -pm755 /etc/apt/keyrings; \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key; \
    # Add WineHQ repository
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources; \
    # Update and install Wine 11 (stable)
    apt-get update; \
    apt-get install -y --install-recommends winehq-stable; \
    # Clean up
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# Winetricks Installation (latest version)
# ============================================================================
RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -o /usr/local/bin/winetricks; \
    chmod +x /usr/local/bin/winetricks

# ============================================================================
# ComicRack Installation
# ============================================================================
COPY ressources/extract_comicrack.py /tmp/extract_comicrack.py

RUN set -eux; \
    mkdir -p /opt/comicrack /opt/scripts; \
    # Download latest ComicRack CE from GitHub
    COMICRACK_URL=$(curl -fsSL https://api.github.com/repos/maforget/ComicRackCE/releases/latest \
        | jq -r '.assets[] | select(.browser_download_url | test("ComicRackCE_v[0-9]+\\.[0-9]+\\.[0-9]+\\.zip$")) | .browser_download_url' \
        | head -n1); \
    curl -fsSL "$COMICRACK_URL" -o /tmp/comicrack.zip; \
    # Extract ComicRack
    python3 /tmp/extract_comicrack.py; \
    # Clean up
    rm -f /tmp/comicrack.zip /tmp/extract_comicrack.py

# ============================================================================
# Application Scripts and Desktop Files
# ============================================================================
COPY ressources/start.sh /opt/scripts/start.sh
COPY ressources/init_wine.sh /etc/cont-init.d/97-init-wine
COPY ressources/configure_mate.sh /etc/cont-init.d/98-configure-mate
COPY ressources/ComicRack.desktop /etc/cont-init.d/99-setup-desktop-icon.sh

# Setup permissions and create desktop icon script
RUN set -eux; \
    chmod +x /opt/scripts/start.sh \
             /etc/cont-init.d/97-init-wine \
             /etc/cont-init.d/98-configure-mate; \
    # Transform desktop file into setup script
    { \
        echo '#!/bin/bash'; \
        echo 'mkdir -p /config/Desktop'; \
        echo 'cat > "/config/Desktop/ComicRack Community Edition.desktop" << '\''DESKTOP_EOF'\'''; \
        cat /etc/cont-init.d/99-setup-desktop-icon.sh; \
        echo 'DESKTOP_EOF'; \
        echo 'chmod +x "/config/Desktop/ComicRack Community Edition.desktop"'; \
        echo 'chown abc:abc "/config/Desktop/ComicRack Community Edition.desktop"'; \
    } > /tmp/desktop-setup.sh; \
    mv /tmp/desktop-setup.sh /etc/cont-init.d/99-setup-desktop-icon.sh; \
    chmod +x /etc/cont-init.d/99-setup-desktop-icon.sh

# ============================================================================
# Ports
# ============================================================================
EXPOSE 3000 3001
