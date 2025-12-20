#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-mate.sh
# Descrição: Instalação do Ambiente MATE
# ==============================================================================

log "INFO" "Iniciando configuração do MATE Desktop..."

# 1. Instalação de Pacotes
PKGS_MATE=(
    "mate"                  # Meta-pacote core
    "mate-extra"            # Extras
    "lightdm"               # Display Manager
    "lightdm-gtk-greeter"   # Tema padrão para LightDM no Mate
    "network-manager-applet"# Ícone de rede na tray
    "ulauncher"             # Launcher
)

i "${PKGS_MATE[@]}"

# 2. Configuração do Display Manager
log "INFO" "Habilitando LightDM..."
if command -v lightdm &>/dev/null; then
    $SUDO systemctl enable --now lightdm.service
fi

# 3. Preferências (Opcionais/Comentadas no original)
# Descomente se quiser forçar numlock
# if command -v gsettings &>/dev/null; then
#     gsettings set org.mate.peripherals-keyboard-xkb.kbd numlock-state 'on'
# fi

log "SUCCESS" "Configuração do MATE concluída."
