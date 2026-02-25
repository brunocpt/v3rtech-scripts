#!/bin/bash
# ==============================================================================
# Script: detect-system.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Detectar distribuição, ambiente desktop, GPU e sessão gráfica
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Este script detecta:
# - Distribuição Linux (Debian, Ubuntu, Arch, Fedora)
# - Ambiente de Desktop (KDE, GNOME, XFCE, Deepin, Cosmic)
# - GPU (Intel, AMD, NVIDIA)
# - Sessão gráfica (X11, Wayland)
# - Se é distribuição imutável (Silverblue, Kinoite, etc)
#
# Salva as informações em config.conf para uso por outros scripts.
#
# ==============================================================================

# Carrega dependências
# Usa BASH_SOURCE para funcionar mesmo se chamado de forma indireta
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }

log "STEP" "Iniciando detecção de ambiente do sistema..."

# ==============================================================================
# 1. DETECÇÃO DE DISTRIBUIÇÃO
# ==============================================================================

if [ ! -f /etc/os-release ]; then
    die "Arquivo /etc/os-release não encontrado. Sistema incompatível."
fi

# Carrega informações da distro
source /etc/os-release

# Normaliza ID para minúsculas
DISTRO_ID="${ID,,}"
DISTRO_LIKE="${ID_LIKE,,}"

# Determina a família da distro
if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" =~ "arch" ]]; then
    DISTRO_FAMILY="arch"
    PKG_MANAGER="pacman"
    log "INFO" "Distribuição detectada: Arch Linux ($PRETTY_NAME)"

elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" =~ "fedora" ]]; then
    DISTRO_FAMILY="fedora"
    PKG_MANAGER="dnf"
    log "INFO" "Distribuição detectada: Fedora ($PRETTY_NAME)"

elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_LIKE" =~ "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" =~ "ubuntu" ]]; then
    DISTRO_FAMILY="debian"
    PKG_MANAGER="apt"
    log "INFO" "Distribuição detectada: Debian/Ubuntu ($PRETTY_NAME)"

else
    log "WARN" "Distribuição não suportada nativamente: $PRETTY_NAME"
    log "WARN" "A instalação automática de pacotes pode falhar."
    DISTRO_FAMILY="unknown"
    PKG_MANAGER="unknown"
fi

# Salva nome específico da distro
DISTRO_NAME="$DISTRO_ID"

# ==============================================================================
# 2. DETECÇÃO DE AMBIENTE DESKTOP
# ==============================================================================

RAW_DE="${XDG_CURRENT_DESKTOP,,}"

# Tenta detectar o ambiente
if [[ "$RAW_DE" =~ "gnome" ]]; then
    DESKTOP_ENV="gnome"
elif [[ "$RAW_DE" =~ "kde" || "$RAW_DE" =~ "plasma" ]]; then
    DESKTOP_ENV="kde"
elif [[ "$RAW_DE" =~ "xfce" ]]; then
    DESKTOP_ENV="xfce"
elif [[ "$RAW_DE" =~ "deepin" ]]; then
    DESKTOP_ENV="deepin"
elif [[ "$RAW_DE" =~ "cosmic" ]]; then
    DESKTOP_ENV="cosmic"
elif [[ "$RAW_DE" =~ "cinnamon" ]]; then
    # Cinnamon não é suportado, mas detectamos para avisar
    log "WARN" "Cinnamon não é suportado nesta versão"
    DESKTOP_ENV="unknown"
elif [[ "$RAW_DE" =~ "mate" ]]; then
    # Mate não é suportado, mas detectamos para avisar
    log "WARN" "Mate não é suportado nesta versão"
    DESKTOP_ENV="unknown"
else
    DESKTOP_ENV="unknown"
    log "WARN" "Ambiente Desktop não identificado (Raw: $XDG_CURRENT_DESKTOP)"
fi

log "INFO" "Ambiente Desktop: ${DESKTOP_ENV^}"

