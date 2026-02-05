#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
HOME=${HOME:-/config}
BASE_WINEPREFIX=${WINEPREFIX:-$HOME/.wine}
WINEARCH=win64          # ComicRack CE est 64-bit
DISPLAY=${DISPLAY:-:1}  # Xvfb lancé par Selkies svc-xorg
PUID=${PUID:-1000}
PGID=${PGID:-1000}
USE_PROTON=${USE_PROTON:-0}
PROTON_DIR=${PROTON_DIR:-/opt/proton}
STEAM_COMPAT_DATA_PATH=${STEAM_COMPAT_DATA_PATH:-}
STEAM_COMPAT_CLIENT_INSTALL_PATH=${STEAM_COMPAT_CLIENT_INSTALL_PATH:-/opt/proton}

if [ "$USE_PROTON" = "1" ]; then
  STEAM_COMPAT_DATA_PATH=${STEAM_COMPAT_DATA_PATH:-$BASE_WINEPREFIX}
  WINEPREFIX="$STEAM_COMPAT_DATA_PATH/pfx"
else
  WINEPREFIX="$BASE_WINEPREFIX"
fi

export HOME WINEPREFIX WINEARCH DISPLAY USE_PROTON PROTON_DIR STEAM_COMPAT_DATA_PATH STEAM_COMPAT_CLIENT_INSTALL_PATH
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0}

