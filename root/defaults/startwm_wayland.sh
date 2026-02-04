#!/usr/bin/env bash
# Pas de labwc : gamescope est lui-même un compositor Wayland.
# Il se connecte au socket créé par Selkies via --backend wayland.

ulimit -c 0

export XCURSOR_THEME=breeze_cursors
export XCURSOR_SIZE=24
export XKB_DEFAULT_LAYOUT=us
export XKB_DEFAULT_RULES=evdev

# Selkies crée le socket dans XDG_RUNTIME_DIR — gamescope a besoin de ces deux
# variables pour le trouver. On les force ici en cas de perte via s6-setuidgid.
export XDG_RUNTIME_DIR=/config/.XDG
export WAYLAND_DISPLAY=wayland-1

exec /opt/scripts/start.sh
