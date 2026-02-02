#!/usr/bin/env bash
set -euo pipefail

export WINEPREFIX=${WINEPREFIX:-/root/.comicrack}
export WINEARCH=${WINEARCH:-win32}
export PROTON_HOME=${PROTON_HOME:-/opt/proton-ge}
export DISPLAY=${DISPLAY:-:0}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-$PROTON_HOME/dist/lib64:$PROTON_HOME/dist/lib:$PROTON_HOME/dist/lib64/wine:$PROTON_HOME/dist/lib/wine}
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-$PROTON_HOME/dist/lib/gstreamer-1.0:$PROTON_HOME/dist/lib64/gstreamer-1.0}

mkdir -p "$WINEPREFIX"
if [ ! -f "$WINEPREFIX/system.reg" ]; then
  WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" "$PROTON_HOME/dist/bin/wineboot" --init
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
