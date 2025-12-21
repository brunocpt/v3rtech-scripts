#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/03-prepara-configs.sh
# Versão: 8.0.0 (Com Desktop Entries)
#
# Descrição: Configurações profundas do sistema.
# Funcionalidades:
#   1. PATH idempotente com marcadores de bloco
#   2. Limpeza de PATH de entradas repetidas
#   3. Aliases com proteção contra duplicação
#   4. Desktop entries para scripts utilitários
#   5. Links simbólicos em /usr/local/bin
#   6. Instalação de fontes
#   7. Configuração de tema de boot (Plymouth)
# ==============================================================================

log "STEP" "Iniciando Configurações Gerais de Sistema..."

# Variáveis de Caminho
INSTALL_TARGET="/usr/local/share/scripts/v3rtech-scripts"
UTILS_DIR="$INSTALL_TARGET/utils"
CONFIG_DIR="$INSTALL_TARGET/configs"
RESOURCES_DIR="$INSTALL_TARGET/resources"
SYSTEM_BASHRC="/etc/bash.bashrc"

# ==============================================================================
# FUNÇÃO: Limpar PATH de Entradas Repetidas
# ==============================================================================
clean_path() {
    local path_var="$1"
    local cleaned=""
    
    # Declara array associativo para rastrear componentes já vistos
    declare -A seen
    
    # Divide o PATH em componentes e remove duplicatas
    IFS=':' read -ra components <<< "$path_var"
    
    for component in "${components[@]}"; do
        # Pula entradas vazias
        if [ -z "$component" ]; then
            continue
        fi
        
        # Se não foi visto antes, adiciona
        if [ -z "${seen[$component]:-}" ]; then
            if [ -z "$cleaned" ]; then
                cleaned="$component"
            else
                cleaned="$cleaned:$component"
            fi
            seen[$component]=1
        fi
    done
    
    echo "$cleaned"
}

# ==============================================================================
# 1. CONFIGURAÇÃO DE PATH
# ==============================================================================
log "INFO" "Configurando PATH global..."

# Detecta PATH duplicado
CURRENT_PATH=$(clean_path "$PATH")
if [ "$CURRENT_PATH" != "$PATH" ]; then
    log "WARN" "PATH contém duplicatas. Limpando..."
    export PATH="$CURRENT_PATH"
fi

