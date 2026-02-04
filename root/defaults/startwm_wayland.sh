#!/usr/bin/env bash
# Mode Wayland — labwc comme compositor (wlroots), Wine via XWayland.
# Même pattern que startwm.sh en X11 : start.sh en background, puis exec le WM.
# svc-de lance ce script après que le socket Wayland Selkies soit prêt.

ulimit -c 0

export XCURSOR_THEME=${XCURSOR_THEME:-whiteglass}
export XCURSOR_SIZE=${XCURSOR_SIZE:-24}
export XKB_DEFAULT_LAYOUT=us
export XKB_DEFAULT_RULES=evdev

# XDG_RUNTIME_DIR et WAYLAND_DISPLAY sont fournis par svc-de / Selkies.
# On les force ici en cas de perte via s6-setuidgid.
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/911}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}

# Lance start.sh en arrière-plan — il attend que XWayland soit prêt
/opt/scripts/start.sh &

# labwc : compositor wlroots, lit /defaults/labwc.xml
exec labwc -c /defaults/labwc.xml
