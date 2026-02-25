#!/bin/bash
# ==============================================================================
# Script: install-desktop-kde.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Instalar e configurar ambiente KDE/Plasma
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Instala pacotes específicos do KDE/Plasma:
# - Plasma desktop
# - Aplicativos KDE
# - Temas e ícones
# - Utilitários
#
# Este script é independente e pode ser executado isoladamente.
#
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# VALIDAÇÃO INICIAL
# ==============================================================================

if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$(dirname "$0")/detect-system.sh" || die "Falha ao detectar sistema"
fi

# Verifica se é KDE
if [ "$DESKTOP_ENV" != "kde" ]; then
    log "WARN" "Este script é para KDE/Plasma. Seu ambiente é: $DESKTOP_ENV"
    if ! ask_yes_no "Deseja continuar mesmo assim?"; then
        log "INFO" "Instalação cancelada"
        exit 0
    fi
fi

section "Instalação de Pacotes KDE/Plasma"

# ==============================================================================
# INSTALAÇÃO POR DISTRIBUIÇÃO
# ==============================================================================

case "$DISTRO_FAMILY" in
    
    # ========== DEBIAN / UBUNTU ==========
    debian)
        log "STEP" "Instalando pacotes KDE para Debian/Ubuntu..."
        
        local kde_packages=(
            # Plasma Desktop
            "plasma-desktop" "plasma-workspace" "plasma-framework" "kde-applications" "kde-utilities"
            
            # Aplicativos KDE
            "dolphin" "konsole" "kate" "kwrite"
            "okular" "gwenview" "kolourpaint"
            "kcalc" "kdeconnect" "kdeplasma-addons"
            
            # Temas e ícones
            "breeze-icon-theme" "breeze" "oxygen-icon-theme"
            
            # Utilitários
            "khotkeys" "kmenuedit" "ksysguard"
            "kscreen" "bluedevil"
        )
        
        for pkg in "${kde_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    
    # ========== ARCH LINUX ==========
    arch)
        log "STEP" "Instalando pacotes KDE para Arch Linux..."
        
        local kde_packages=(
            # Plasma Desktop
            "plasma" "plasma-desktop" "plasma-workspace"
            
            # Aplicativos KDE
            "dolphin" "konsole" "kate" "okular"
            "gwenview" "kolourpaint" "kcalc" "kdeconnect"
            "kdeplasma-addons"
            
            # Temas
            "breeze" "breeze-icons" "oxygen-icons"
        )
        
        for pkg in "${kde_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    
    # ========== FEDORA ==========
    fedora)
        log "STEP" "Instalando pacotes KDE para Fedora..."
        
        local kde_packages=(
            # Plasma Desktop
            "plasma-desktop" "plasma-workspace" "plasma-framework"
            
            # Aplicativos KDE
            "dolphin" "konsole" "kate" "okular"
            "gwenview" "kolourpaint" "kcalc" "kdeconnect"
            "kdeplasma-addons"
            
            # Temas
            "breeze-icon-theme" "breeze" "oxygen-icon-theme"
        )
        
        for pkg in "${kde_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

# ==============================================================================
# CONFIGURAÇÕES PÓS-INSTALAÇÃO
# ==============================================================================

log "STEP" "Aplicando configurações do KDE..."

# Se estiver em Wayland, aplica otimizações
if [ "$SESSION_TYPE" = "wayland" ]; then
    log "INFO" "Sessão Wayland detectada, aplicando otimizações..."
    # Aqui podem ir configurações específicas para Wayland
fi

# Se tiver NVIDIA, aplica configurações
if [ "$GPU_VENDOR" = "nvidia" ]; then
    log "INFO" "GPU NVIDIA detectada, aplicando otimizações..."
    # Aqui podem ir configurações específicas para NVIDIA
fi

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

section "KDE/Plasma Instalado"
log "SUCCESS" "Instalação de pacotes KDE concluída!"
log "INFO" "Reinicie o sistema para aplicar todas as mudanças"
