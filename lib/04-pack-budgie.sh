#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-budgie.sh
# Descrição: Otimizações e Pacotes para Budgie Desktop
# ==============================================================================

log "INFO" "Iniciando configuração do Budgie Desktop..."

# 1. Ajustes de Sistema de Arquivos (Legado do script original)
# Remove exfatprogs conflitante se existir e instala utils
if command -v exfatprogs &>/dev/null; then
    log "INFO" "Removendo exfatprogs para evitar conflitos..."
    r exfatprogs
fi

# 2. Instalação de Pacotes Específicos
PKGS_BUDGIE=(
    # Utilitários de Disco e Rede
    "exfat-utils" "ntfs-3g" "gvfs-backends" "smbclient" "cifs-utils" "avahi-daemon" "gparted"

    # Core Budgie
    "budgie-desktop" "budgie-control-center" "budgie-screensaver" "budgie-extras"

    # Apps GNOME Auxiliares
    "gnome-calculator" "gnome-calendar" "gnome-control-center" "gnome-terminal"
    "gedit" "gthumb" "catfish" "amberol" "seahorse"

    # Nemo (Gerenciador de Arquivos)
    "nemo" "nemo-fileroller" "nemo-preview" "nemo-seahorse" "nemo-share"
    "nemo-image-converter" "nemo-terminal" "nemo-audio-tab"
)

i "${PKGS_BUDGIE[@]}"

# 3. Configuração do Nemo como Padrão
log "INFO" "Definindo Nemo como gerenciador de arquivos padrão..."
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

# 4. GSettings (Preferências Visuais e Comportamentais)
log "INFO" "Aplicando preferências do Budgie (GSettings)..."

# Janelas e Botões
gsettings set org.gnome.mutter center-new-windows true
gsettings set com.solus-project.budgie-wm button-layout 'close,minimize,maximize:appmenu'
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# Teclado e Atalhos
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab', '<Super>Tab']"

# Energia (Não bloquear tela, timeout ajustado)
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 7200
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false

# 5. Restauração de Configurações Específicas (Wavebox e Zotero)
# A instalação base deve vir do CSV, aqui restauramos apenas os dados.

if command -v wavebox &>/dev/null; then
    log "INFO" "Wavebox detectado. Restaurando configurações..."
    restore_zip_config "$CONFIGS_DIR/wavebox-$REAL_USER.zip" "$REAL_HOME/.config"
fi

if command -v zotero &>/dev/null; then
    log "INFO" "Zotero detectado. Restaurando configurações..."
    # Zotero costuma ficar na raiz da home ou .config dependendo da versão
    restore_zip_config "$CONFIGS_DIR/zotero-$REAL_USER.zip" "$REAL_HOME"
fi

# 6. Serviços de Sistema
log "INFO" "Habilitando serviços essenciais (Avahi, NetworkManager)..."
$SUDO systemctl enable --now avahi-daemon.service
$SUDO systemctl enable --now NetworkManager

# 7. Autostart do Synapse (se instalado)
if command -v synapse &>/dev/null; then
    mkdir -p "$REAL_HOME/.config/autostart"
    cat <<EOF > "$REAL_HOME/.config/autostart/synapse.desktop"
[Desktop Entry]
Name=Synapse
Exec=synapse --startup
Encoding=UTF-8
Type=Application
X-GNOME-Autostart-enabled=true
Icon=synapse
EOF
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/autostart/synapse.desktop"
fi

log "SUCCESS" "Configuração do Budgie Desktop concluída."
