#!/usr/bin/env bash
set -euo pipefail

HOME=${HOME:-/config}
WINEPREFIX=${WINEPREFIX:-$HOME/.wine}
WINEARCH=${WINEARCH:-win32}
PIXELFLUX_WAYLAND=${PIXELFLUX_WAYLAND:-false}
DISPLAY=${DISPLAY:-:1}
WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/config/.XDG}
PUID=${PUID:-1000}
PGID=${PGID:-1000}
INSTALL_WINE_MONO=${INSTALL_WINE_MONO:-1}
WINETRICKS_PACKAGES=${WINETRICKS_PACKAGES:-}

export HOME WINEPREFIX WINEARCH DISPLAY PIXELFLUX_WAYLAND WAYLAND_DISPLAY XDG_RUNTIME_DIR
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-/usr/lib/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0}

COMIC_CMD=${COMIC_CMD:-/usr/bin/wine}
WINEBOOT_CMD=${WINEBOOT_CMD:-/usr/bin/wineboot}
COMIC_ARGS=${COMIC_ARGS:-/opt/comicrack/ComicRack.exe}
read -r -a COMIC_ARGS_ARRAY <<< "$COMIC_ARGS"

GAMESCOPE_CMD=${GAMESCOPE_CMD:-$(command -v gamescope || true)}
if [ -z "$GAMESCOPE_CMD" ]; then
  echo "[start] error: gamescope binary not available" >&2
  exit 1
fi

GAMESCOPE_WIDTH=${GAMESCOPE_WIDTH:-1920}
GAMESCOPE_HEIGHT=${GAMESCOPE_HEIGHT:-1080}
GAMESCOPE_SCALE=${GAMESCOPE_SCALE:-1.0}
GAMESCOPE_FULLSCREEN=${GAMESCOPE_FULLSCREEN:-1}
GAMESCOPE_EXTRA_ARGS=${GAMESCOPE_EXTRA_ARGS:-}

GAME_CMD_ARGS=()
if [ "$GAMESCOPE_FULLSCREEN" != "0" ]; then
  GAME_CMD_ARGS+=(--fullscreen)
fi
GAME_CMD_ARGS+=(--scale "$GAMESCOPE_SCALE")
GAME_CMD_ARGS+=(--width "$GAMESCOPE_WIDTH")
GAME_CMD_ARGS+=(--height "$GAMESCOPE_HEIGHT")
if [ -n "$GAMESCOPE_EXTRA_ARGS" ]; then
  read -r -a EXTRA <<< "$GAMESCOPE_EXTRA_ARGS"
  GAME_CMD_ARGS+=("${EXTRA[@]}")
fi

mkdir -p "$WINEPREFIX" "$XDG_RUNTIME_DIR"
if [ "$(id -u)" -eq 0 ]; then
  chown -R "${PUID}:${PGID}" "$WINEPREFIX" "$XDG_RUNTIME_DIR"
fi

wait_for_x=0
WAYLAND_SOCKET="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
if [ "$PIXELFLUX_WAYLAND" = "true" ]; then
  for i in {1..30}; do
    if [ -S "$WAYLAND_SOCKET" ]; then
      wait_for_x=1
      break
    fi
    echo "[start] waiting for Wayland display $WAYLAND_DISPLAY (attempt $i/30)..."
    sleep 1
  done
  if [ "$wait_for_x" -eq 0 ]; then
    echo "[start] warning: Wayland display $WAYLAND_DISPLAY still unavailable after 30s"
  fi
else
  for i in {1..30}; do
    if xdpyinfo >/dev/null 2>&1; then
      wait_for_x=1
      break
    fi
    echo "[start] waiting for X server (attempt $i/30)..."
    sleep 1
  done
  if [ "$wait_for_x" -eq 0 ]; then
    echo "[start] warning: X server still unavailable after 30s"
  fi
fi

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  if [ -n "$WINEBOOT_CMD" ]; then
    "$WINEBOOT_CMD" --init
  else
    echo "[start] warning: wineboot missing" >&2
  fi
fi

# Ensure Wine Mono is installed in the prefix (headless-safe, avoids GUI prompt).
if [ "$INSTALL_WINE_MONO" != "0" ]; then
  MONO_MSI=""
  if ls /usr/share/wine/mono/wine-mono-*.msi >/dev/null 2>&1; then
    MONO_MSI="$(ls /usr/share/wine/mono/wine-mono-*.msi 2>/dev/null | sort -V | tail -n1)"
  fi
  if [ -n "$MONO_MSI" ]; then
    # If mono isn't installed in the prefix yet, install it silently.
    if [ ! -d "$WINEPREFIX/drive_c/windows/mono" ]; then
      echo "[start] installing Wine Mono into prefix via msiexec..."
      "$COMIC_CMD" msiexec /i "$MONO_MSI" /qn || true
    fi
  fi
fi

# Optional: install extra components via winetricks (example: WINETRICKS_PACKAGES=dotnet48).
if [ -n "$WINETRICKS_PACKAGES" ] && command -v winetricks >/dev/null 2>&1; then
  echo "[start] running winetricks: $WINETRICKS_PACKAGES"
  winetricks -q $WINETRICKS_PACKAGES || true
fi

printf "[start] launching gamescope %s -- %s %s\n" "${GAME_CMD_ARGS[*]}" "$COMIC_CMD" "${COMIC_ARGS_ARRAY[*]}"
exec "$GAMESCOPE_CMD" "${GAME_CMD_ARGS[@]}" -- "$COMIC_CMD" "${COMIC_ARGS_ARRAY[@]}"
