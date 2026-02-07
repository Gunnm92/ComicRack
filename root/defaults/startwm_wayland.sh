#!/usr/bin/env bash
# Mode Wayland — Weston comme compositor nested sur pixelflux.
# pixelflux expose wayland-1. Weston se connecte dessus en mode --socket.
# XWayland est lancé automatiquement par Weston.

ulimit -c 0

export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/config/.XDG}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export PIXELFLUX_WAYLAND=${PIXELFLUX_WAYLAND:-true}
export XCURSOR_THEME=${XCURSOR_THEME:-default}
export XCURSOR_SIZE=${CURSOR_SIZE:-400}

# Lancer start.sh en arrière-plan
/usr/bin/env PIXELFLUX_WAYLAND="${PIXELFLUX_WAYLAND}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY}" /opt/scripts/start.sh >/config/start.log 2>&1 &

# Start Weston en mode nested (utilise le socket wayland-1 de pixelflux)
# Utiliser pixman renderer (software) car pas de GPU
exec weston --backend=wayland-backend.so --shell=kiosk-shell.so --use-pixman
