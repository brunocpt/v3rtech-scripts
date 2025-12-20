#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-xfce.sh
# Descrição: Otimizações e Pacotes para XFCE
# ==============================================================================

log "INFO" "Iniciando configuração do XFCE..."

# 1. Pacotes Extras
PKGS_XFCE=(
    "xfce4-goodies"
    "thunar-archive-plugin"
    "gvfs-backends" # Importante para SMB/Google Drive
    "mugshot"       # Editor de perfil de usuário
)

i "${PKGS_XFCE[@]}"

# 2. Configurações (Xfconf-query)
log "INFO" "Aplicando configurações do XFCE (xfconf)..."

# Desabilitar Som de Beep
if command -v xfconf-query &>/dev/null; then
    # Power Manager (Não bloquear ao suspender se desejar)
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false

    # Sessão (Não salvar sessão ao sair)
    xfconf-query -c xfce4-session -p /general/SaveOnExit -n -t bool -s false

    # Thunar (Exemplo: Single click false)
    xfconf-query -c thunar -p /misc-single-click -n -t bool -s false
fi

# 3. Helpers (Terminal Padrão, Browser)
# Cria arquivo de configuração de helpers
mkdir -p "$REAL_HOME/.config/xfce4"
cat <<EOF > "$REAL_HOME/.config/xfce4/helpers.rc"
WebBrowser=google-chrome
FileManager=Thunar
TerminalEmulator=xfce4-terminal
MailReader=thunderbird
EOF
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/xfce4/helpers.rc"

log "SUCCESS" "Configuração do XFCE concluída."
