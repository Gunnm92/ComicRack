#!/usr/bin/env bash
set -euo pipefail

WINEPREFIX=${WINEPREFIX:-/config/comicrack/wineprefix}
WINEARCH=${WINEARCH:-win32}
PROTON_HOME=${PROTON_HOME:-/opt/proton-ge}
DISPLAY=${DISPLAY:-:1}

export WINEPREFIX WINEARCH PROTON_HOME DISPLAY
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-$PROTON_HOME/dist/lib/gstreamer-1.0:$PROTON_HOME/dist/lib64/gstreamer-1.0}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-$PROTON_HOME/dist/lib64:$PROTON_HOME/dist/lib:$PROTON_HOME/dist/lib64/wine:$PROTON_HOME/dist/lib/wine:$LD_LIBRARY_PATH}
export PATH=${PATH:-$PROTON_HOME/dist/bin:$PROTON_HOME/dist/bin32:$PATH}

if [ -x "$PROTON_HOME/dist/bin/wine" ]; then
  COMIC_CMD=${COMIC_CMD:-$PROTON_HOME/dist/bin/wine}
  WINEBOOT_CMD=${WINEBOOT_CMD:-$PROTON_HOME/dist/bin/wineboot}
else
  COMIC_CMD=${COMIC_CMD:-$(command -v wine || true)}
  WINEBOOT_CMD=${WINEBOOT_CMD:-$(command -v wineboot || true)}
fi
COMIC_ARGS=${COMIC_ARGS:-/opt/comicrack/ComicRack.exe}
read -r -a COMIC_ARGS_ARRAY <<< "$COMIC_ARGS"

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

mkdir -p "$WINEPREFIX"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  if [ -n "$WINEBOOT_CMD" ]; then
    "$WINEBOOT_CMD" --init
  else
    echo "[start] warning: wineboot missing" >&2
  fi
fi

wait_for_x=0
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

printf "[start] launching gamescope %s -- %s %s\n" "${GAME_CMD_ARGS[*]}" "$COMIC_CMD" "${COMIC_ARGS_ARRAY[*]}"
exec gamescope "${GAME_CMD_ARGS[@]}" -- "$COMIC_CMD" "${COMIC_ARGS_ARRAY[@]}"
