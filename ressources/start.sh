#!/usr/bin/env bash
# ============================================================================
# ComicRack Launcher
# ============================================================================
# Simple launcher that starts ComicRack with Wine

set -euo pipefail

cd /opt/comicrack
exec wine ComicRack.exe
