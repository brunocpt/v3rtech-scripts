#!/bin/bash
# ==============================================================================
# Script: install-desktop-xfce.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Instalar e configurar ambiente XFCE
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

if [ -z "$DISTRO_FAMILY" ]; then
    source "$(dirname "$0")/detect-system.sh" || die "Falha ao detectar sistema"
fi

section "Instalação de Pacotes XFCE"

case "$DISTRO_FAMILY" in
    debian)
        log "STEP" "Instalando pacotes XFCE para Debian/Ubuntu..."
        i "xfce4" "xfce4-goodies" "xfce4-terminal" "xfce4-whiskermenu-plugin" || log "WARN" "Falha ao instalar XFCE"
        ;;
    arch)
        log "STEP" "Instalando pacotes XFCE para Arch Linux..."
        i "xfce4" "xfce4-goodies" || log "WARN" "Falha ao instalar XFCE"
        ;;
    fedora)
        log "STEP" "Instalando pacotes XFCE para Fedora..."
        i "xfce4-desktop" "xfce4-panel" "xfce4-session" "xfce4-terminal" || log "WARN" "Falha ao instalar XFCE"
        ;;
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

log "SUCCESS" "Instalação de pacotes XFCE concluída!"
log "INFO" "Reinicie o sistema para aplicar todas as mudanças"
