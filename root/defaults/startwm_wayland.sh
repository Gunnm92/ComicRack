#!/usr/bin/env bash
# Mode Wayland — pas de compositor intermédiaire.
# pixelflux (Selkies) expose wayland-1 comme compositor wlroots.
# On lance XWayland dessus : il se connecte comme client Wayland
# et expose un display X (:1) pour Wine.

ulimit -c 0

export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/config/.XDG}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export XCURSOR_THEME=${XCURSOR_THEME:-whiteglass}
export XCURSOR_SIZE=${XCURSOR_SIZE:-24}
export DISPLAY=:1

# XWayland en background — se connecte à pixelflux et expose DISPLAY=:1
# -rootless : fenêtres gérées par le compositor
# -noreset  : ne pas mourir après le dernier client
Xwayland :1 -rootless -noreset &
XWPID=$!

# Attendre que le display X soit prêt avant de lancer Wine
for i in {1..30}; do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "[startwm] XWayland $DISPLAY is up"
    break
  fi
  echo "[startwm] waiting for XWayland $DISPLAY (attempt $i/30)..."
  sleep 1
done

# Lance start.sh — une seule fois, après que XWayland soit prêt
exec /opt/scripts/start.sh
