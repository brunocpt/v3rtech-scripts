#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/03-prepara-configs.sh
# Versão: 7.0.0 (PATH Idempotente + Limpeza de Duplicatas - Bug Fix)
#
# Descrição: Configurações profundas do sistema.
# Correções:
#   1. PATH agora usa marcadores de bloco para remoção segura (verdadeiramente idempotente)
#   2. Função para limpar PATH de entradas repetidas (com array associativo corrigido)
#   3. Garante chmod +x na pasta utils para que os scripts sejam achados.
#   4. Aliases com proteção contra duplicação
#   5. Integração com desktop entries e atalhos de teclado
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
# 1. LIMPEZA DE PATH DUPLICADO (SE EXISTIR)
# ==============================================================================
log "INFO" "Verificando se há entradas duplicadas no PATH..."

# Verifica se há duplicatas no PATH atual
if [ -n "$PATH" ]; then
    CLEANED_PATH=$(clean_path "$PATH")
    
    if [ "$CLEANED_PATH" != "$PATH" ]; then
        log "WARN" "PATH contém entradas duplicadas. Limpando..."
        export PATH="$CLEANED_PATH"
        
        # Também limpa no bashrc se houver duplicatas
        if grep -q "export PATH=" "$SYSTEM_BASHRC" 2>/dev/null; then
            log "INFO" "Removendo entradas duplicadas do $SYSTEM_BASHRC..."
            
            # Extrai o PATH do bashrc, limpa e reescreve
            BASHRC_PATH=$(grep "^export PATH=" "$SYSTEM_BASHRC" | head -1 | sed 's/export PATH=//' | sed 's/"//g' || true)
            if [ -n "$BASHRC_PATH" ]; then
                CLEANED_BASHRC_PATH=$(clean_path "$BASHRC_PATH")
                $SUDO sed -i 's|^export PATH=.*|export PATH="'"$CLEANED_BASHRC_PATH"'"|' "$SYSTEM_BASHRC"
                log "SUCCESS" "PATH limpado e atualizado no $SYSTEM_BASHRC"
            fi
        fi
    else
        log "SUCCESS" "PATH sem duplicatas."
    fi
fi

# ==============================================================================
# 2. CONFIGURAÇÃO DE PATH GLOBAL INTELIGENTE (IDEMPOTENTE)
# ==============================================================================
log "INFO" "Configurando PATH global (com proteção anti-duplicação)..."

# Remove TODAS as configurações antigas do V3RTECH (usando marcadores de bloco)
if grep -q "# === V3RTECH SCRIPTS: Global PATH BEGIN ===" "$SYSTEM_BASHRC"; then
    log "INFO" "Removendo configuração de PATH antiga para atualização..."
    $SUDO sed -i '/# === V3RTECH SCRIPTS: Global PATH BEGIN ===/,/# === V3RTECH SCRIPTS: Global PATH END ===/d' "$SYSTEM_BASHRC"
fi

