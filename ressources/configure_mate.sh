#!/bin/bash
# Configuration MATE - Thème sombre style macOS

# Attendre que MATE soit démarré
sleep 3

# Thème GTK sombre
gsettings set org.mate.interface gtk-theme 'Yaru-dark'
gsettings set org.mate.interface icon-theme 'Yaru'

# Thème fenêtre Marco (window manager)
gsettings set org.mate.Marco.general theme 'Yaru-dark'

# Panneau supérieur style macOS (fond sombre transparent)
gsettings set org.mate.panel.toplevel:/org/mate/panel/toplevels/top/ background-color 'rgba(0,0,0,0.8)'
gsettings set org.mate.panel.toplevel:/org/mate/panel/toplevels/top/ background-type 'color'
gsettings set org.mate.panel.toplevel:/org/mate/panel/toplevels/top/ expand true
gsettings set org.mate.panel.toplevel:/org/mate/panel/toplevels/top/ size 32

# Police système
gsettings set org.mate.interface font-name 'Ubuntu 11'
gsettings set org.mate.interface document-font-name 'Ubuntu 11'
gsettings set org.mate.interface monospace-font-name 'Ubuntu Mono 13'

# Gestionnaire de fichiers Caja - thème sombre
gsettings set org.mate.caja.preferences theme 'dark'

# Fond d'écran sombre uni
gsettings set org.mate.background picture-filename ''
gsettings set org.mate.background primary-color '#1a1a1a'
gsettings set org.mate.background color-shading-type 'solid'

# Animations fluides
gsettings set org.mate.Marco.general compositing-manager true
gsettings set org.mate.Marco.general reduced-resources false

# Boutons fenêtre style macOS (fermer à gauche)
gsettings set org.mate.Marco.general button-layout 'close,minimize,maximize:'

echo "MATE configuré avec thème sombre style macOS"
