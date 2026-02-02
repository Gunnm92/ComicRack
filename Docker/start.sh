#!/usr/bin/env bash
set -euo pipefail

WINEPREFIX=${WINEPREFIX:-/config/comicrack/wineprefix}
WINEARCH=${WINEARCH:-win32}
PROTON_HOME=${PROTON_HOME:-/opt/proton-ge}
DISPLAY=${DISPLAY:-:1}

export WINEPREFIX WINEARCH PROTON_HOME DISPLAY
export GST_PLUGIN_SYSTEM_PATH_1_0=${GST_PLUGIN_SYSTEM_PATH_1_0:-$PROTON_HOME/dist/lib/gstreamer-1.0:$PROTON_HOME/dist/lib64/gstreamer-1.0}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-$PROTON_HOME/dist/lib64:$PROTON_HOME/dist/lib:$PROTON_HOME/dist/lib64/wine:$PROTON_HOME/dist/lib/wine:$LD_LIBRARY_PATH}
export PATH=${PATH:-$PROTON_HOME/dist/bin:$PROTON_HOME/dist/bin32:$PATH}

mkdir -p "$WINEPREFIX"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  "$PROTON_HOME/dist/bin/wineboot" --init
fi

exec "$PROTON_HOME/dist/bin/wine" /opt/comicrack/ComicRack.exe
