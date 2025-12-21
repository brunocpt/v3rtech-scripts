#!/usr/bin/env bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: utils/atualiza_scripts.sh
# Versão: 2.0.0 (New Structure + GitHub Fallback)
# Descrição: Sincroniza a versão de desenvolvimento para o sistema.
# ==============================================================================

# === Variáveis de Caminho ===
# Origem Local (Rede/Cloud)
LOCAL_SRC="/mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts"

# Origem Remota (GitHub)
REPO_URL="https://github.com/brunocpt/v3rtech-scripts.git"

# Destino no Sistema
SYSTEM_DST="/usr/local/share/scripts/v3rtech-scripts"

# Variáveis de Usuário
OWNER="${SUDO_USER:-$USER}"
GROUP=$(id -gn "$OWNER")

# === Cabeçalho ===
echo "========================================================"
echo "   V3RTECH SCRIPTS - ATUALIZADOR DE VERSÃO"
echo "========================================================"
echo "Data: $(date)"
echo "Destino: $SYSTEM_DST"

# === 1. Verificação da Origem ===
USE_GIT=false

if [ -d "$LOCAL_SRC" ]; then
    echo "[INFO] Origem local detectada: $LOCAL_SRC"
    SRC_DIR="$LOCAL_SRC"
else
    echo "[WARN] Origem local não encontrada (Drive não montado?)"
    echo "[INFO] Alternando para modo GitHub..."
    USE_GIT=true
fi

# === 2. Processo de Atualização ===

# Cria diretório de destino se não existir
if [ ! -d "$SYSTEM_DST" ]; then
    echo "[INFO] Criando diretório de destino..."
    sudo mkdir -p "$SYSTEM_DST"
    sudo chown "$USER:$USER" "$SYSTEM_DST" # Temporário para git clone funcionar sem sudo
fi

if [ "$USE_GIT" = true ]; then
    # --- MODO GITHUB ---

    # Verifica se o destino já é um repositório git
    if [ -d "$SYSTEM_DST/.git" ]; then
        echo "[STEP] Atualizando repositório existente (git pull)..."
        # Força reset para garantir que arquivos locais modificados não travem o pull
        sudo git -C "$SYSTEM_DST" fetch --all
        sudo git -C "$SYSTEM_DST" reset --hard origin/main
        sudo git -C "$SYSTEM_DST" pull origin main
    else
        echo "[STEP] Clonando repositório do zero..."
        # Clona direto para o destino
        sudo git clone "$REPO_URL" "$SYSTEM_DST"
    fi

    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Atualização via GitHub concluída."
    else
        echo "[ERROR] Falha ao atualizar via GitHub."
        exit 1
    fi

else
    # --- MODO LOCAL (RSYNC) ---

    echo "[STEP] Sincronizando arquivos locais (Rsync)..."

    # Exclui .git da cópia local para não quebrar versionamento futuro se houver
    sudo rsync -avhP --delete \
        --exclude '.git' \
        --exclude '*.tmp' \
        "$SRC_DIR/" "$SYSTEM_DST/"

    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Sincronização local concluída."
    else
        echo "[ERROR] Falha no Rsync."
        exit 1
    fi
fi

# === 3. Ajuste de Permissões e Links ===
echo ""
echo "[STEP] Ajustando permissões e links simbólicos..."

# Define root como dono final da pasta de sistema
sudo chown -R root:root "$SYSTEM_DST"

# Define permissões: Pastas 755, Arquivos 644
sudo find "$SYSTEM_DST" -type d -exec chmod 755 {} +
sudo find "$SYSTEM_DST" -type f -exec chmod 644 {} +

# Scripts executáveis (.sh) e binários na pasta bin/ ou utils/ devem ser 755
sudo find "$SYSTEM_DST" -name "*.sh" -exec chmod +x {} +
if [ -d "$SYSTEM_DST/bin" ]; then
    sudo chmod +x "$SYSTEM_DST/bin"/*
fi
if [ -d "$SYSTEM_DST/utils" ]; then
    sudo chmod +x "$SYSTEM_DST/utils"/*
fi

# Recria links simbólicos em /usr/local/bin para os utilitários
echo "[STEP] Atualizando links em /usr/local/bin..."
if [ -d "$SYSTEM_DST/utils" ]; then
    for script in "$SYSTEM_DST/utils"/*; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            script_name=$(basename "$script")
            # Remove extensão .sh do link para ficar mais elegante (opcional, mantive com .sh se preferir)
            # sudo ln -sf "$script" "/usr/local/bin/${script_name%.sh}"

            # Mantém nome original
            sudo ln -sf "$script" "/usr/local/bin/$script_name"
            echo " -> Link criado: $script_name"
        fi
    done
fi

# === 4. Exceções de Segurança (Chaves SSH/GPG) ===
# Se existirem chaves sensíveis copiadas, garante que só o dono original ou root leia
KEYS_DIR="$SYSTEM_DST/configs/ssh-keys"
if [ -d "$KEYS_DIR" ]; then
    echo "[SEC] Ajustando permissões de chaves SSH..."
    # Tenta definir o dono para o usuário real (SUDO_USER) se for para uso pessoal,
    # ou root se for servidor. Como é /usr/local/share, root 600 é mais seguro.
    sudo chmod 700 "$KEYS_DIR"
    sudo find "$KEYS_DIR" -type f -exec chmod 600 {} +
fi

echo ""
echo "========================================================"
echo "   ATUALIZAÇÃO FINALIZADA COM SUCESSO"
echo "========================================================"