# Adiciona PATH do projeto (se ainda não estiver)
if [[ ":$PATH:" != *":$UTILS_DIR:"* ]]; then
    log "INFO" "Adicionando $UTILS_DIR ao PATH..."
    
    # Remove bloco antigo se existir
    $SUDO sed -i '/# === V3RTECH SCRIPTS: Global PATH BEGIN ===/,/# === V3RTECH SCRIPTS: Global PATH END ===/d' "$SYSTEM_BASHRC"
    
    # Adiciona novo bloco
    {
        echo "# === V3RTECH SCRIPTS: Global PATH BEGIN ==="
        echo "if [ -d \"$UTILS_DIR\" ]; then"
        echo "    case \":\$PATH:\" in"
        echo "        *:\"$UTILS_DIR\":*) ;;"
        echo "        *) export PATH=\"\$PATH:$UTILS_DIR\" ;;"
        echo "    esac"
        echo "fi"
        echo "# === V3RTECH SCRIPTS: Global PATH END ==="
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null
    
    log "SUCCESS" "PATH configurado"
fi

# ==============================================================================
# 2. CONFIGURAÇÃO DE ALIASES
# ==============================================================================
log "INFO" "Configurando aliases..."

ALIASES_FILE="$CONFIG_DIR/aliases.geral"

if [ -f "$ALIASES_FILE" ]; then
    # Remove bloco antigo se existir
    $SUDO sed -i '/# === V3RTECH SCRIPTS: Global Aliases BEGIN ===/,/# === V3RTECH SCRIPTS: Global Aliases END ===/d' "$SYSTEM_BASHRC"
    
    # Adiciona novo bloco
    {
        echo "# === V3RTECH SCRIPTS: Global Aliases BEGIN ==="
        cat "$ALIASES_FILE"
        echo "# === V3RTECH SCRIPTS: Global Aliases END ==="
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null
    
    log "SUCCESS" "Aliases configurados"
fi

# ==============================================================================
# 3. PERMISSÕES DE SCRIPTS
# ==============================================================================
log "INFO" "Ajustando permissões de scripts..."

if [ -d "$UTILS_DIR" ]; then
    $SUDO chmod +x "$UTILS_DIR"/* 2>/dev/null || true
    log "SUCCESS" "Permissões ajustadas"
fi

# ==============================================================================
# 4. DESKTOP ENTRIES
# ==============================================================================
log "INFO" "Criando desktop entries para scripts utilitários..."

LOCATION_DEST="/usr/share/applications"
SCRIPT_BASE="$UTILS_DIR"
ICON_BASE="$RESOURCES_DIR/atalhos"

# Cria pasta de destino, se necessário
$SUDO mkdir -p "$LOCATION_DEST"

# Array de entradas: "id|nome|script|ícone"
ENTRADAS=(
    "metaflatpaks|Instalador de Metapacks Flatpaks|metaflatpaks.sh|metapacks.svg"
    "cpa|Copiador de Pastas|cpa|cpa.svg"
    "cpplay|Copiador de Playlists para Pendrive|cpplay.sh|cpplay.svg"
    "upall|Atualizador de Aplicativos|upall.sh|upall.svg"
    "wtt|Whisper Transcriber|wtt.sh|wtt.svg"
    "extrai-legendas|Extrai Legendas|extrai-legendas.sh|extrai-legendas.svg"
    "video-converter-gui|Converte arquivos de vídeo|video-converter-gui.sh|video-converter-gui.svg"
    "restaura-config|Restaurar Configurações|restaura-config.sh|restaura-config.svg"
    "configs-zip|Backup de Configurações Pessoais|configs-zip.sh|configs-zip.svg"
)

DESKTOP_ENTRIES_CREATED=0
DESKTOP_ENTRIES_FAILED=0

for entry in "${ENTRADAS[@]}"; do
    IFS="|" read -r file name script_file icon_file <<< "$entry"
    
    EXEC_CMD="$SCRIPT_BASE/$script_file"
    ICON_PATH="$ICON_BASE/$icon_file"
    DESKTOP_FILE="$LOCATION_DEST/${file}.desktop"
    
    # Verifica se o script existe e é executável
    if [ ! -f "$EXEC_CMD" ]; then
        log "WARN" "Script não encontrado: $EXEC_CMD"
        ((DESKTOP_ENTRIES_FAILED++))
        continue
    fi
    
    # Torna o script executável
    $SUDO chmod +x "$EXEC_CMD" 2>/dev/null || true
    
    # Verifica se o ícone existe
    if [ ! -f "$ICON_PATH" ]; then
        log "WARN" "Ícone não encontrado: $ICON_PATH (usando ícone padrão)"
        ICON_PATH="application-x-executable"
    fi
    
    # Cria o arquivo .desktop
    log "DEBUG" "Criando desktop entry: $file"
    
    $SUDO tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=$name
Comment=
Exec=$EXEC_CMD
Icon=$ICON_PATH
Type=Application
Terminal=false
NoDisplay=false
Categories=Utility
X-KDE-Trusted=true
EOF
    
    # Ajusta permissões do arquivo .desktop
    $SUDO chmod 644 "$DESKTOP_FILE"
    
    log "SUCCESS" "✓ Desktop entry criada: $file"
    ((DESKTOP_ENTRIES_CREATED++))
done

log "INFO" "Desktop entries: $DESKTOP_ENTRIES_CREATED criadas, $DESKTOP_ENTRIES_FAILED falhadas"

# ==============================================================================
# 5. RESTAURAÇÃO DE CONFIGURAÇÕES
# ==============================================================================
log "INFO" "Restaurando configurações de usuário..."

CONFIG_SRC_DIR="$CONFIG_DIR/user-configs"
CUSTOM_BASHRC="$CONFIG_DIR/.bashrc"

if [ -f "$CUSTOM_BASHRC" ]; then
    if [ -f "$REAL_HOME/.bashrc" ]; then
        log "INFO" "Fazendo backup de .bashrc..."
        cp "$REAL_HOME/.bashrc" "$REAL_HOME/.bashrc.bak"
        cat "$CUSTOM_BASHRC" >> "$REAL_HOME/.bashrc"
    fi
fi

# Restaura Zips
if [ -d "$CONFIG_SRC_DIR" ]; then
    for zipfile in "$CONFIG_SRC_DIR"/*.zip; do
        [ -e "$zipfile" ] || continue
        filename=$(basename "$zipfile")
        log "INFO" "Restaurando configurações: $filename..."
        unzip -o -q "$zipfile" -d "$REAL_HOME/"
    done
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME"
fi

# ==============================================================================
# 6. INSTALAÇÃO DE SCRIPTS UTILITÁRIOS (LINKS)
# ==============================================================================
log "INFO" "Criando links simbólicos..."

# Cria links em /usr/local/bin (Garantia extra caso o PATH falhe)
if [ -d "$UTILS_DIR" ]; then
    LINKS_CREATED=0
    for script in "$UTILS_DIR"/*; do
        [ -e "$script" ] || continue
        script_name=$(basename "$script")
        
        # Pula arquivos que não são executáveis
        [ -x "$script" ] || continue
        
        $SUDO ln -sf "$script" "/usr/local/bin/$script_name"
        ((LINKS_CREATED++))
    done
    
    log "SUCCESS" "✓ $LINKS_CREATED links simbólicos criados"
fi

# Fontes
if [ -d "$RESOURCES_DIR/fonts" ]; then
    log "INFO" "Instalando fontes..."
    $SUDO mkdir -p /usr/share/fonts/v3rtech
    $SUDO cp -r "$RESOURCES_DIR/fonts/"* /usr/share/fonts/v3rtech/ 2>/dev/null || true
    
    if command -v fc-cache &>/dev/null; then
        $SUDO fc-cache -f
        log "SUCCESS" "Fontes instaladas"
    fi
fi

# ==============================================================================
# 7. CONFIGURAÇÃO VISUAL DE BOOT (PLYMOUTH)
# ==============================================================================
log "INFO" "Verificando tema de boot..."

if ! command -v plymouth &>/dev/null; then
    if command -v apt &>/dev/null; then
        log "INFO" "Instalando Plymouth..."
        $SUDO apt install -y plymouth plymouth-themes 2>/dev/null || true
    fi
fi

if command -v plymouth-set-default-theme &>/dev/null; then
    if [ -d "/usr/share/plymouth/themes/spinner" ]; then
        $SUDO plymouth-set-default-theme -R spinner 2>/dev/null || true
    elif [ -d "/usr/share/plymouth/themes/bgrt" ]; then
        $SUDO plymouth-set-default-theme -R bgrt 2>/dev/null || true
    fi
fi

# ==============================================================================
# RESUMO FINAL
# ==============================================================================

log "SUCCESS" "✓ Configurações aplicadas com sucesso."
log "INFO" "Reinicie o terminal para aplicar mudanças de PATH e aliases."
