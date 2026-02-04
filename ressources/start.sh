#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
HOME=${HOME:-/config}
WINEPREFIX=${WINEPREFIX:-$HOME/.wine}
WINEARCH=win64          # ComicRack CE est 64-bit
DISPLAY=${DISPLAY:-:1}  # Xvfb lancé par Selkies svc-xorg
PUID=${PUID:-1000}
PGID=${PGID:-1000}

export HOME WINEPREFIX WINEARCH DISPLAY
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0}

INSTALL_WINETRICKS=${INSTALL_WINETRICKS:-1}
WINETRICKS_PACKAGES=${WINETRICKS_PACKAGES:-dotnet48 corefonts}
COMIC_ARGS=${COMIC_ARGS:-/opt/comicrack/ComicRack.exe}
WINE_DPI=${WINE_DPI:-150}           # DPI pour les polices Wine (96=par défaut, 150 pour 1280x720)
CURSOR_SIZE=${CURSOR_SIZE:-120}     # Taille du curseur X11/Wine
WINE_FONT=${WINE_FONT:-}            # Police globale Wine (ex: Arial)
XCURSOR_THEME=${XCURSOR_THEME:-}    # Thème XCursor (optionnel)
COMIC_DARK=${COMIC_DARK:-0}          # 1 pour activer le mode dark (-dark)

# ---------------------------------------------------------------------------
# Attendre que le serveur d'affichage soit disponible
# ---------------------------------------------------------------------------
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  # Mode Wayland — attendre le socket Wayland (créé par Selkies / pixelflux).
  # XWayland sera lancé automatiquement par labwc quand Wine se connecte.
  WSOCK="${XDG_RUNTIME_DIR:-/run/user/911}/${WAYLAND_DISPLAY}"
  for i in {1..30}; do
    if [ -e "$WSOCK" ]; then
      echo "[start] Wayland socket $WSOCK is up"
      break
    fi
    echo "[start] waiting for Wayland socket $WSOCK (attempt $i/30)..."
    sleep 1
  done
else
  # Mode X11 — attendre Xvfb (Selkies / svc-xorg)
  for i in {1..30}; do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
      echo "[start] X server $DISPLAY is up"
      break
    fi
    echo "[start] waiting for X server $DISPLAY (attempt $i/30)..."
    sleep 1
  done
fi

# ---------------------------------------------------------------------------
# Préfixe Wine
# ---------------------------------------------------------------------------
mkdir -p "$WINEPREFIX"
RUN_AS_CMD=()
if [ "$(id -u)" -eq 0 ]; then
  chown -R "${PUID}:${PGID}" "$WINEPREFIX"
  if command -v s6-setuidgid >/dev/null 2>&1; then
    RUN_AS_CMD=(s6-setuidgid "${PUID}:${PGID}")
  elif command -v su-exec >/dev/null 2>&1; then
    RUN_AS_CMD=(su-exec "${PUID}:${PGID}")
  elif command -v gosu >/dev/null 2>&1; then
    RUN_AS_CMD=(gosu "${PUID}:${PGID}")
  fi
fi

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  echo "[start] running wineboot --init"
  "${RUN_AS_CMD[@]}" /usr/bin/wineboot --init || true
fi

# ---------------------------------------------------------------------------
# Winetricks (une seule fois) — dotnet48 par défaut
# ---------------------------------------------------------------------------
if [ "$INSTALL_WINETRICKS" != "0" ] && [ -n "$WINETRICKS_PACKAGES" ] && command -v winetricks >/dev/null 2>&1; then
  marker="$WINEPREFIX/.winetricks_done_${WINETRICKS_PACKAGES//[^a-zA-Z0-9_.-]/_}"
  if [ ! -f "$marker" ]; then
    echo "[start] running winetricks: $WINETRICKS_PACKAGES"
    "${RUN_AS_CMD[@]}" winetricks -q $WINETRICKS_PACKAGES || true
    touch "$marker" || true
  fi
fi

# ---------------------------------------------------------------------------
# DPI des polices Wine — évite que texte et curseur soient trop petits.
# Appliqué après winetricks pour ne pas être écrasé par ses opérations.
# ---------------------------------------------------------------------------
if [ -n "$WINE_DPI" ] && [ "$WINE_DPI" != "96" ]; then
  echo "[start] setting Wine DPI to $WINE_DPI via registry"
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Desktop" /v LogPixels /t REG_DWORD /d "$WINE_DPI" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f || true
fi

# ---------------------------------------------------------------------------
# Curseur (X11 + Wine)
# ---------------------------------------------------------------------------
if [ -n "$CURSOR_SIZE" ]; then
  export XCURSOR_SIZE="$CURSOR_SIZE"
  if [ -n "$XCURSOR_THEME" ]; then
    export XCURSOR_THEME="$XCURSOR_THEME"
  fi
  echo "[start] setting cursor size to $CURSOR_SIZE"
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v UseXCursor /t REG_SZ /d "Y" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v CursorBaseSize /t REG_DWORD /d "$CURSOR_SIZE" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v CursorSize /t REG_SZ /d "$CURSOR_SIZE" /f || true
fi

# ---------------------------------------------------------------------------
# Police globale Wine
# ---------------------------------------------------------------------------
if [ -n "$WINE_FONT" ]; then
  echo "[start] setting Wine font to $WINE_FONT"
  for font_name in "MS Shell Dlg" "MS Shell Dlg 2" "Segoe UI" "Segoe UI Semibold" "Segoe UI Bold" "Tahoma" "Microsoft Sans Serif" "MS Sans Serif"; do
    "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes" /v "$font_name" /t REG_SZ /d "$WINE_FONT" /f || true
    "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes" /v "$font_name" /t REG_SZ /d "$WINE_FONT" /f || true
  done
fi

# ---------------------------------------------------------------------------
# Lance ComicRack
# ---------------------------------------------------------------------------
echo "[start] launching wine $COMIC_ARGS"
if [ "$COMIC_DARK" = "1" ]; then
  echo "[start] enabling ComicRack dark mode (-dark)"
  exec "${RUN_AS_CMD[@]}" /usr/bin/wine $COMIC_ARGS -dark
fi
exec "${RUN_AS_CMD[@]}" /usr/bin/wine $COMIC_ARGS
