#!/bin/bash

echo "$(tput setaf 3)--- Instalando ferramentas de desenvolvimento ---$(tput sgr0)"

# --- Visual Studio Code ---
if [ -x /usr/bin/code ]; then
  echo "[OK] Visual Studio Code já está instalado no sistema (via gerenciador nativo)."
else
  if ! flatpak list | grep -q com.visualstudio.code; then
    sudo flatpak install -y flathub com.visualstudio.code
    # Restaura configurações do VSCode, se arquivo zip existir
    if [ -f "/usr/local/share/scripts/config/vscode-flatpak-$USER.zip" ]; then
      cp /usr/local/share/scripts/config/vscode-flatpak-$USER.zip $HOME
      cd $HOME
      rm -rf .var/local/com.visualstudio.code/
      unzip -o vscode-flatpak-$USER.zip && rm vscode-flatpak-$USER.zip
    fi
  fi
fi

# --- PyCharm ---
#if ! flatpak list | grep -q com.jetbrains.PyCharm-Professional; then
  #sudo flatpak install -y flathub com.jetbrains.PyCharm-Professional
  ## Restaura configurações do PyCharm, se arquivo zip existir
  #if [ -f "/usr/local/share/scripts/config/pycharm-flatpak-$USER.zip" ]; then
    #cp /usr/local/share/scripts/config/pycharm-flatpak-$USER.zip $HOME
    #cd $HOME
    #rm -rf .var/local/com.jetbrains.PyCharm-Professional/
    #unzip -o pycharm-flatpak-$USER.zip && rm pycharm-flatpak-$USER.zip
  #fi
#fi

# --- DBeaver ---
if ! flatpak list | grep -q io.dbeaver.DBeaverCommunity; then
  sudo flatpak install -y flathub io.dbeaver.DBeaverCommunity
  # Restaura configurações do DBeaver, se arquivo zip existir
  if [ -f "/usr/local/share/scripts/config/dbeaver-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/dbeaver-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/io.dbeaver.DBeaverCommunity/
    unzip -o dbeaver-flatpak-$USER.zip && rm dbeaver-flatpak-$USER.zip
  fi
fi

# --- Postman ---
if ! flatpak list | grep -q com.getpostman.Postman; then
  sudo flatpak install -y flathub com.getpostman.Postman
  # Restaura configurações do Postman, se arquivo zip existir
  if [ -f "/usr/local/share/scripts/config/postman-flatpak-$USER.zip" ]; then
    cp /usr/local/share/scripts/config/postman-flatpak-$USER.zip $HOME
    cd $HOME
    rm -rf .var/local/com.getpostman.Postman/
    unzip -o postman-flatpak-$USER.zip && rm postman-flatpak-$USER.zip
  fi
fi

# --- Remmina ---
if [ -x /usr/bin/remmina ]; then
  echo "[OK] Remmina já está instalado no sistema (via gerenciador nativo)."
else
  if ! flatpak list | grep -q org.remmina.Remmina; then
    sudo flatpak install -y flathub org.remmina.Remmina
    # Restaura configurações do Remmina, se arquivo zip existir
    if [ -f "/usr/local/share/scripts/config/remmina-flatpak-$USER.zip" ]; then
      cp /usr/local/share/scripts/config/remmina-flatpak-$USER.zip $HOME
      cd $HOME
      rm -rf .var/local/org.remmina.Remmina/
      unzip -o remmina-flatpak-$USER.zip && rm remmina-flatpak-$USER.zip
    fi
  fi
fi

echo "Instalação concluída!"

