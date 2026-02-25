#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-system.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Instalar aplicativos de Sistema
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }
source "$BASE_DIR/lib/apps-data.sh" || { echo "[ERRO] Não foi possível carregar lib/apps-data.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# VALIDAÇÃO INICIAL
# ==============================================================================

if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$BASE_DIR/lib/detect-system.sh" || die "Falha ao detectar sistema"
fi

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# ==============================================================================

install_native_app() {
    local app_name="$1"
    local package="${APP_MAP_NATIVE[$app_name]}"
    
    if [ -z "$package" ]; then
        log "WARN" "Pacote nativo não disponível para $app_name em $DISTRO_FAMILY"
        return 1
    fi
    
    log "INFO" "Instalando $app_name (nativo)..."
    log "DEBUG" "Pacote: $package"
    
    i $package
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"
        return 0
    else
        log "WARN" "Falha ao instalar $app_name"
        return 1
    fi
}

install_flatpak_app() {
    local app_name="$1"
    local flatpak_id="${APP_MAP_FLATPAK[$app_name]}"
    
    if [ -z "$flatpak_id" ]; then
        log "WARN" "Flatpak ID não disponível para $app_name"
        return 1
    fi
    
    log "INFO" "Instalando $app_name (Flatpak)..."
    log "DEBUG" "Flatpak ID: $flatpak_id"
    
    install_flatpak "$flatpak_id"
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"
        return 0
    else
        log "WARN" "Falha ao instalar $app_name"
        return 1
    fi
}

install_app() {
    local app_name="$1"
    local app_method="${APP_MAP_METHOD[$app_name]}"
    local prefer_method="$PREFER_NATIVE"
    
    if [ "$app_method" = "flatpak" ]; then
        install_flatpak_app "$app_name"
    elif [ "$app_method" = "pipx" ] || [ "$app_method" = "custom" ]; then
        log "DEBUG" "$app_name será tratado por outro script ($app_method)"
        return 0
    else
        if [ "$prefer_method" = "true" ]; then
            install_native_app "$app_name" || install_flatpak_app "$app_name"
        else
            install_flatpak_app "$app_name" || install_native_app "$app_name"
        fi
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

section "Instalação de Aplicativos de Sistema"

# Carrega seleção de apps
if [ -f "$CONFIG_HOME/selected-apps.conf" ]; then
    source "$CONFIG_HOME/selected-apps.conf"
else
    log "WARN" "Arquivo de seleção não encontrado. Nenhum app de Sistema será instalado."
    exit 0
fi

log "STEP" "Instalando aplicativos de Sistema selecionados..."

installed_count=0
for i in "${!APP_NAMES_ORDERED[@]}"; do
    app_name="${APP_NAMES_ORDERED[$i]}"
    category="${APP_MAP_CATEGORY[$app_name]}"
    
    if [ "$category" = "Sistema" ]; then
        var_name="SELECTED_APP_$i"
        if [ "${!var_name}" = "true" ]; then
            log "DEBUG" "App '$app_name' (índice $i) selecionado para instalação."
            install_app "$app_name"
            ((installed_count++))
        fi
    fi
done

if [ $installed_count -eq 0 ]; then
    log "INFO" "Nenhum aplicativo de Sistema foi selecionado para instalação."
else
    log "SUCCESS" "Instalação de $installed_count aplicativo(s) de Sistema concluída!"
fi
