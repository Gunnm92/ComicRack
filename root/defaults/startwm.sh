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
if [ -n "${CURSOR_SIZE:-}" ] || [ -n "${XCURSOR_THEME:-}" ]; then
  mkdir -p /config/.config/xsettingsd
  {
    [ -n "${CURSOR_SIZE:-}" ] && echo "Xcursor/size $CURSOR_SIZE"
    [ -n "${XCURSOR_THEME:-}" ] && echo "Xcursor/theme \"$XCURSOR_THEME\""
  } > /config/.config/xsettingsd/xsettingsd.conf
  if command -v s6-svc >/dev/null 2>&1 && [ -d /run/service/svc-xsettingsd ]; then
    s6-svc -r /run/service/svc-xsettingsd || true
  fi
fi
/opt/scripts/start.sh &
exec dbus-launch --exit-with-session openbox --config-file /defaults/menu.xml
