#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-multimedia.sh
# Versão: 7.0.0
# Data: 2026-03-20
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

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }
source "$BASE_DIR/lib/apps-data.sh" || { echo "[ERRO] Não foi possível carregar lib/apps-data.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# As funções install_native_app, install_flatpak_app e install_app estão
# centralizadas em core/package-mgr.sh e já estão disponíveis via export -f.
# ==============================================================================

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
    log "INFO" "Iniciando pós-instalação do Filebot..."

    if flatpak list --app 2>/dev/null | grep -q "net.filebot.FileBot"; then

        # ----------------------------------------------------------------------
        # 1. Aplicar licença (se existir)
        # ----------------------------------------------------------------------
        LICENSE_FILE="$BASE_DIR/configs/FileBot_License_PX10290120.psm"

        if [ -f "$LICENSE_FILE" ]; then
            log "INFO" "Aplicando licença do Filebot..."
            if cat "$LICENSE_FILE" | flatpak run net.filebot.FileBot --license 2>/dev/null; then
                log "SUCCESS" "✓ Licença aplicada"
            else
                log "WARN" "⚠ Falha ao aplicar licença"
            fi
        else
            log "DEBUG" "Arquivo de licença não encontrado: $LICENSE_FILE"
        fi

        # ----------------------------------------------------------------------
        # 2. Ativar OpenSubtitles v2
        # ----------------------------------------------------------------------
        log "INFO" "Configurando OpenSubtitles v2..."

        if flatpak run net.filebot.FileBot \
            -script fn:properties \
            --def net.filebot.WebServices.OpenSubtitles.v2=true \
            2>/dev/null; then
            log "SUCCESS" "✓ OpenSubtitles v2 configurado"
        else
            log "WARN" "⚠ Falha ao configurar OpenSubtitles v2"
        fi

        # ----------------------------------------------------------------------
        # 3. Configurar credenciais OpenSubtitles (opcional)
        # ----------------------------------------------------------------------
        OSDB_CONFIG="$BASE_DIR/configs/filebot-osdb.conf"

        if [ -f "$OSDB_CONFIG" ]; then
            log "INFO" "Lendo credenciais OpenSubtitles..."

            # shellcheck disable=SC1090
            source "$OSDB_CONFIG"

            if [ -n "${OSDB_USER:-}" ] && [ -n "${OSDB_PWD:-}" ]; then
                log "INFO" "Configurando credenciais OpenSubtitles..."

                if flatpak run net.filebot.FileBot \
                    -script fn:configure \
                    --def osdbUser="$OSDB_USER" \
                    --def osdbPwd="$OSDB_PWD" \
                    2>/dev/null; then
                    log "SUCCESS" "✓ Credenciais OpenSubtitles configuradas"
                else
                    log "WARN" "⚠ Falha ao configurar credenciais OpenSubtitles"
                fi
            else
                log "DEBUG" "Credenciais OpenSubtitles não definidas em $OSDB_CONFIG"
            fi
        else
            log "DEBUG" "Arquivo de configuração OpenSubtitles não encontrado: $OSDB_CONFIG"
        fi

        log "SUCCESS" "✓ Pós-instalação do Filebot concluída"

    else
        log "WARN" "Filebot não está instalado via Flatpak. Pós-instalação ignorada."
    fi
fi
