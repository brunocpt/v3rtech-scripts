#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-gnome.sh
# Descrição: Otimizações e Pacotes para GNOME
# ==============================================================================

log "INFO" "Iniciando configuração do GNOME..."

# 1. Instalação de Pacotes Específicos (Usando abstração 'i')
# Nota: Nomes de pacotes podem variar. O 'i' tenta resolver, mas para extensões
# específicas, talvez seja necessário mapeamento extra no CSV ou comando direto.

PKGS_GNOME=(
    "gnome-tweaks"
    "gnome-shell-extensions"
    "dconf-editor"
    "guake"
    "ulauncher" # Nome genérico, no Arch o 'i' pode precisar de ajuste se for ulauncher-git
    "seahorse"
)

# Tenta instalar. Se falhar algum, loga warning.
i "${PKGS_GNOME[@]}"

# 2. Configurações do GSettings (Preferências)
log "INFO" "Aplicando preferências do GNOME (GSettings)..."

# Layout de botões (Min, Max, Fechar)
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Alt+Tab (Janelas e não Apps)
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab', '<Super>Tab']"

# Energia (Não suspender na tomada)
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'

# Interface
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true

# Screenshot (Salvar em Downloads - ajustado do seu script)
if [ -d "$REAL_HOME/Downloads" ]; then
    gsettings set org.gnome.gnome-screenshot auto-save-directory "file://$REAL_HOME/Downloads"
fi

# 3. Wavebox e Zotero (Lógica de Restauração Específica)
# A instalação principal deve vir do CSV (App Nativo ou Flatpak).
# Aqui focamos apenas na RESTAURAÇÃO DE CONFIG se o app estiver presente.

if command -v wavebox &>/dev/null; then
    log "INFO" "Wavebox detectado. Verificando backup de config..."
    restore_zip_config "$CONFIGS_DIR/wavebox-$REAL_USER.zip" "$REAL_HOME/.config"
fi

if command -v zotero &>/dev/null; then
    log "INFO" "Zotero detectado. Verificando backup de config..."
    restore_zip_config "$CONFIGS_DIR/zotero-$REAL_USER.zip" "$REAL_HOME"
fi

log "SUCCESS" "Configuração do GNOME concluída."