# ==============================================================================
# 3. DETECÇÃO DE SESSÃO GRÁFICA (X11 vs Wayland)
# ==============================================================================

SESSION_TYPE="${XDG_SESSION_TYPE,,}"

if [ -z "$SESSION_TYPE" ]; then
    # Tenta detectar via variáveis de ambiente
    if [ -n "$WAYLAND_DISPLAY" ]; then
        SESSION_TYPE="wayland"
    elif [ -n "$DISPLAY" ]; then
        SESSION_TYPE="x11"
    else
        SESSION_TYPE="unknown"
    fi
fi

log "INFO" "Sessão gráfica: ${SESSION_TYPE^}"

# ==============================================================================
# 4. DETECÇÃO DE GPU
# ==============================================================================

GPU_VENDOR="unknown"

# Tenta detectar GPU via lspci
if command -v lspci &>/dev/null; then
    if lspci | grep -qi "nvidia"; then
        GPU_VENDOR="nvidia"
    elif lspci | grep -qi "amd"; then
        GPU_VENDOR="amd"
    elif lspci | grep -qi "intel"; then
        GPU_VENDOR="intel"
    fi
fi

# Se não conseguiu via lspci, tenta glxinfo
if [ "$GPU_VENDOR" = "unknown" ] && command -v glxinfo &>/dev/null; then
    if glxinfo 2>/dev/null | grep -qi "nvidia"; then
        GPU_VENDOR="nvidia"
    elif glxinfo 2>/dev/null | grep -qi "amd"; then
        GPU_VENDOR="amd"
    elif glxinfo 2>/dev/null | grep -qi "intel"; then
        GPU_VENDOR="intel"
    fi
fi

log "INFO" "GPU detectada: ${GPU_VENDOR^}"

# ==============================================================================
# 5. DETECÇÃO DE DISTRIBUIÇÃO IMUTÁVEL
# ==============================================================================

IS_IMMUTABLE="false"

# Verifica se é uma distribuição imutável
if [ -f /etc/ostree/os-release ]; then
    IS_IMMUTABLE="true"
    log "INFO" "Sistema imutável detectado (ostree)"
fi

# ==============================================================================
# 6. SALVAR CONFIGURAÇÃO
# ==============================================================================

# Atualiza o arquivo de configuração com as informações detectadas
log "INFO" "Salvando configuração em $CONFIG_FILE..."

# Usa a função save_config do env.sh
save_config "DISTRO_FAMILY" "$DISTRO_FAMILY"
save_config "DISTRO_NAME" "$DISTRO_NAME"
save_config "PKG_MANAGER" "$PKG_MANAGER"
save_config "DESKTOP_ENV" "$DESKTOP_ENV"
save_config "SESSION_TYPE" "$SESSION_TYPE"
save_config "GPU_VENDOR" "$GPU_VENDOR"
save_config "IS_IMMUTABLE" "$IS_IMMUTABLE"

# ==============================================================================
# 7. RESUMO DA DETECÇÃO
# ==============================================================================

log "SUCCESS" "Detecção concluída com sucesso!"
echo ""
log "INFO" "Resumo do sistema detectado:"
list_item "Distribuição: $DISTRO_NAME ($DISTRO_FAMILY)"
list_item "Ambiente: $DESKTOP_ENV"
list_item "Sessão: $SESSION_TYPE"
list_item "GPU: $GPU_VENDOR"
list_item "Imutável: $IS_IMMUTABLE"
echo ""

# ==============================================================================
# 8. VALIDAÇÃO
# ==============================================================================

# Valida se a detecção foi bem-sucedida
if [ "$DISTRO_FAMILY" = "unknown" ]; then
    log "WARN" "Distribuição desconhecida. Alguns recursos podem não funcionar."
fi

if [ "$DESKTOP_ENV" = "unknown" ]; then
    log "WARN" "Ambiente Desktop desconhecido. Configurações de desktop serão puladas."
fi

log "SUCCESS" "Sistema pronto para instalação"
