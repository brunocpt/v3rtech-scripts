#!/bin/bash
# Script para instalar o Ventoy no Linux

echo "$(tput setaf 3)--- Ventoy será instalado no sistema $(uname -ion) ---$(tput sgr0)"
echo ""

# Define o link mais recente do Ventoy x86_64 (veja https://www.ventoy.net/en/download.html para atualizar se necessário)
VENTOY_VERSION="1.1.07"
VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VERSION}/ventoy-${VENTOY_VERSION}-linux.tar.gz"

# Baixa o arquivo
echo "Baixando Ventoy ${VENTOY_VERSION}..."
wget -c "$VENTOY_URL" -O /tmp/ventoy.tar.gz

# Instalação
cd /tmp/
tar -xvzf ventoy.tar.gz
rm ventoy.tar.gz
mv ventoy-* ventoy
sudo rm -rf /opt/ventoy/
sudo mv /tmp/ventoy /opt/
sudo cp /opt/usr/local/share/scripts/atalhos/ventoy.svg /opt/ventoy/ 2>/dev/null || true
sudo chown -R root:root /opt/ventoy/
sudo chmod -R 755 /opt/ventoy/
cd /opt/ventoy/
sudo ln -sf /opt/ventoy/Ventoy2Disk.sh /usr/bin/ventoy2disk
sudo ln -sf /opt/ventoy/VentoyGUI.x86_64 /usr/bin/ventoygui
sudo ln -sf /opt/ventoy/VentoyWeb.sh /usr/bin/ventoyweb

# Lançador no menu
echo '[Desktop Entry]
Name=Ventoy GUI
Comment=GUI for Ventoy, a multi-boot USB creator
Exec=/opt/ventoy/VentoyGUI.x86_64
Terminal=false
Type=Application
Icon=/opt/ventoy/ventoy.svg
Categories=Utility;
StartupNotify=true' | sudo tee /usr/share/applications/ventoy-gui.desktop > /dev/null

echo
echo "Instalação do Ventoy concluída!"

