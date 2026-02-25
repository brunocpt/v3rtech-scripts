#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-multimedia.sh
# Versão: 4.1.0
# Data: 2026-02-25
# Objetivo: Instalar aplicativos de Multimídia e realizar pós-instalação
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

section "Instalação de Aplicativos de Multimídia"

# Carrega seleção de apps
if [ -f "$CONFIG_HOME/selected-apps.conf" ]; then
    source "$CONFIG_HOME/selected-apps.conf"
else
    log "WARN" "Arquivo de seleção não encontrado. Nenhum app de Multimídia será instalado."
    exit 0
fi

log "STEP" "Instalando aplicativos de Multimídia selecionados..."

installed_count=0
filebot_selected=false
for i in "${!APP_NAMES_ORDERED[@]}"; do
    app_name="${APP_NAMES_ORDERED[$i]}"
    category="${APP_MAP_CATEGORY[$app_name]}"
    
    if [ "$category" = "Multimídia" ]; then
        var_name="SELECTED_APP_$i"
        if [ "${!var_name}" = "true" ]; then
            log "DEBUG" "App $app_name (índice $i) selecionado para instalação."
            install_app "$app_name"
            ((installed_count++))
            if [ "$app_name" = "Filebot" ]; then
                filebot_selected=true
            fi
        fi
    fi
done

if [ $installed_count -eq 0 ]; then
    log "INFO" "Nenhum aplicativo de Multimídia foi selecionado para instalação."
else
    log "SUCCESS" "Instalação de $installed_count aplicativo(s) de Multimídia concluída!"
fi

# ==============================================================================
# PÓS-INSTALAÇÃO DE FILEBOT
# ==============================================================================
if [ "$filebot_selected" = true ]; then
    log "INFO" "Verificando se Filebot está instalado..."
    if ! flatpak list --app 2>/dev/null | grep -q "net.filebot.FileBot"; then
        log "WARN" "Filebot não está instalado, pulando pós-instalação"
    else
        log "INFO" "Configurando Filebot..."
        
        # 1. Aplicar licença (se existir)
        LICENSE_FILE="$BASE_DIR/configs/FileBot_License_PX10290120.psm"
        if [ -f "$LICENSE_FILE" ]; then
            log "INFO" "Aplicando licença do Filebot..."
            cat "$LICENSE_FILE" | flatpak run net.filebot.FileBot --license
        else
            log "DEBUG" "Arquivo de licença não encontrado: $LICENSE_FILE"
        fi
        
        # 2. Configurar OpenSubtitles v2
        log "INFO" "Configurando OpenSubtitles v2..."
        if flatpak run net.filebot.FileBot -script fn:properties --def net.filebot.WebServices.OpenSubtitles.v2=true 2>/dev/null; then
            log "SUCCESS" "✓ OpenSubtitles v2 configurado"
        else
            log "WARN" "⚠ Falha ao configurar OpenSubtitles v2"
        fi
        
        # 3. Configurar credenciais OpenSubtitles (se fornecidas)
        OSDB_CONFIG="$BASE_DIR/configs/filebot-osdb.conf"
        if [ -f "$OSDB_CONFIG" ]; then
            log "INFO" "Lendo credenciais OpenSubtitles..."
            source "$OSDB_CONFIG"
            if [ -n "$OSDB_USER" ] && [ -n "$OSDB_PWD" ]; then
                log "INFO" "Configurando credenciais OpenSubtitles..."
                if flatpak run net.filebot.FileBot -script fn:configure \
                    --def osdbUser="$OSDB_USER" \
                    --def osdbPwd="$OSDB_PWD" 2>/dev/null; then
                    log "SUCCESS" "✓ Credenciais OpenSubtitles configuradas"
                else
                    log "WARN" "⚠ Falha ao configurar credenciais OpenSubtitles"
                fi
            else
                log "DEBUG" "Credenciais OpenSubtitles não configuradas no arquivo"
            fi
        else
            log "DEBUG" "Arquivo de configuração não encontrado: $OSDB_CONFIG"
        fi
        log "SUCCESS" "✓ Filebot configurado com sucesso"
    fi
fi
