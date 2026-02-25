#!/bin/bash
# ==============================================================================
# Script: install-desktop-cosmic.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar e configurar ambiente Cosmic (Pop!_OS)
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

section "Instalação de Pacotes Cosmic"

log "WARN" "Cosmic é um ambiente relativamente novo. Suporte limitado."

case "$DISTRO_FAMILY" in
    debian)
        log "STEP" "Instalando pacotes Cosmic para Debian/Ubuntu..."
        # Cosmic é baseado em GNOME, usa pacotes similares
        i "cosmic-desktop" "cosmic-terminal" || log "WARN" "Falha ao instalar Cosmic"
        ;;
    *)
        log "ERROR" "Cosmic não é suportado em $DISTRO_FAMILY"
        log "INFO" "Cosmic é disponível principalmente em Pop!_OS (Ubuntu-based)"
        exit 1
        ;;
esac

log "SUCCESS" "Instalação de pacotes Cosmic concluída!"
log "INFO" "Reinicie o sistema para aplicar todas as mudanças"
