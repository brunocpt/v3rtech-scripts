#!/bin/bash
# Script de instalação de aplicativos para Escritório via flatpak

# Obsidian
if [ -x /usr/bin/obsidian ]; then
  echo "[OK] Obsidian já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub flathub md.obsidian.Obsidian
  if [ -f "/usr/local/share/scripts/config/obsidian-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/obsidian-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/md.obsidian.Obsidian/
    unzip -o obsidian-flatpak-$USER.zip
    rm obsidian-flatpak-$USER.zip
  fi
fi

# Sejda Desktop
if [ -x /usr/bin/sejda ]; then
  echo "[OK] Sejda já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub com.sejda.Sejda
fi

# Calibre
if [ -x /usr/bin/calibre ]; then
  echo "[OK] Calibre já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub com.calibre_ebook.calibre
  if [ -f "/usr/local/share/scripts/config/calibre-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/calibre-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/com.calibre_ebook.calibre/
    unzip -o calibre-flatpak-$USER.zip
    rm calibre-flatpak-$USER.zip
  fi
fi

# Libreoffice
if [ -x /usr/bin/libreoffice ]; then
  echo "[OK] LibreOffice já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.libreoffice.LibreOffice
fi

# XMind
if [ -x /usr/bin/XMind ]; then
  echo "[OK] XMind já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak -y install net.xmind.XMind
fi

# Zotero
if [ -x /usr/bin/zotero ]; then
  echo "[OK] Zotero já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.zotero.Zotero
  if [ -f "/usr/local/share/scripts/config/zotero-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/zotero-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/org.zotero.Zotero/
    unzip -o zotero-flatpak-$USER.zip
    rm zotero-flatpak-$USER.zip
  fi
fi

# Tintero
  sudo flatpak install -y flathub app.tintero.Tintero
  if [ -f "/usr/local/share/scripts/config/tintero-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/tintero-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/org.zotero.Zotero/
    unzip -o tintero-flatpak-$USER.zip
    rm tintero-flatpak-$USER.zip
  fi

# Draw.io
  sudo flatpak install -y flathub com.jgraph.drawio.desktop

# Dialect
#  sudo flatpak install -y flathub app.drey.Dialect

# Document Scanner
#  sudo flatpak install -y flathub org.gnome.SimpleScan

# FINALIZANDO A INSTALACAO
  echo "Instalacao concluida!"


