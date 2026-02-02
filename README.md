# ComicRack Docker (Proton GE + Community Edition)

This image bundles the ComicRack Community Edition Windows build with a modern Proton GE runtime and a lightweight XFCE desktop so the app can run headless inside a container while remaining controllable through VNC/noVNC. The Dockerfile now pulls GE-Proton10-29 (released January 24, 2026, with the latest DXVK/vkd3d and controller fixes) and installs the latest ComicRack CE v0.9.182 (December 19, 2025) release automatically at build time so you always ship a fresh runtime and binary. citeturn4search0turn4search1

Because Wine/Proton uses GStreamer to decode in-game media, the container installs the full GStreamer 1.0 plugin suite and exports `GST_PLUGIN_SYSTEM_PATH_1_0` so Proton can reach both the bundled modules and the system codecs, which mirrors the Bottles recommendation and the official Proton GE instructions for media foundation support. citeturn4search2turn4search3

## Building

```bash
docker build -f Docker/Dockerfile -t comicrack-proton .
```

The build downloads noVNC 1.6.0, websockify 0.13.0, the latest Proton GE tarball, and the current ComicRack CE ZIP by querying each project’s GitHub releases during image creation.

## Running

```bash
docker run --rm -p 8080:8080 -p 5900:5900 comicrack-proton
```

- `http://localhost:8080/vnc.html` opens the noVNC session that bridges VNC port 5900 to your browser.
- Port 5900 is kept for standard VNC clients (`x11vnc` runs with `-nopw -shared`).
- The compositor (XFCE) and ComicRack binary are launched via `supervisord`; the entrypoint runs `wineboot` once before `supervisord` so the Wine prefix is initialized before the GUI services start.

## Notes

- The `start.sh` entrypoint ensures `WINEPREFIX` exists, seeds it with `wineboot`, and keeps `supervisord` in the foreground while setting Proton’s `PATH`/`LD_LIBRARY_PATH`.
- You can pin a specific Proton or ComicRack release by overriding the GitHub release URLs via build args and setting `PROTON_HOME` to an extracted tarball of your choice.
