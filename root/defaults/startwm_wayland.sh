#!/usr/bin/env bash
# Mode Wayland — labwc comme compositor sur pixelflux.
# pixelflux expose wayland-1, labwc se connecte dessus comme compositor nested.
# XWayland est lancé automatiquement par labwc quand Wine se connecte.

ulimit -c 0

export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/config/.XDG}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export XCURSOR_THEME=${XCURSOR_THEME:-whiteglass}
export XCURSOR_SIZE=${XCURSOR_SIZE:-24}
# Ne pas exporter DISPLAY ici — XWayland sera lancé auto par labwc
# et start.sh détecte le display via /tmp/.X11-unix/

# Lance start.sh en arrière-plan — il détecte le display XWayland auto
/opt/scripts/start.sh &

# labwc comme compositor — lit /defaults/labwc.xml
exec labwc -c /defaults/labwc.xml
