# ComicRack CE — ToDo

Branche active : `wayland` (Debian Trixie + Proton-GE + labwc)

---

## Résolu

- [x] **Base image Debian Trixie + Proton-GE** — `debiantrixie`, apt i386, Proton-GE dans `/opt/proton`
- [x] **Mode Wayland** — labwc comme compositor nested sur pixelflux/Selkies, XWayland auto
- [x] **Lancement via Proton** — chemin `Z:\opt\comicrack\ComicRack.exe` (Proton résout depuis le prefix, pas le cwd)
- [x] **Volume `/library`** — monté R/W, permissions fixées via `FIX_LIBRARY_PERMS`
- [x] **Persistance données** — AppData ComicRack monté directement dans le prefix via volume bind (`./data/comicrack` → `…/cYo/ComicRack Community Edition`). Wine/Proton ne suit pas les symlinks vers des volumes extérieurs, donc pas de `ln -s`. Prefix Wine dans volume `comicrack-config`
- [x] **Volumes `/data` + `/import`** — `/data` persiste entre redémarrages, `/import/Plugins` et `/import/Scripts` copiés au boot
- [x] **Extraction zip ComicRack** — Le zip GitHub est créé sur Windows (backslash dans les chemins). Fix dans le Dockerfile : `info.filename.replace('\\', '/')` avant extraction
- [x] **Curseur** — `CURSOR_SIZE=32` dans compose, `XCURSOR_SIZE` exporté dans startwm_wayland.sh depuis `CURSOR_SIZE`
- [x] **DPI Wine** — `WINE_DPI=150` via registre (`LogPixels` + `Win8DpiScaling`)
- [x] **Police Wine** — `WINE_FONT=Arial` via FontSubstitutes (HKCU + HKLM)
- [x] **library/ retiré du tracking git** — `git filter-repo` pour éradiquer de l'historique

## En cours / À tester après rebuild

- [ ] **Langue française** — Le zip `Languages/fr.zip` existe dans `/opt/comicrack/Languages/` après le fix extraction. À tester en UI — ComicRack devrait le détacter automatiquement ou permettre de le choisir dans les paramètres

## Bloqué / Limitation connue

- ~~**Dark mode**~~ — **Incompatible avec Proton-GE.** Le flag `-dark` et `UseDarkMode = true` dans `ComicRack.ini` provoquent tous deux une fermeture immédiate de ComicRack CE sous Proton. Le dark mode fonctionne en mode Wine natif (`USE_PROTON=0`). Le start.sh supprime automatiquement `UseDarkMode` du ini quand `USE_PROTON=1` pour éviter le crash. `COMIC_DARK=1` dans compose n'a d'effet qu'en Wine natif.

## À faire — Haut priorité

- [ ] **Clavier azerty** — Le layout xkb dans le container est pas azerty. Piste : `setxkbmap fr` dans `startwm_wayland.sh` ou via xsettingsd. Ne peut être testé que depuis l'UI (pas depuis `docker exec` sans XAUTHORITY)

## À faire — Bas priorité

- [ ] **Lancement différé** — ComicRack se lance dès le démarrage du container même si personne ne se connecte. Option : `AUTO_START=0` + bouton dans l'UI, ou attendre la première connexion WebSocket avant de lancer
- [ ] **Fond d'écran** — Le bureau labwc est noir. Option : image of the day via un script background (feh ou eog)
- [ ] **Cursor pack Windows** — `CURSOR_PACK=1` dans compose mais les curseurs `.cur` ne sont pas appliqués via le registre Wine dans le prefix Proton. À déboguer si le curseur par défaut n'est pas satisfaisant

## Architecture / notes

```
docker-compose.yml
  volumes:
    ./library  → /library   (comics .cbz)
    ./data     → /data      (AppData ComicRack, persistant)
    ./import   → /import    (Plugins + Scripts à copier au boot)
    comicrack-config → /config  (prefix Wine/Proton, cache)

  volumes supplémentaire:
    ./data/comicrack → /config/.wine/pfx/…/cYo/ComicRack Community Edition
      (volume bind direct dans le prefix — pas de symlink, Wine ne suit pas les symlinks vers des volumes extérieurs)

  env clés:
    PIXELFLUX_WAYLAND=true   → Selkies en mode Wayland
    USE_PROTON=1             → proton run au lieu de wine
    COMIC_DARK=1             → UseDarkMode dans ini (Wine natif uniquement, crash sous Proton)
    CURSOR_SIZE=32           → XCURSOR_SIZE (Wayland) + CursorBaseSize (Wine)
    WINE_DPI=150             → LogPixels dans le registre Wine

start.sh flow:
  1. Détecte XWayland (scan /tmp/.X11-unix/)
  2. Init prefix si nécessaire (wineboot via proton)
  3. Fix perms /library
  4. Copy plugins/scripts depuis /import vers /data/comicrack/
  5. Dark mode : UseDarkMode dans ComicRack.ini si USE_PROTON=0 ; supprimé si USE_PROTON=1
  6. Winetricks (dotnet48, skip si déjà présent)
  7. DPI, curseur, polices via registre Wine
  8. exec proton run Z:\opt\comicrack\ComicRack.exe
```