# Injeta o código inteligente com marcadores de bloco
if ! grep -q "# === V3RTECH SCRIPTS: Global PATH BEGIN ===" "$SYSTEM_BASHRC"; then
    log "INFO" "Injetando lógica de PATH no $SYSTEM_BASHRC..."

    {
        echo ""
        echo "# === V3RTECH SCRIPTS: Global PATH BEGIN ==="
        echo "if [ -d \"$UTILS_DIR\" ]; then"
        echo "    case \":\$PATH:\" in"
        echo "        *:\"$UTILS_DIR\":*) ;;"
        echo "        *) export PATH=\"\$PATH:$UTILS_DIR\" ;;"
        echo "    esac"
        echo "fi"
        echo "# === V3RTECH SCRIPTS: Global PATH END ==="
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null

    log "SUCCESS" "PATH configurado. Reinicie o terminal para testar."
else
    log "INFO" "PATH inteligente já configurado."
fi

# ==============================================================================
# 3. PERMISSÕES DE EXECUÇÃO (CRÍTICO)
# ==============================================================================
log "INFO" "Ajustando permissões de execução dos utilitários..."

if [ -d "$UTILS_DIR" ]; then
    # Garante que a pasta é legível e executável por todos
    $SUDO chmod 755 "$UTILS_DIR"

    # Garante que TODOS os scripts dentro dela sejam executáveis
    $SUDO chmod +x "$UTILS_DIR"/*

    log "SUCCESS" "Permissões +x aplicadas em $UTILS_DIR"
else
    log "ERROR" "Diretório de utils não encontrado: $UTILS_DIR"
fi

# ==============================================================================
# 4. CONFIGURAÇÃO DE ALIASES GLOBAIS (IDEMPOTENTE)
# ==============================================================================
log "INFO" "Configurando carregamento automático de aliases..."

GLOBAL_ALIAS_FILE="$CONFIG_DIR/aliases.geral"

# Remove TODAS as configurações antigas de aliases (usando marcadores de bloco)
if grep -q "# === V3RTECH SCRIPTS: Global Aliases BEGIN ===" "$SYSTEM_BASHRC"; then
    log "INFO" "Removendo configuração de aliases antiga para atualização..."
    $SUDO sed -i '/# === V3RTECH SCRIPTS: Global Aliases BEGIN ===/,/# === V3RTECH SCRIPTS: Global Aliases END ===/d' "$SYSTEM_BASHRC"
fi

if ! grep -q "# === V3RTECH SCRIPTS: Global Aliases BEGIN ===" "$SYSTEM_BASHRC"; then
    log "INFO" "Injetando carregamento de aliases..."
    {
        echo ""
        echo "# === V3RTECH SCRIPTS: Global Aliases BEGIN ==="
        echo "if [ -f \"$GLOBAL_ALIAS_FILE\" ]; then"
        echo "    source \"$GLOBAL_ALIAS_FILE\""
        echo "fi"
        echo "# === V3RTECH SCRIPTS: Global Aliases END ==="
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null
    log "SUCCESS" "Aliases configurados."
else
    log "INFO" "Aliases já configurados."
fi

# ==============================================================================
# 5. OTIMIZAÇÕES DE KERNEL E LOGS
# ==============================================================================
log "INFO" "Aplicando otimizações de Kernel e Journald..."

SYSCTL_CONF="/etc/sysctl.d/99-v3rtech-optimizations.conf"
if [ ! -f "$SYSCTL_CONF" ]; then
    {
        echo "vm.swappiness=10"
        echo "vm.vfs_cache_pressure=50"
        echo "fs.inotify.max_user_watches=524288"
    } | $SUDO tee "$SYSCTL_CONF" > /dev/null
    $SUDO sysctl -p "$SYSCTL_CONF" &>/dev/null
fi

JOURNAL_CONF="/etc/systemd/journald.conf"
if [ -f "$JOURNAL_CONF" ]; then
    $SUDO sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=100M/' "$JOURNAL_CONF"
    $SUDO sed -i 's/^SystemMaxUse=.*/SystemMaxUse=100M/' "$JOURNAL_CONF"
    $SUDO sed -i 's/^#SystemMaxFiles=.*/SystemMaxFiles=5/' "$JOURNAL_CONF"
    $SUDO sed -i 's/^SystemMaxFiles=.*/SystemMaxFiles=5/' "$JOURNAL_CONF"
fi

# ==============================================================================
# 6. RESTAURAÇÃO DE CONFIGURAÇÕES DE USUÁRIO
# ==============================================================================
log "INFO" "Padronizando diretórios pessoais e restaurando configs..."

$SUDO xdg-user-dirs-update &>/dev/null

CONFIG_SRC_DIR="$RESOURCES_DIR/configs"
CUSTOM_BASHRC="$RESOURCES_DIR/user.bashrc"

# Mescla .bashrc do usuário (Apenas visuais)
if [ -f "$CUSTOM_BASHRC" ]; then
    if ! grep -q "V3RTECH Custom Settings" "$REAL_HOME/.bashrc"; then
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
# 7. INSTALAÇÃO DE SCRIPTS UTILITÁRIOS (LINKS)
# ==============================================================================
log "INFO" "Criando links simbólicos..."

# Cria links em /usr/local/bin (Garantia extra caso o PATH falhe)
if [ -d "$UTILS_DIR" ]; then
    for script in "$UTILS_DIR"/*; do
        [ -e "$script" ] || continue
        script_name=$(basename "$script")
        $SUDO ln -sf "$script" "/usr/local/bin/$script_name"
    done
fi

# Fontes
if [ -d "$RESOURCES_DIR/fonts" ]; then
    log "INFO" "Instalando fontes..."
    $SUDO mkdir -p /usr/share/fonts/v3rtech
    $SUDO cp -r "$RESOURCES_DIR/fonts/"* /usr/share/fonts/v3rtech/
    $SUDO fc-cache -f
fi

# ==============================================================================
# 8. CONFIGURAÇÃO VISUAL DE BOOT (PLYMOUTH)
# ==============================================================================
log "INFO" "Verificando tema de boot..."

if ! command -v plymouth &>/dev/null; then
    if command -v apt &>/dev/null; then
        $SUDO apt install -y plymouth plymouth-themes
    fi
fi

if command -v plymouth-set-default-theme &>/dev/null; then
    if [ -d "/usr/share/plymouth/themes/spinner" ]; then
        $SUDO plymouth-set-default-theme -R spinner
    elif [ -d "/usr/share/plymouth/themes/bgrt" ]; then
        $SUDO plymouth-set-default-theme -R bgrt
    fi
fi

log "SUCCESS" "Configurações aplicadas. REINICIE o terminal para ver o novo PATH."
