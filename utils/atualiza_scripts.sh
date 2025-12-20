#!/usr/bin/env bash

# === Variáveis ===
SRC="/mnt/trabalho/Cloud/Compartilhado/Linux"
DST="/usr/local/share/scripts"
FONTS_DST="$HOME/.local/share/fonts"
OWNER="${SUDO_USER:-$USER}"
GROUP=$(id -gn "$OWNER")

# === Detecta distribuição ===
source /etc/os-release
DISTRO="$ID"
VARIANT="$VARIANT"

case "$DISTRO" in
  arch|rebornos|archcraft|cachyos|endeavouros|manjaro|biglinux) DISTRO="Arch" ;;
  ubuntu|elementary|neon|zorin) DISTRO="Ubuntu" ;;
  debian|lingmo|siduction) DISTRO="Debian" ;;
  fedora|rhel|nobara) DISTRO="Fedora" ;;
  solus) DISTRO="Solus" ;;
  *) DISTRO="Geral"; echo "Distro não reconhecida. Usando scripts gerais." ;;
esac

# === Informações iniciais ===
echo ""
echo "--- Atualizando scripts em $DST ---"
echo "Máquina: ${HOSTNAME:-$(cat /etc/hostname)}"
echo "Sistema: $ID"
echo "Scripts específicos: $DISTRO"
echo "Destino global: $DST"
echo "Dono padrão: root:root"
echo "Exceção (chaves): $OWNER:$GROUP"

# === Sincroniza fontes (continua local por usuário) ===
echo ""
echo "--- Sincronizando fontes ---"
echo "Fonte: $SRC/fonts/"
echo "Destino: $FONTS_DST"
mkdir -p "$FONTS_DST"

stats=$(rsync -ruhP --delete --out-format='' --stats "$SRC/fonts/" "$FONTS_DST" 2>&1)

if echo "$stats" | grep -Eq 'transferred: [1-9]|created files: [1-9]|deleted files: [1-9]'; then
  echo "Fontes foram alteradas. Atualizando cache de fontes..."
  fc-cache -fsv
  echo "Cache de fontes atualizado."
else
  echo "Nenhuma fonte foi alterada."
fi

# === Criação dos diretórios de destino ===
echo ""
echo "--- Criando estrutura de pastas globais em $DST ---"
sudo mkdir -p "$DST/atalhos"
sudo mkdir -p "$DST/config"
sudo mkdir -p "$DST/docker"
sudo mkdir -p "$DST/Geral"
sudo mkdir -p "$DST/$DISTRO"

# === Sincronização dos scripts e configs ===
echo "--- Sincronizando atalhos ---"
sudo rsync -ruhP --delete "$SRC/atalhos/" "$DST/atalhos"

echo "--- Sincronizando config ---"
sudo rsync -ruhP --delete "$SRC/config/" "$DST/config"

echo "--- Sincronizando docker ---"
sudo rsync -ruhP --delete "$SRC/docker/" "$DST/docker"

echo "--- Sincronizando scripts gerais ---"
sudo rsync -ruhP --delete "$SRC/scripts/Geral/" "$DST/Geral"

echo "--- Sincronizando scripts específicos para $DISTRO ---"
sudo rsync -ruhP --delete "$SRC/scripts/$DISTRO/" "$DST/$DISTRO"

# === Ajusta permissões ===
echo ""
echo "--- Ajustando permissões e propriedade ---"
sudo chown -R root:root "$DST"
sudo find "$DST" -type d -exec chmod 755 {} +
sudo find "$DST" -type f -exec chmod 744 {} +
sudo find "$DST/Geral" "$DST/$DISTRO" -type f \( -name "*.sh" -o -not -name "*.*" \) -exec chmod 755 {} + 2>/dev/null || true

# === Exceções para pastas de chaves ===
echo ""
echo "--- Aplicando exceções de segurança para pastas de chaves ---"
for dir in "$DST/config/keys" "$DST/config/ssh-keys"; do
  if sudo test -d "$dir"; then
    echo "Protegendo: $dir"
    sudo chown -R "$OWNER:$GROUP" "$dir"
    sudo find "$dir" -type f -exec chmod 400 {} +
    sudo chmod 700 "$dir"
  fi
done

# === Final ===
echo ""
echo "------------------------------------------------"
echo "  Atualização concluída com sucesso!"
echo "------------------------------------------------"

