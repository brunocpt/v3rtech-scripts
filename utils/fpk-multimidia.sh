#!/bin/bash
# Script de instalação de aplicativos para Escritório via flatpak

# GIMP (Image Manipulator)
if [ -x /usr/bin/gimp ]; then
  echo "[OK] GIMP já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.gimp.GIMP
fi

# Inkscape Vector Illustrator
if [ -x /usr/bin/inkscape ]; then
  echo "[OK] Inkscape já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.inkscape.Inkscape
fi

# Upscayl
#  sudo flatpak install -y flathub org.upscayl.Upscayl

# PenPot
#  sudo flatpak install -y flathub com.authormore.penpotdesktop

# FreeCAD
#if [ -x /usr/bin/freecad ]; then
  #echo "[OK] Freecad já está instalado no sistema (via gerenciador nativo)."
#else
  #sudo flatpak install -y flathub org.freecad.FreeCAD
#fi

# Scribus
#if [ -x /usr/bin/scribus ]; then
  #echo "[OK] Scribus já está instalado no sistema (via gerenciador nativo)."
#else
  #sudo flatpak install -y flathub net.scribus.Scribus
#fi

# WebPConverter
  #sudo flatpak install -y flathub io.itsterminal.WebPConverter

# OBS Studio
if [ -x /usr/bin/obs-studio ]; then
  echo "[OK] obs-studio já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub com.obsproject.Studio
fi

# Normalize Audio (substitui MP3Gain)
  sudo flatpak install -y flathub io.github.tapscodes.MuseAmp

# Picard
if [ -x /usr/bin/picard ]; then
  echo "[OK] Picard já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.musicbrainz.Picard
  if [ -f "/usr/local/share/scripts/config/picard-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/picard-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/org.musicbrainz.Picard/
    unzip -o picard-flatpak-$USER.zip && rm picard-flatpak-$USER.zip
  fi
fi

# VLC
if [ -x /usr/bin/vlc ]; then
  echo "[OK] VLC client já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.videolan.VLC
fi

# Avidemux
if [ -x /usr/bin/avidemux3_qt5 ]; then
  echo "[OK] AviDemux já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.avidemux.Avidemux
fi

# FileBot
  sudo flatpak install -y flathub net.filebot.FileBot
  flatpak run net.filebot.FileBot --license /mnt/trabalho/Cloud/Compartilhado/Linux/config/FileBot_License_PX10290120.psm
  flatpak run net.filebot.FileBot -script fn:properties --def net.filebot.WebServices.OpenSubtitles.v2=true
  flatpak run net.filebot.FileBot -script fn:configure --def osdbUser="brunocpt_" --def osdbPwd="730PiNYJ"

# FINALIZANDO A INSTALACAO
  echo "Instalacao concluida!"

