#!/usr/bin/env bash
# ============================================================================
# Wine Prefix Initialization Script
# ============================================================================
# Runs once at container startup to initialize Wine and install dependencies

set -euo pipefail

WINEPREFIX=${WINEPREFIX:-/config/.wine}
WINETRICKS_PACKAGES=${WINETRICKS_PACKAGES:-"dotnet48 corefonts mono gecko"}

# Initialize Wine prefix if needed
if [ ! -f "$WINEPREFIX/system.reg" ]; then
  echo "[Wine] Initializing Wine prefix at $WINEPREFIX"
  wineboot --init >/tmp/wineboot.log 2>&1 || true
fi

# Install winetricks dependencies (only once)
if [ -n "$WINETRICKS_PACKAGES" ]; then
  marker="$WINEPREFIX/.winetricks_done"

  if [ ! -f "$marker" ]; then
    echo "[Wine] Installing dependencies: $WINETRICKS_PACKAGES"
    winetricks -q $WINETRICKS_PACKAGES >/tmp/winetricks.log 2>&1 || true
    touch "$marker"
    echo "[Wine] Dependencies installed successfully"
  fi
fi
