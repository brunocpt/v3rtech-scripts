#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-multimedia.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar apps de Multimídia e realizar pós-instalação
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# FUNCIONALIDADES:
# 1. Instala aplicativos de Multimídia (VLC, OBS, Spotify, etc.)
# 2. Suporta múltiplas distribuições (Arch, Debian, Fedora)
# 3. Suporta instalação nativa e Flatpak
# 4. Pós-instalação específica para Filebot (Licença e OpenSubtitles)
#
# ==============================================================================

set -euo pipefail

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }
source "$BASE_DIR/lib/apps-data.sh" || { echo "[ERRO] Não foi possível carregar lib/apps-data.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# ==============================================================================

install_native_app() {
    local app_name="$1"
    local package="${APP_MAP_NATIVE[$app_name]}"
    if [ -z "$package" ]; then return 1; fi
    if is_installed "$package"; then
        log "INFO" "Pacote '$package' ($app_name) já está instalado."
        return 10
    fi
    log "INFO" "Instalando $app_name (nativo)..."
    i "$package"
    return $?
}

install_flatpak_app() {
    local app_name="$1"
    local flatpak_id="${APP_MAP_FLATPAK[$app_name]}"
    if [ -z "$flatpak_id" ]; then return 1; fi
    if flatpak list 2>/dev/null | grep -q "$flatpak_id"; then
        log "INFO" "Flatpak '$flatpak_id' ($app_name) já está instalado."
        return 10
    fi
    log "INFO" "Instalando $app_name (Flatpak)..."
    install_flatpak "$flatpak_id"
    return $?
}

install_app() {
    local app_name="$1"
    local app_method="${APP_MAP_METHOD[$app_name]}"
    local prefer_native="${PREFER_NATIVE:-false}"
    local install_status=1
    local install_type=""

    if [ "$app_method" = "pipx" ] || [ "$app_method" = "custom" ]; then return 0; fi

    log "STEP" "Processando $app_name..."

    if [ "$app_method" = "flatpak" ]; then
        install_flatpak_app "$app_name"; install_status=$?; install_type="flatpak"
    elif [ "$prefer_native" = "true" ]; then
        install_native_app "$app_name"; install_status=$?; install_type="native"
        if [ $install_status -ne 0 ] && [ $install_status -ne 10 ]; then
            install_flatpak_app "$app_name"; install_status=$?; install_type="flatpak"
        fi
    else
        install_flatpak_app "$app_name"; install_status=$?; install_type="flatpak"
        if [ $install_status -ne 0 ] && [ $install_status -ne 10 ]; then
            install_native_app "$app_name"; install_status=$?; install_type="native"
        fi
    fi

    if [ $install_status -eq 0 ] || [ $install_status -eq 10 ]; then
        [ $install_status -eq 0 ] && log "SUCCESS" "$app_name instalado via $install_type"
        return 0
    fi
    return 1
}

# ==============================================================================
# MAIN
# ==============================================================================

section "Instalação de Aplicativos de Multimídia"

SELECTED_APPS_FILE="$CONFIG_HOME/selected-apps.conf"
if [ ! -f "$SELECTED_APPS_FILE" ]; then
    log "WARN" "Arquivo de seleção não encontrado."
    exit 0
fi

source "$SELECTED_APPS_FILE"

installed_count=0
filebot_selected=false

# Itera sobre todos os apps e verifica se são de Multimídia e foram selecionados
for i in "${!APP_NAMES_ORDERED[@]}"; do
    app_name="${APP_NAMES_ORDERED[$i]}"
    category="${APP_MAP_CATEGORY[$app_name]}"
    
    if [[ "$category" == "Multimídia" ]]; then
        var_name="SELECTED_APP_$i"
        
        # CORREÇÃO: Verifica se a variável existe antes de acessá-la
        # Usa 'declare -p' para verificar se a variável foi definida
        if declare -p "$var_name" &>/dev/null && [ "${!var_name}" = "true" ]; then
            install_app "$app_name" && ((installed_count++))
            if [ "$app_name" = "Filebot" ]; then
                filebot_selected=true
            fi
        fi
    fi
done

log "SUCCESS" "Instalação de $installed_count aplicativo(s) de Multimídia concluída!"

# ==============================================================================
# PÓS-INSTALAÇÃO DE FILEBOT
# ==============================================================================
if [ "$filebot_selected" = true ]; then
    log "INFO" "Configurando Filebot..."
    if flatpak list --app 2>/dev/null | grep -q "net.filebot.FileBot"; then
        LICENSE_FILE="$BASE_DIR/configs/FileBot_License_PX10290120.psm"
        if [ -f "$LICENSE_FILE" ]; then
            log "INFO" "Aplicando licença..."
            cat "$LICENSE_FILE" | flatpak run net.filebot.FileBot --license || true
        fi
        log "INFO" "Configurando OpenSubtitles v2..."
        flatpak run net.filebot.FileBot -script fn:properties --def net.filebot.WebServices.OpenSubtitles.v2=true 2>/dev/null || true
    fi
fi
