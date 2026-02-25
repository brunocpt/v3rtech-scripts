#!/bin/bash
# ==============================================================================
# Script: install-desktop-deepin.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Instalar e configurar ambiente Deepin
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

section "Instalação de Pacotes Deepin"

case "$DISTRO_FAMILY" in
    debian)
        log "STEP" "Instalando pacotes Deepin para Debian/Ubuntu..."
        i "deepin" "deepin-desktop-environment" "deepin-terminal" || log "WARN" "Falha ao instalar Deepin"
        ;;
    arch)
        log "STEP" "Instalando pacotes Deepin para Arch Linux..."
        i "deepin" "deepin-terminal" || log "WARN" "Falha ao instalar Deepin"
        ;;
    fedora)
        log "STEP" "Instalando pacotes Deepin para Fedora..."
        i "deepin-desktop-environment" "deepin-terminal" || log "WARN" "Falha ao instalar Deepin"
        ;;
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

log "SUCCESS" "Instalação de pacotes Deepin concluída!"
log "INFO" "Reinicie o sistema para aplicar todas as mudanças"
