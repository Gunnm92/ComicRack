#!/usr/bin/env bash
# Lance start.sh en arrière-plan (wine / ComicRack), puis Openbox comme WM.
# /defaults/autostart n'est pas lu automatiquement par Openbox dans cette image,
# on lance donc start.sh directement ici.
DISPLAY=${DISPLAY:-:1}
export DISPLAY
if [ -n "${CURSOR_SIZE:-}" ]; then
  export XCURSOR_SIZE="$CURSOR_SIZE"
fi
if [ -n "${XCURSOR_THEME:-}" ]; then
  export XCURSOR_THEME="$XCURSOR_THEME"
fi
if command -v xrdb >/dev/null 2>&1; then
  if [ -n "${CURSOR_SIZE:-}" ]; then
    printf "Xcursor.size: %s\n" "$CURSOR_SIZE" | xrdb -merge -display "$DISPLAY"
  fi
  if [ -n "${XCURSOR_THEME:-}" ]; then
    printf "Xcursor.theme: %s\n" "$XCURSOR_THEME" | xrdb -merge -display "$DISPLAY"
  fi
fi
/opt/scripts/start.sh &
exec dbus-launch --exit-with-session openbox --config-file /defaults/menu.xml
