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
    # Arch has no "community" repo anymore; only enable multilib (needed for lib32-* packages). \
    python3 -c 'import pathlib; p=pathlib.Path("/etc/pacman.conf"); lines=p.read_text().splitlines(True); out=[]; in_m=False; found=False; \
for l in lines: \
  s=l.strip(); \
  if s in ("[multilib]","#[multilib]"): in_m=True; found=True; out.append("[multilib]\\n"); continue; \
  if in_m and s.startswith("[") and s not in ("[multilib]","#[multilib]"): in_m=False; \
  if in_m and l.lstrip().startswith("#Include = /etc/pacman.d/mirrorlist"): out.append("Include = /etc/pacman.d/mirrorlist\\n"); continue; \
  out.append(l); \
if not found: out.append("\\n[multilib]\\nInclude = /etc/pacman.d/mirrorlist\\n"); \
p.write_text("".join(out))' && \
    pacman -Syyu --noconfirm && \
    pacman -Sl multilib >/dev/null 2>&1 && \
    pacman -S --noconfirm --needed \
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
