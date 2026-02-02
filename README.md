# ComicRack Docker on LinuxServer Selkies

This build now uses the LinuxServer [Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies) (Debian Trixie flavor) to provide a modern Kasm-style WebRTC desktop instead of the old noVNC stack. Selkies already wires pixelflux/pcmflux, PulseAudio, gamescope, and an Openbox session behind a single HTTP/WebSocket gateway, so the container only needs to start ComicRack via Proton GE while the Selkies runtime handles the browser stream and authentication.

The image downloads GE-Proton10-29 (released January 24, 2026, with the latest DXVK/vkd3d fixes) and the ComicRack Community Edition v0.9.182 ZIP (published December 19, 2025) at build time, installs Wine/GStreamer support, and exports `GST_PLUGIN_SYSTEM_PATH_1_0` so Proton can reach both its own codec plugins and the system-provided GStreamer modules. Gamescope is installed as the compositor, so only ComicRack’s window is rendered, scaled, and streamed within the Selkies session. The gamescope command can be tuned via the `GAMESCOPE_WIDTH`, `GAMESCOPE_HEIGHT`, `GAMESCOPE_SCALE`, `GAMESCOPE_FULLSCREEN`, and `GAMESCOPE_EXTRA_ARGS` environment variables before launching the container.

## Build

```bash
docker build -f Docker/Dockerfile -t comicrack-selkies .
```

## Run

Selkies exposes ports 3000 (HTTP) and 3001 (HTTPS) by default and can now run in Wayland mode. The provided `docker-compose.yml` builds the image, enables `PIXELFLUX_WAYLAND`, and maps Selkies’ ports to `5700`/`5701` on your host:

```bash
docker-compose up --build
```

- Browse to `http://localhost:5700` or `https://localhost:5701` to connect to ComicRack through the Selkies/VNC web UI.
- Change the capture resolution by setting the `SELKIES_MANUAL_WIDTH`, `SELKIES_MANUAL_HEIGHT`, or `MAX_RESOLUTION` env vars in the compose file (or via `docker compose run -e ...`). The `GAMESCOPE_WIDTH`/`GAMESCOPE_HEIGHT`/`GAMESCOPE_SCALE` variables already control how gamescope shapes ComicRack inside the Wayland session.
- The compose file no longer mounts any host directory, so the entire Selkies `/config` tree is ephemeral by default; mount a directory yourself with `-v ~/comicrack:/config` (or edit the compose) if you want the Wine prefix/persistent data to survive restarts.
- Set `PASSWORD` in the compose file (or via `docker compose run -e PASSWORD=...`) only if you need HTTP authentication; leaving it unset lets Selkies use its default `abc/abc` credentials or operate password-free depending on upstream defaults.
- The compose file also enables `PIXELFLUX_WAYLAND`, so Selkies boots into its Wayland compositor; `ressources/start.sh` waits for the Wayland socket before launching `gamescope` so the streamed session only shows ComicRack. 

## Behavior

- `root/defaults/autostart` simply executes `/opt/scripts/start.sh`, which initializes the Proton Wine prefix once (`wineboot`) and then launches ComicRack CE wrapped by `gamescope` (so only that window is rendered/encoded within the Selkies stream).
- Set `GAMESCOPE_WIDTH`, `GAMESCOPE_HEIGHT`, `GAMESCOPE_SCALE`, `GAMESCOPE_FULLSCREEN` (0/1), or `GAMESCOPE_EXTRA_ARGS` to tune the gamescope surface, and override `COMIC_CMD`/`COMIC_ARGS` if you want to run a helper script before starting the executable.
- GStreamer 1.0 plugins are installed (base/aux/bad/ugly/libav/pulseaudio) so any codecs invoked by ComicRack through Proton will resolve via `GST_PLUGIN_SYSTEM_PATH_1_0`.
- If you need to pin to a different Proton or ComicRack release, download the desired tarball/ZIP outside the build and override `PROTON_HOME` or the comic archive in a derived Dockerfile.

## Troubleshooting

- Selkies already runs a compositor, so there is no separate VNC server​—the browser session is routed through pixelflux. Do not try to run the old noVNC port 8080.
- To expose a custom desktop size or enable GPU acceleration, pass the Selkies env vars like `MAX_RESOLUTION`, `DRINODE`, or `PIXELFLUX_WAYLAND` when running the container.
