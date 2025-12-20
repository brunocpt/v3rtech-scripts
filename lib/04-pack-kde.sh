#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-kde.sh
# Descrição: Otimizações e Pacotes para KDE Plasma
# ==============================================================================

log "INFO" "Iniciando configuração do KDE Plasma..."

# 1. Instalação de Extras (Dolphin plugins, Ark, etc)
# Muitos já estão no CSV principal, aqui focamos em ferramentas de DE.

PKGS_KDE=(
    "ark"
    "dolphin-plugins"
    "kate"
    "gwenview"
    "spectacle" # Screenshot tool moderna do KDE
    "yakuake"   # Terminal Dropdown estilo Quake (Alternativa ao Guake no KDE)
)

i "${PKGS_KDE[@]}"

# 2. Remoção de Bloatware (Se existirem)
# Usamos a função 'r' (remove) do package-mgr.sh
APPS_TO_REMOVE=(
    "kmix"
    "ktorrent"
    "elisa" # Player de música padrão as vezes indesejado
)

r "${APPS_TO_REMOVE[@]}"

# 3. Restauração de Configs (Falkon, Konsole, etc)
# Falkon
restore_zip_config "$CONFIGS_DIR/falkon-$REAL_USER.zip" "$REAL_HOME/.config"

# 4. Ajustes de Sistema (Desabilitar baloo/indexador se desejar - Opcional)
# balooctl disable 2>/dev/null

log "SUCCESS" "Configuração do KDE Plasma concluída."
