#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
HOME=${HOME:-/config}
WINEPREFIX=${WINEPREFIX:-$HOME/.wine}
WINEARCH=win64          # ComicRack CE est 64-bit
DISPLAY=${DISPLAY:-:1}  # Xvfb lancé par Selkies svc-xorg

export HOME WINEPREFIX WINEARCH DISPLAY
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0}

INSTALL_WINETRICKS=${INSTALL_WINETRICKS:-1}
WINETRICKS_PACKAGES=${WINETRICKS_PACKAGES:-dotnet48}
COMIC_ARGS=${COMIC_ARGS:-/opt/comicrack/ComicRack.exe}
WINE_DPI=${WINE_DPI:-150}           # DPI pour les polices Wine (96=par défaut, 150 pour 1280x720)

# ---------------------------------------------------------------------------
# Attendre que X11 soit disponible (Selkies / svc-xorg)
# ---------------------------------------------------------------------------
for i in {1..30}; do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "[start] X server $DISPLAY is up"
    break
  fi
  echo "[start] waiting for X server $DISPLAY (attempt $i/30)..."
  sleep 1
done

# ---------------------------------------------------------------------------
# Préfixe Wine
# ---------------------------------------------------------------------------
mkdir -p "$WINEPREFIX"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  echo "[start] running wineboot --init"
  /usr/bin/wineboot --init || true
fi

# ---------------------------------------------------------------------------
# Winetricks (une seule fois) — dotnet48 par défaut
# ---------------------------------------------------------------------------
if [ "$INSTALL_WINETRICKS" != "0" ] && [ -n "$WINETRICKS_PACKAGES" ] && command -v winetricks >/dev/null 2>&1; then
  marker="$WINEPREFIX/.winetricks_done_${WINETRICKS_PACKAGES//[^a-zA-Z0-9_.-]/_}"
  if [ ! -f "$marker" ]; then
    echo "[start] running winetricks: $WINETRICKS_PACKAGES"
    winetricks -q $WINETRICKS_PACKAGES || true
    touch "$marker" || true
  fi
fi

# ---------------------------------------------------------------------------
# DPI des polices Wine — évite que texte et curseur soient trop petits.
# Appliqué après winetricks pour ne pas être écrasé par ses opérations.
# ---------------------------------------------------------------------------
if [ -n "$WINE_DPI" ] && [ "$WINE_DPI" != "96" ]; then
  DPI_HEX=$(printf "%08x" "$WINE_DPI")
  USERREG="$WINEPREFIX/user.reg"
  if [ -f "$USERREG" ] && grep -q '"LogPixels"=dword:' "$USERREG"; then
    echo "[start] patching Wine DPI to $WINE_DPI (0x$DPI_HEX) in user.reg"
    sed -i "s/\"LogPixels\"=dword:[0-9a-f]\{8\}/\"LogPixels\"=dword:$DPI_HEX/" "$USERREG"
  fi
fi

# ---------------------------------------------------------------------------
# Lance ComicRack
# ---------------------------------------------------------------------------
echo "[start] launching wine $COMIC_ARGS"
exec /usr/bin/wine $COMIC_ARGS
