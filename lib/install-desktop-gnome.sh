#!/bin/bash
# ==============================================================================
# Script: install-desktop-gnome.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Instalar e configurar ambiente GNOME
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

if [ "$DESKTOP_ENV" != "gnome" ]; then
    log "WARN" "Este script é para GNOME. Seu ambiente é: $DESKTOP_ENV"
    if ! ask_yes_no "Deseja continuar mesmo assim?"; then
        exit 0
    fi
fi

section "Instalação de Pacotes GNOME"

case "$DISTRO_FAMILY" in
    debian)
        log "STEP" "Instalando pacotes GNOME para Debian/Ubuntu..."
        local gnome_packages=(
            "gnome-shell" "gnome-desktop" "gnome-session"
            "nautilus" "gnome-terminal" "gedit"
            "gnome-calendar" "gnome-calculator" "gnome-maps"
            "gnome-system-monitor" "gnome-tweaks"
            "adwaita-icon-theme"
        )
        for pkg in "${gnome_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    arch)
        log "STEP" "Instalando pacotes GNOME para Arch Linux..."
        local gnome_packages=(
            "gnome-shell" "gnome-desktop" "gnome-session"
            "nautilus" "gnome-terminal" "gedit"
            "gnome-calendar" "gnome-calculator" "gnome-maps"
            "gnome-system-monitor" "gnome-tweaks"
            "adwaita-icon-theme"
        )
        for pkg in "${gnome_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    fedora)
        log "STEP" "Instalando pacotes GNOME para Fedora..."
        local gnome_packages=(
            "gnome-shell" "gnome-desktop" "gnome-session"
            "nautilus" "gnome-terminal" "gedit"
            "gnome-calendar" "gnome-calculator" "gnome-maps"
            "gnome-system-monitor" "gnome-tweaks"
            "adwaita-icon-theme"
        )
        for pkg in "${gnome_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

section "GNOME Instalado"
log "SUCCESS" "Instalação de pacotes GNOME concluída!"
log "INFO" "Reinicie o sistema para aplicar todas as mudanças"
