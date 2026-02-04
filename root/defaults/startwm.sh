#!/usr/bin/env bash
# Lance start.sh en arrière-plan (wine / ComicRack), puis Openbox comme WM.
# /defaults/autostart n'est pas lu automatiquement par Openbox dans cette image,
# on lance donc start.sh directement ici.
/opt/scripts/start.sh &
exec dbus-launch --exit-with-session openbox --config-file /defaults/menu.xml
