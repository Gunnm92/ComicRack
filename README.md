# ComicRack Docker sur LinuxServer Selkies

Le conteneur est maintenant construit sur l’image `linuxserver/baseimage-selkies:arch`, ce qui fournit directement le compositeur Wayland Arch rapide avec Selkies (pixelflux/pcmflux, PulseAudio, etc.) au lieu de l’ancien empilement noVNC. La Dockerfile installe Wine, GStreamer et `gamescope` à l’aide des dépôts officiels `pacman` (y compris `community`/`multilib`) et télécharge la dernière release de ComicRack Community Edition au moment du build. `gamescope` rend uniquement la fenêtre de ComicRack pour que Selkies puisse s’en charger proprement dans le tunnel WebSocket/HTTP.

## Compilation

```bash
docker build -t comicrack-selkies .
```

## Exécution

Le fichier `docker-compose.yml` construit l’image, active le mode Wayland (`PIXELFLUX_WAYLAND=true`), contrôle la résolution du bureau et expose les ports Selkies standard.

```bash
docker compose up --build
```

- Le navigateur se connecte via `http://localhost:5700` ou `https://localhost:5701` au tunnel WebSocket fourni par Selkies.
- L’environnement `SELKIES_MANUAL_WIDTH`/`SELKIES_MANUAL_HEIGHT` définit la résolution cible (ici 1920x1080) pour la session Wayland, tandis que `GAMESCOPE_WIDTH`, `GAMESCOPE_HEIGHT`, `GAMESCOPE_SCALE` et `GAMESCOPE_FULLSCREEN` ajustent la surface renderisée et affichée par `gamescope`.
- Aucune archive/volume hôte n’est montée par défaut : le dossier `/config` reste éphémère. Montez votre propre volume (par exemple `-v ~/comicrack:/config`) si vous souhaitez conserver le préfixe Wine ou les paramètres entre les redémarrages.
- L’authentification reste optionnelle : ne renseignez `PASSWORD` que si vous avez besoin de sécuriser l’interface HTTP (sinon, Selkies applique `abc/abc` ou fonctionne sans mote de passe selon les valeurs par défaut).
- Selkies attend le socket Wayland avant de lancer `gamescope` ; le script `ressources/start.sh` démarre `wineboot` (si nécessaire) puis exécute ComicRack via `gamescope` afin que seule son interface soit encodée.

## Description

- `ressources/start.sh` exporte les variables de résolution, prépare le préfixe Wine (et lui applique `PUID`/`PGID` par défaut 1000) et fixe `XDG_RUNTIME_DIR` à `/config/.XDG` avant d’attendre la disponibilité du socket Wayland. Le lancement de `gamescope` se fait avec `GAMESCOPE_FULLSCREEN=1` par défaut et accepte les arguments supplémentaires via `GAMESCOPE_EXTRA_ARGS`.
- Les plugins GStreamer (`base`, `good`, `bad`, `ugly`, `libav`, `pulseaudio`, `alsa`) sont installés pour que Wine puisse atteindre les codecs GPU/audio dont ComicRack a besoin.
- La résolution peut être changée à chaud en réexportant `SELKIES_MANUAL_*` ou `GAMESCOPE_*` dans `docker compose run` ou en ajustant le fichier de composition. Les variables `COMIC_CMD` et `COMIC_ARGS` peuvent aussi être surchargées si vous souhaitez lancer une étape préalable à `ComicRack.exe`.

## Résolution de problèmes

- Selkies tourne déjà son propre compositeur : inutile de chercher un port noVNC (comme 8080) ou d’essayer de démarrer un affichage X11 traditionnel.
- Si vous avez besoin de GPU natif, exposez la variable `DRINODE` et adaptez `MAX_RESOLUTION`; sinon, la capture software (x264 via Pixman) fonctionne dans la machine virtuelle Arch.