INSTALL_WINETRICKS=${INSTALL_WINETRICKS:-1}
WINETRICKS_PACKAGES=${WINETRICKS_PACKAGES:-dotnet48 corefonts mono gecko}
COMIC_ARGS=${COMIC_ARGS:-/opt/comicrack/ComicRack.exe}
PROTON_RUN=${PROTON_RUN:-$PROTON_DIR/proton}
COMIC_WORKDIR=${COMIC_WORKDIR:-/opt/comicrack}
WINE_DPI=${WINE_DPI:-150}           # DPI pour les polices Wine (96=par défaut, 150 pour 1280x720)
CURSOR_SIZE=${CURSOR_SIZE:-200}     # Taille du curseur X11/Wine
WINE_FONT=${WINE_FONT:-}            # Police globale Wine (ex: Arial)
XCURSOR_THEME=${XCURSOR_THEME:-}    # Thème XCursor (optionnel)
COMIC_DARK=${COMIC_DARK:-0}          # 1 pour activer le mode dark (-dark)
CURSOR_PACK=${CURSOR_PACK:-0}        # 1 pour installer un pack de curseurs Windows
CURSOR_PACK_URL=${CURSOR_PACK_URL:-https://github.com/SullensCR/Windows-Material-Design-Cursor-V2-Dark-Hdpi-by-jepriCreations/archive/refs/heads/main.zip}
CURSOR_PACK_VARIANT=${CURSOR_PACK_VARIANT:-default} # "default" ou "pure black"

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
if [ "$USE_PROTON" = "1" ]; then
  mkdir -p "$STEAM_COMPAT_DATA_PATH"
fi
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
  if [ "$USE_PROTON" = "1" ] && [ -x "$PROTON_RUN" ]; then
    "${RUN_AS_CMD[@]}" "$PROTON_RUN" run wineboot --init || true
  else
    "${RUN_AS_CMD[@]}" /usr/bin/wineboot --init || true
  fi
fi

# ---------------------------------------------------------------------------
# Winetricks (une seule fois) — dotnet48 par défaut
# ---------------------------------------------------------------------------
if [ "$INSTALL_WINETRICKS" != "0" ] && [ -n "$WINETRICKS_PACKAGES" ] && command -v winetricks >/dev/null 2>&1; then
  if command -v wineserver >/dev/null 2>&1; then
    echo "[start] stopping wineserver before winetricks"
    "${RUN_AS_CMD[@]}" wineserver -k || true
    "${RUN_AS_CMD[@]}" wineserver -w || true
  fi
  marker="$WINEPREFIX/.winetricks_done_${WINETRICKS_PACKAGES//[^a-zA-Z0-9_.-]/_}"
  if [ ! -f "$marker" ]; then
    # If dotnet48 is already present, avoid long winetricks runs.
    if "${RUN_AS_CMD[@]}" /usr/bin/wine reg query "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full" /v Release >/dev/null 2>&1; then
      echo "[start] dotnet48 already present; skipping winetricks"
      "${RUN_AS_CMD[@]}" touch "$marker" || true
    else
    echo "[start] running winetricks: $WINETRICKS_PACKAGES"
    if command -v timeout >/dev/null 2>&1; then
      "${RUN_AS_CMD[@]}" timeout -k 10 1800s winetricks -q $WINETRICKS_PACKAGES || true
    else
      "${RUN_AS_CMD[@]}" winetricks -q $WINETRICKS_PACKAGES || true
    fi
    if "${RUN_AS_CMD[@]}" /usr/bin/wine reg query "HKLM\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full" /v Release >/dev/null 2>&1; then
      "${RUN_AS_CMD[@]}" touch "$marker" || true
    fi
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Pack de curseurs Windows (remplace les curseurs système Wine)
# ---------------------------------------------------------------------------
if [ "$CURSOR_PACK" = "1" ] && command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
  cursor_dir="$WINEPREFIX/drive_c/windows/Cursors"
  marker="$WINEPREFIX/.cursorpack_${CURSOR_PACK_VARIANT}_done"
  if [ ! -f "$marker" ]; then
    echo "[start] installing Windows cursor pack ($CURSOR_PACK_VARIANT)"
    tmp_zip="/tmp/cursorpack.zip"
    tmp_dir="/tmp/cursorpack"
    rm -rf "$tmp_dir"
    mkdir -p "$tmp_dir"
    curl -fsSL "$CURSOR_PACK_URL" -o "$tmp_zip" || true
    unzip -q "$tmp_zip" -d "$tmp_dir" || true
    src_dir=$(find "$tmp_dir" -type d -path "*/cursor/${CURSOR_PACK_VARIANT}" -print -quit)
    if [ -n "$src_dir" ]; then
      "${RUN_AS_CMD[@]}" mkdir -p "$cursor_dir"
      "${RUN_AS_CMD[@]}" cp -f "$src_dir"/* "$cursor_dir"/ || true
      "${RUN_AS_CMD[@]}" touch "$marker" || true
    else
      echo "[start] warning: cursor pack variant not found: $CURSOR_PACK_VARIANT"
    fi
    rm -rf "$tmp_dir" "$tmp_zip"
  fi
  # Apply cursor scheme
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v Arrow /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\pointer.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v Help /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\help.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v AppStarting /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\busy.ani" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v Wait /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\working.ani" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v Crosshair /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\precision.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v IBeam /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\beam.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v NWPen /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\handwriting.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v No /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\unavailable.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v SizeNS /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\vert.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v SizeWE /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\horz.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v SizeNWSE /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\dgn1.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v SizeNESW /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\dgn2.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v SizeAll /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\move.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v UpArrow /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\alternate.cur" /f || true
  "${RUN_AS_CMD[@]}" /usr/bin/wine reg add "HKCU\\Control Panel\\Cursors" /v Hand /t REG_SZ /d "C:\\\\windows\\\\Cursors\\\\link.cur" /f || true
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
# Ensure working directory so relative resource lookups succeed.
if [ -d "$COMIC_WORKDIR" ]; then
  cd "$COMIC_WORKDIR"
fi
# ---------------------------------------------------------------------------
if [ "$USE_PROTON" = "1" ] && [ -x "$PROTON_RUN" ]; then
  echo "[start] launching Proton $COMIC_ARGS"
  if [ "$COMIC_DARK" = "1" ]; then
    echo "[start] enabling ComicRack dark mode (-dark)"
    exec "${RUN_AS_CMD[@]}" "$PROTON_RUN" run $COMIC_ARGS -dark
  fi
  exec "${RUN_AS_CMD[@]}" "$PROTON_RUN" run $COMIC_ARGS
fi

echo "[start] launching wine $COMIC_ARGS"
if [ "$COMIC_DARK" = "1" ]; then
  echo "[start] enabling ComicRack dark mode (-dark)"
  exec "${RUN_AS_CMD[@]}" /usr/bin/wine $COMIC_ARGS -dark
fi
exec "${RUN_AS_CMD[@]}" /usr/bin/wine $COMIC_ARGS
