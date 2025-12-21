#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/03-prepara-configs.sh
# Versão: 5.0.0 (Smart Path & Permissions Fix)
#
# Descrição: Configurações profundas do sistema.
# Correções:
#   1. PATH agora usa lógica anti-duplicação (case statement).
#   2. Garante chmod +x na pasta utils para que os scripts sejam achados.
#   3. Caminho 'configs' corrigido.
# ==============================================================================

log "STEP" "Iniciando Configurações Gerais de Sistema..."

# Variáveis de Caminho
INSTALL_TARGET="/usr/local/share/scripts/v3rtech-scripts"
UTILS_DIR="$INSTALL_TARGET/utils"
CONFIG_DIR="$INSTALL_TARGET/configs"
SYSTEM_BASHRC="/etc/bash.bashrc"

# ==============================================================================
# 1. CONFIGURAÇÃO DE PATH GLOBAL INTELIGENTE
# ==============================================================================
log "INFO" "Configurando PATH global (com proteção anti-duplicação)..."

# Remove configurações antigas/simples do V3RTECH para evitar conflito
if grep -q "V3RTECH SCRIPTS: Global PATH" "$SYSTEM_BASHRC"; then
    log "INFO" "Removendo configuração de PATH antiga para atualização..."
    # Sed remove o bloco antigo se ele foi marcado com o comentário específico (simplificado)
    # Na prática, a limpeza manual que você fez antes resolve, aqui garantimos o futuro.
    $SUDO sed -i '/V3RTECH SCRIPTS: Global PATH/,+4d' "$SYSTEM_BASHRC"
fi

# Injeta o código inteligente.
# A lógica 'case ":$PATH:"' verifica se o caminho já existe na variável atual.
# Se existir, não faz nada. Se não, adiciona. Isso resolve o problema de duplicação.
if ! grep -q "$UTILS_DIR" "$SYSTEM_BASHRC"; then
    log "INFO" "Injetando lógica de PATH no $SYSTEM_BASHRC..."

    {
        echo ""
        echo "# --- V3RTECH SCRIPTS: Global PATH (Smart Append) ---"
        echo "if [ -d \"$UTILS_DIR\" ]; then"
        echo "    case \":\$PATH:\" in"
        echo "        *:\"$UTILS_DIR\":*) ;;"
        echo "        *) export PATH=\"\$PATH:$UTILS_DIR\" ;;"
        echo "    esac"
        echo "fi"
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null

    log "SUCCESS" "PATH configurado. Reinicie o terminal para testar."
else
    log "INFO" "PATH inteligente já configurado."
fi

# ==============================================================================
# 2. PERMISSÕES DE EXECUÇÃO (CRÍTICO)
# ==============================================================================
log "INFO" "Ajustando permissões de execução dos utilitários..."

if [ -d "$UTILS_DIR" ]; then
    # Garante que a pasta é legível e executável por todos
    $SUDO chmod 755 "$UTILS_DIR"

    # Garante que TODOS os scripts dentro dela sejam executáveis
    # Isso resolve o problema de 'comando não encontrado'
    $SUDO chmod +x "$UTILS_DIR"/*

    log "SUCCESS" "Permissões +x aplicadas em $UTILS_DIR"
else
    log "ERROR" "Diretório de utils não encontrado: $UTILS_DIR"
fi

# ==============================================================================
# 3. CONFIGURAÇÃO DE ALIASES GLOBAIS
# ==============================================================================
log "INFO" "Configurando carregamento automático de aliases..."

GLOBAL_ALIAS_FILE="$CONFIG_DIR/aliases.geral"

# Limpa entrada antiga se existir (para evitar duplicação do bloco source)
if grep -q "source.*aliases.geral" "$SYSTEM_BASHRC"; then
    # Verifica se aponta para o caminho errado 'config' (sem s)
    if grep -q "/config/" "$SYSTEM_BASHRC"; then
        log "WARN" "Corrigindo caminho de aliases antigo no bashrc..."
        $SUDO sed -i '/aliases.geral/d' "$SYSTEM_BASHRC"
        $SUDO sed -i '/V3RTECH.*Global Aliases/d' "$SYSTEM_BASHRC"
    fi
fi

if ! grep -q "$GLOBAL_ALIAS_FILE" "$SYSTEM_BASHRC"; then
    log "INFO" "Injetando carregamento de aliases..."
    {
        echo ""
        echo "# --- V3RTECH SCRIPTS: Global Aliases ---"
        echo "if [ -f \"$GLOBAL_ALIAS_FILE\" ]; then"
        echo "    source \"$GLOBAL_ALIAS_FILE\""
        echo "fi"
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null
    log "SUCCESS" "Aliases configurados."
fi

# ==============================================================================
# 4. OTIMIZAÇÕES DE KERNEL E LOGS
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
# 5. RESTAURAÇÃO DE CONFIGURAÇÕES DE USUÁRIO
# ==============================================================================
log "INFO" "Padronizando diretórios pessoais e restaurando configs..."

$SUDO xdg-user-dirs-update &>/dev/null

RESOURCES_DIR="$(dirname "$0")/../resources"
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
# 6. INSTALAÇÃO DE SCRIPTS UTILITÁRIOS (LINKS)
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
# 7. CONFIGURAÇÃO VISUAL DE BOOT (PLYMOUTH)
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
