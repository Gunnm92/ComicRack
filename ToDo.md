La solution est maintenant fonctionnel en terme d'affichage ce qui reste à faire : 

Critique : 
- La lecture écriture ne fonctionne pas les covers ne s'affiche pas (sans doute lier au souci de lecture écriture sur le dossier library)
  - Statut: corrigé via commit 21709aa (mount /library + FIX_LIBRARY_PERMS + test write OK).

- La persistence des données à chaque reconstruction on efface tout paramétre et librairie il faut le rendre persistent. 
  - Statut: corrigé via commit 31ffd5c (AppData ComicRack redirigé vers /data/comicrack).

Analyse / pistes :
- R/W Library : vérifier UID/GID effectifs dans le conteneur et les droits sur le dossier host (./library). Si le conteneur tourne en user 1000:1000, le dossier host doit être writable par 1000:1000. Si besoin, créer un volume séparé /data et monter en RW.
- Persistance : séparer le prefix Proton/Wine et les données app dans un volume dédié (ex: /data). Lier AppData (cYo) + config + cache dans /data. Éviter que les assets de l’image soient re‑extraits à chaque rebuild dans le même dossier que les données.

Haut :
- Distinguer la notion d'installation et de service dans le script start 

- La langue française ne s'installe pas dans comicrack il n'y a que l'anglais 

- Le mode dark de comicrack ne s'applique pas 

- Créer un mapping pour : 
    - Library => Contient la library 
    - Data contient les données de l'application & paramétre avec un dossier import pour déposer les plugin comicrack  
  - Statut: corrigé via commit 21709aa (volumes /library /data /import + copie plugins/scripts).
  - Gitignore: data/ + import/ ajoutés (commit 0e74c80).
    
Analyse / pistes :
- Installation vs service : scinder start.sh (init: prefix/pack/registry) et run.sh (lancement). Ajouter un marker pour init une seule fois.
- Langue FR : vérifier présence du zip langue dans /opt/comicrack/Languages et/ou copier vers AppData (cYo). Peut nécessiter un import dans le dossier data utilisateur.
- Dark mode : vérifier le mode compatible avec CE/Proton (option CLI ou config). Si -dark non supporté, forcer via paramètre dans Config.xml.
- Mapping Data : créer volumes /data (persist), /library (media), /import (plugins). Définir chemins dans variables et copier plugins au boot.
  - Tests Docker: `docker compose up -d --build`, `touch /library/.rw_test` en user 1000 OK, symlink AppData → `/data/comicrack`.

Bas :
- Voir si on peut modifier la font pas le standard microsoft la elles sont très moche (peut ajouter des fonts winetricks)

- Augementer legerement le cursor tester la valeur 38 par exemple 

- Mettre les variables d'environnement par defaut aligné sur le docker compose pour n'avoir qu'a surchargé lorsque c'est absolument nécéssaire fixer le title 'ComicRack-Web' 

- Fixer le clavier dans le terminal il est ni azerty ni qwerty voir d'ou viens l'erreur. 

- Voir il est possible de lancer comicrack lorsque la fenetre est rééllement afficher (éviter que le docker consomme de la ressources inutilement) ou ajouter un raccourci pour le lancer 

- Voir si on peut changer le fond d'ecran noir par une image of the day 

Analyse / pistes :
- Fonts : installer corefonts + liberation + noto (ou ttf‑mscorefonts si dispo). Définir FontSubstitutes via registry et vérifier rendu.
- Cursor : côté Wayland, régler XCURSOR_SIZE + xsettingsd. Côté Wine/Proton, vérifier UseXCursor + CursorBaseSize.
- Variables par défaut : déplacer les defaults dans start.sh, alignés avec docker-compose (TITLE, DPI, etc.).
- Clavier terminal : vérifier layout Openbox/xkb (setxkbmap fr). Peut venir de Selkies/xsettingsd.
- Lancement différé : attendre socket Wayland/X + première connexion web avant de lancer. Option “AUTO_START=0” + script manuel.
- Fond d’écran : set background via openbox/autostart (feh) ou script qui télécharge “image of the day”.
