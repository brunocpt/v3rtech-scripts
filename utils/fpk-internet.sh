#!/bin/bash
# Script de instalação de aplicativos para Internet via flatpak

echo
echo "Instalando aplicativos para internet..."

# --- Google Chrome ---
if [ -x /usr/bin/google-chrome ] || [ -x /usr/bin/google-chrome-beta ]; then
  echo "[OK] Google Chrome já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub com.google.Chrome
  if [ -f "/usr/local/share/scripts/config/chrome-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/chrome-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/com.google.Chrome/
    unzip -o chrome-flatpak-$USER.zip && rm chrome-flatpak-$USER.zip
  fi
fi

# --- Vivaldi ---
if [ -x /usr/bin/vivaldi ] || [ -x /usr/bin/vivaldi-snapshot ]; then
  echo "[OK] Google Chrome já está instalado no sistema (via gerenciador nativo)."
else
  echo "Instalando Vivaldi..."
  sudo flatpak install -y flathub com.vivaldi.Vivaldi
  if [ -f "/usr/local/share/scripts/config/vivaldi-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/vivaldi-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/com.vivaldi.Vivaldi/
    unzip -o vivaldi-flatpak-$USER.zip && rm vivaldi-flatpak-$USER.zip
  fi
fi

# --- Brave ---
if [ -x /usr/bin/brave ] || [ -x /usr/bin/brave-browser ]; then
  echo "[OK] Brave Browser já está instalado no sistema (via gerenciador nativo)."
else
  echo "Instalando Brave..."
  sudo flatpak install -y flathub com.brave.Browser
  if [ -f "/usr/local/share/scripts/config/brave-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/brave-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/com.brave.Browser/
    unzip -o brave-flatpak-$USER.zip && rm brave-flatpak-$USER.zip
  fi
fi

# --- Microsoft Edge ---
#sudo flatpak install -y flathub-beta com.microsoft.Edge
#if [ -f "/usr/local/share/scripts/config/edge-flatpak-$USER.zip" ]; then
#  cp /usr/local/share/scripts/config/edge-flatpak-$USER.zip $HOME
#  cd $HOME
#  rm -rf .var/local/com.microsoft.Edge/
#  unzip -o edge-flatpak-$USER.zip && rm edge-flatpak-$USER.zip
#fi

# --- Opera ---
if [ -x /usr/bin/opera ] ; then
  echo "[OK] Opera já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub com.opera.Opera
  if [ -f "/usr/local/share/scripts/config/opera-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/opera-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/com.opera.Opera/
    unzip -o opera-flatpak-$USER.zip && rm opera-flatpak-$USER.zip
  fi
fi

# --- Firefox ---
if [ -x /usr/bin/firefox ] || [ -x /usr/bin/firefox-beta ]; then
  echo "[OK] Firefox já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub org.mozilla.firefox
  if [ -f "/usr/local/share/scripts/config/firefox-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/firefox-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/org.mozilla.firefox/
    unzip -o firefox-flatpak-$USER.zip && rm firefox-flatpak-$USER.zip
  fi
fi

# --- Zen Browser ---
#sudo flatpak install -y flathub app.zen_browser.zen
#if [ -f "/usr/local/share/scripts/config/zen-flatpak-$USER.zip" ]; then
#  cp /usr/local/share/scripts/config/zen-flatpak-$USER.zip $HOME
#  cd $HOME
#  rm -rf .var/local/app.zen_browser.zen/
#  unzip -o zen-flatpak-$USER.zip && rm zen-flatpak-$USER.zip
#fi

# --- Wavebox ---
if [ -x /opt/wavebox.io/wavebox/wavebox ]; then
  echo "[OK] Wavebox já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub io.wavebox.Wavebox
  flatpak override --user io.wavebox.Wavebox --talk-name=org.freedesktop.secrets
  flatpak override --user io.wavebox.Wavebox --filesystem=xdg-config/keyrings
  #if [ -f "/usr/local/share/scripts/config/wavebox-flatpak-$USER.zip" ]; then
  #  cp /usr/local/share/scripts/config/wavebox-flatpak-$USER.zip $HOME
  #  cd $HOME
  #  rm -rf .var/local/io.wavebox.Wavebox/
  #  unzip -o wavebox-flatpak-$USER.zip && rm wavebox-flatpak-$USER.zip
  #fi
fi

# --- Nextcloud Client ---
if [ -x /usr/bin/nextcloud ]; then
  echo "[OK] Nextcloud client já está instalado no sistema (via gerenciador nativo)."
else
  sudo flatpak install -y flathub com.nextcloud.desktopclient.nextcloud
  if [ -f "/usr/local/share/scripts/config/nextcloud-flatpak-$USER.zip" ]; then
        cp /usr/local/share/scripts/config/nextcloud-flatpak-$USER.zip $HOME
        cd $HOME
        rm -rf .var/local/com.nextcloud.desktopclient.nextcloud/
        unzip -o nextcloud-flatpak-$USER.zip && rm nextcloud-flatpak-$USER.zip
  fi
fi

# --- Filezilla ---
sudo flatpak install -y flathub org.filezillaproject.Filezilla
if [ -f "/usr/local/share/scripts/config/filezilla-flatpak-$USER.zip" ]; then
  cp /usr/local/share/scripts/config/filezilla-flatpak-$USER.zip $HOME
  cd $HOME
  rm -rf .var/local/org.filezillaproject.Filezilla/
  unzip -o filezilla-flatpak-$USER.zip && rm filezilla-flatpak-$USER.zip
fi

# --- Transmission ---
#sudo flatpak install -y flathub com.transmissionbt.Transmission
#if [ -f "/usr/local/share/scripts/config/transmission-flatpak-$USER.zip" ]; then
#  cp /usr/local/share/scripts/config/transmission-flatpak-$USER.zip $HOME
#  cd $HOME
#  rm -rf .var/local/com.transmissionbt.Transmission/
#  unzip -o transmission-flatpak-$USER.zip && rm transmission-flatpak-$USER.zip
#fi

# --- MailViewer ---
sudo flatpak install -y flathub io.github.alescdb.mailviewer

echo
echo "Instalação concluída!"

