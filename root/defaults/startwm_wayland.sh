#!/usr/bin/env bash
# Mode Wayland — labwc comme compositor nested sur pixelflux.
# pixelflux expose wayland-1. labwc se connecte dessus.
# XWayland est lancé automatiquement par labwc quand Wine se connecte.
# On utilise -s pour lancer start.sh APRÈS que labwc soit initialisé
# (output créé, pas de flash noir au démarrage).

ulimit -c 0

export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/config/.XDG}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export PIXELFLUX_WAYLAND=${PIXELFLUX_WAYLAND:-true}
export XCURSOR_THEME=${XCURSOR_THEME:-default}
export XCURSOR_SIZE=${CURSOR_SIZE:-400}

# Start labwc, then launch ComicRack in background once compositor is up.
labwc -c /defaults/labwc.xml &
labwc_pid=$!

/usr/bin/env PIXELFLUX_WAYLAND="${PIXELFLUX_WAYLAND}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY}" /opt/scripts/start.sh >/config/start.log 2>&1 &

wait "$labwc_pid"
