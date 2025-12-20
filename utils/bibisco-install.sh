#!/usr/bin/env bash
# Instalação automatizada do Bibisco Supporters Edition no Linux

set -euo pipefail

BIBISCO_ZIP_URL="https://app.gumroad.com/r/de5d133d7feeebb307bb50d9f75721c8/product_files?product_file_ids%5B%5D=kXuLbfCN3GBNzYqwtMduuQ%3D%3D"
BIBISCO_LOCAL_ICON="/mnt/trabalho/Cloud/Compartilhado/Linux/atalhos/bibisco.png"
TMP_ZIP="/tmp/bibisco.zip"
DEST_DIR="/opt/bibisco"
BIN_LINK="/usr/local/bin/bibisco"
DESKTOP_FILE="/usr/share/applications/bibisco.desktop"

# 1. Baixa o arquivo zip
echo "Baixando Bibisco Supporters Edition..."
wget -O "$TMP_ZIP" "$BIBISCO_ZIP_URL"

# 2. Extrai para /opt/bibisco (remove antes se já existir)
echo "Extraindo para $DEST_DIR..."
sudo rm -rf "$DEST_DIR"
sudo unzip -q "$TMP_ZIP" -d /opt/
# Procura pasta extraída
EXTRACTED=$(find /opt -maxdepth 1 -type d -name "bibisco-linux*" | sort | tail -n 1)
if [ -z "$EXTRACTED" ]; then
    echo "Erro: pasta bibisco-linux* não encontrada após extração."
    exit 1
fi
sudo mv "$EXTRACTED" "$DEST_DIR"

# 3. Copia ícone (se existir)
if [ -f "$BIBISCO_LOCAL_ICON" ]; then
    sudo cp "$BIBISCO_LOCAL_ICON" "$DEST_DIR/"
fi

# 4. Permissões seguras
sudo chown -R root:root "$DEST_DIR"
sudo chmod -R 755 "$DEST_DIR"

# 5. Cria atalho no PATH
sudo ln -sf "$DEST_DIR/bibisco" "$BIN_LINK"

# 6. Cria arquivo .desktop para menu
sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Bibisco
GenericName=Bibisco
Comment=Bibisco is a novel writing software that helps you to write your novel, in a simple way.
Exec=$BIN_LINK %F
Icon=$DEST_DIR/bibisco.png
NoDisplay=false
Terminal=false
Categories=Office;
StartupNotify=true
EOF

echo "Instalação concluída! Procure por 'Bibisco' no menu de aplicativos ou execute 'bibisco' no terminal."

