#!/bin/bash
# Script para instalar o Zotero manualmente no Linux

set -e

echo "--- Baixando a versão beta do Zotero ---"
curl -Lo /tmp/zotero.tar.xz "https://www.zotero.org/download/client/dl?platform=linux-x86_64&channel=beta"

cd /tmp/
tar -xvf zotero.tar.bz2
cd Zotero*

sudo mkdir -p /opt/zotero/
sudo cp /mnt/trabalho/Cloud/Compartilhado/Linux/atalhos/zotero.png /opt/zotero/
sudo cp -Rf ./* /opt/zotero/
sudo chown -R root:users /opt/zotero/
sudo chmod -R 775 /opt/zotero/

sudo ln -sf /opt/zotero/zotero /usr/bin/zotero

# Cria atalho no menu
cat << EOF | sudo tee /usr/share/applications/zotero.desktop > /dev/null
[Desktop Entry]
Type=Application
Version=8
Encoding=UTF-8
Name=Zotero
Comment=Launch Zotero
Icon=/opt/zotero/zotero.png
Exec=zotero
Terminal=false
StartupNotify=true
Categories=Office;
EOF

echo "Instalação concluída!"

