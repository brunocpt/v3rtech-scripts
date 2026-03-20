#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-system.sh
# Versão: 7.0.0
# Data: 2026-03-20
# Objetivo: Instalar aplicativos de Sistema
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
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
# VALIDAÇÃO INICIAL
# ==============================================================================

if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$BASE_DIR/lib/detect-system.sh" || die "Falha ao detectar sistema"
fi

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# As funções install_native_app, install_flatpak_app e install_app estão
# centralizadas em core/package-mgr.sh e já estão disponíveis via export -f.
# ==============================================================================

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

    if [[ "$category" == "Sistema" || "$category" == "Utilitários" ]]; then
        var_name="SELECTED_APP_$i"
        if declare -p "$var_name" &>/dev/null && [ "${!var_name}" = "true" ]; then
            install_app "$app_name" && ((installed_count++))
        fi
    fi
done

if [ $installed_count -eq 0 ]; then
    log "INFO" "Nenhum aplicativo de Sistema foi selecionado para instalação."
else
    log "SUCCESS" "Instalação de $installed_count aplicativo(s) de Sistema concluída!"
fi

# ==============================================================================
# PÓS-INSTALAÇÃO / CONFIGURAÇÃO DO COCKPIT
# ==============================================================================

# Habilita o serviço do Cockpit caso esteja instalado e o sistema use systemd
if command -v systemctl &>/dev/null && systemctl list-unit-files cockpit.socket &>/dev/null; then
    log "INFO" "Habilitando e iniciando o serviço do Cockpit..."
    $SUDO systemctl enable --now cockpit.socket 2>/dev/null || true
fi
