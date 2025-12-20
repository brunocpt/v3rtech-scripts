#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-cosmic.sh
# Descrição: Instalação e Configuração do COSMIC Desktop (Rust-based)
# ==============================================================================

log "INFO" "Iniciando configuração do COSMIC Desktop Environment..."

# 1. Instalação de Pacotes Essenciais
# Nota: Como o Cosmic é novo, os nomes dos pacotes podem variar.
# O 'i' tentará instalar. No Arch (seu script original), usa-se paru para muitos destes.

PKGS_COSMIC=(
    "cosmic-session"
    "cosmic-wallpapers"
    "power-profiles-daemon" # Gestão de energia recomendada
    "seahorse"              # Gerenciador de chaves
    "gnome-keyring"         # Chaveiro
    "ulauncher"             # Launcher de apps
)

i "${PKGS_COSMIC[@]}"

# 2. Ajustes de Preferências (GSettings/Cosmic Settings)
log "INFO" "Aplicando preferências do ambiente..."

# O Cosmic ainda usa muito do backend GNOME/GTK para configurações,
# mas está migrando para configurações próprias. Aplicamos o que é seguro.

# Tema Claro (Baseado no seu script original)
if command -v gsettings &>/dev/null; then
    # Esquema de cores
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

    # Screenshots em ~/Imagens
    if [ -d "$REAL_HOME/Imagens" ]; then
        gsettings set org.gnome.gnome-screenshot auto-save-directory "file://$REAL_HOME/Imagens"
    fi

    # Energia (Não suspender conectado à tomada)
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

    # NumLock Ativo
    gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true

    # Escala Fracionada (Experimental no Mutter/Gnome, nativa no Cosmic-comp, mas mal não faz)
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
fi

# 3. Configuração do Ulauncher
if command -v ulauncher &>/dev/null; then
    log "INFO" "Definindo Ulauncher como handler padrão..."
    xdg-mime default ulauncher.desktop x-scheme-handler/application

    # Habilitar autostart do Ulauncher se necessário
    if [ ! -f "$REAL_HOME/.config/autostart/ulauncher.desktop" ]; then
        mkdir -p "$REAL_HOME/.config/autostart"
        cp /usr/share/applications/ulauncher.desktop "$REAL_HOME/.config/autostart/" 2>/dev/null
    fi
fi

# 4. Verificação de Sessão (Wayland)
# O Cosmic é Wayland-first. Verificamos apenas para log.
if [[ "${SESSION_TYPE,,}" == *"wayland"* ]]; then
    log "INFO" "Sessão Wayland detectada. O COSMIC deve funcionar com aceleração total."
else
    log "WARN" "Sessão atual não parece ser Wayland ($SESSION_TYPE). O COSMIC requer Wayland para funcionar corretamente."
fi

log "SUCCESS" "Configuração do COSMIC finalizada."
