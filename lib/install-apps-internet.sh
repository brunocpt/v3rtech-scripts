#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-internet.sh
# Versão: 4.1.1
# Data: 2026-02-24
# Objetivo: Instalar aplicativos de Internet (navegadores, nuvem, comunicação)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
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
    i "$package"
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"
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
    install_flatpak "$flatpak_id"
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"
    else
        log "WARN" "Falha ao instalar $app_name"
        return 1
    fi
}

install_app() {
    local app_name="$1"
    local app_method="${APP_MAP_METHOD[$app_name]}"
    local prefer_native="${PREFER_NATIVE:-false}"

    if [ "$app_method" = "flatpak" ]; then
        install_flatpak_app "$app_name"
    elif [ "$app_method" = "pipx" ] || [ "$app_method" = "custom" ]; then
        log "DEBUG" "$app_name será tratado por outro script (método: $app_method)"
    else
        if [ "$prefer_native" = "true" ]; then
            install_native_app "$app_name" || install_flatpak_app "$app_name"
        else
            install_flatpak_app "$app_name" || install_native_app "$app_name"
        fi
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================
section "Instalação de Aplicativos de Internet"

SELECTED_APPS_FILE="$CONFIG_HOME/selected-apps.conf"
if [ ! -f "$SELECTED_APPS_FILE" ]; then
    log "WARN" "Arquivo de seleção não encontrado. Nenhum app de Internet será instalado."
    exit 0
fi

# Carrega o arquivo de configuração para ter acesso às variáveis SELECTED_APP_*
source "$SELECTED_APPS_FILE"

log "STEP" "Instalando aplicativos de Internet selecionados..."

installed_count=0
for i in "${!APP_NAMES_ORDERED[@]}"; do
    app_name="${APP_NAMES_ORDERED[$i]}"
    category="${APP_MAP_CATEGORY[$app_name]}"
    
    if [ "$category" = "Internet" ] || [ "$category" = "Nuvem" ] || [ "$category" = "Comunicação" ]; then
        var_name="SELECTED_APP_$i"
        if [ "${!var_name}" = "true" ]; then
            log "DEBUG" "App '$app_name' selecionado para instalação"
            install_app "$app_name"
            ((installed_count++))
        fi
    fi
done

if [ $installed_count -eq 0 ]; then
    log "INFO" "Nenhum aplicativo de Internet foi selecionado para instalação."
else
    log "SUCCESS" "Instalação de $installed_count aplicativo(s) de Internet concluída!"
fi
