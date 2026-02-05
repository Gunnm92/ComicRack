#!/usr/bin/env bash
# Mode Wayland — labwc comme compositor nested sur pixelflux.
# pixelflux expose wayland-1. labwc se connecte dessus.
# XWayland est lancé automatiquement par labwc quand Wine se connecte.
# On utilise -s pour lancer start.sh APRÈS que labwc soit initialisé
# (output créé, pas de flash noir au démarrage).

ulimit -c 0

export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/config/.XDG}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export XCURSOR_THEME=${XCURSOR_THEME:-default}
export XCURSOR_SIZE=${CURSOR_SIZE:-400}

# labwc -s lance la commande après initialisation du compositor
exec labwc -c /defaults/labwc.xml -s "/opt/scripts/start.sh"
