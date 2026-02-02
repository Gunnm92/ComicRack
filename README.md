# ComicRack Docker on LinuxServer Selkies

This build now uses the LinuxServer [Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies) (Debian Trixie flavor) to provide a modern Kasm-style WebRTC desktop instead of the old noVNC stack. Selkies already wires pixelflux/pcmflux, PulseAudio, and an Openbox session behind a single HTTP/WebSocket gateway, so the container only needs to start ComicRack via Proton GE while the Selkies runtime handles the browser stream and authentication.

The image downloads GE-Proton10-29 (released January 24, 2026, with the latest DXVK/vkd3d fixes) and the ComicRack Community Edition v0.9.182 ZIP (published December 19, 2025) at build time, installs WineGStreamer support, and exports `GST_PLUGIN_SYSTEM_PATH_1_0` so Proton can reach both its own codec plugins and the system-provided GStreamer modules.

## Build

```bash
docker build -f Docker/Dockerfile -t comicrack-selkies .
```

## Run

Selkies exposes a small web control plane on port 3000 by default and an HTTPS endpoint on 3001. Run the container and map your desired ports:

```bash
docker run --rm -p 3000:3000 -p 3001:3001 -v ~/comicrack:/config comicrack-selkies
```

- Access the remote desktop (with ComicRack) at `http://localhost:3000` (default `CUSTOM_PORT`) or `https://localhost:3001`.
- Set `PASSWORD`, `CUSTOM_PORT`, `CUSTOM_HTTPS_PORT`, and related Selkies env variables to lock down who can connect (see the upstream README for the full list).
- The Wine prefix lives under `/config/comicrack/wineprefix`, so mounting `/config` keeps your database, scripts, and prefix between restarts.

## Behavior

- `root/defaults/autostart` simply executes `/opt/scripts/start.sh`, which initializes the Proton Wine prefix once (`wineboot`) and then launches ComicRack CE via `Proton/dist/bin/wine`.
- GStreamer 1.0 plugins are installed (base/aux/bad/ugly/libav/pulseaudio) so any codecs invoked by ComicRack through Proton will resolve via `GST_PLUGIN_SYSTEM_PATH_1_0`.
- If you need to pin to a different Proton or ComicRack release, download the desired tarball/ZIP outside the build and override `PROTON_HOME` or the comic archive in a derived Dockerfile.

## Troubleshooting

- Selkies already runs a compositor, so there is no separate VNC server​—the browser session is routed through pixelflux. Do not try to run the old noVNC port 8080.
- To expose a custom desktop size or enable GPU acceleration, pass the Selkies env vars like `MAX_RESOLUTION`, `DRINODE`, or `PIXELFLUX_WAYLAND` when running the container.
