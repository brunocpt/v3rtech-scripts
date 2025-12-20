#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/03-prepara-configs.sh
# Versão: 2.0.0
#
# Descrição: Configurações profundas do sistema e ambiente de usuário.
# Inclui:
#   1. Otimizações de Kernel (Sysctl) e Logs (Journald).
#   2. Configuração de Shell (Bashrc, Aliases).
#   3. Criação de Diretórios e Links Simbólicos Pessoais.
#   4. Restauração de Configurações de Apps (Cups, Geany, Grsync, etc).
#   5. Configuração de Impressoras e Rede (Hosts, Fstab).
#   6. Instalação de Scripts Utilitários e Atalhos .desktop.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando Configurações Gerais de Sistema e Usuário..."

# ==============================================================================
# 1. OTIMIZAÇÕES DE SISTEMA (Requer Root)
# ==============================================================================
log "INFO" "Aplicando otimizações de Kernel e Journald..."

# Journald (Limita tamanho dos logs)
# Usa sed para editar inline ou tee para criar
if [ -f /etc/systemd/journald.conf ]; then
    $SUDO sed -i 's/^#Storage=.*/Storage=none/' /etc/systemd/journald.conf
    $SUDO sed -i 's/^Storage=.*/Storage=none/' /etc/systemd/journald.conf
else
    echo -e "[Journal]\nStorage=none" | $SUDO tee /etc/systemd/journald.conf > /dev/null
fi

# Sysctl (Swappiness, Cache, Inotify)
# Cria arquivo dedicado para não poluir o sysctl.conf principal
cat <<EOF | $SUDO tee /etc/sysctl.d/99-v3rtech-tuning.conf > /dev/null
vm.swappiness=10
fs.inotify.max_user_watches=524288
fs.file-max=2097152
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5
EOF
$SUDO sysctl --system > /dev/null

# ZRAM (Se instalado)
if command -v zramctl &> /dev/null; then
    log "INFO" "ZRAM detectado. Ajustando configurações padrão..."
    # Configuração depende do pacote (zram-tools ou zram-config),
    # geralmente o default já é bom, mas aqui seria o lugar para tunar /etc/default/zramswap
fi

# ==============================================================================
# 2. CONFIGURAÇÃO DE SHELL E AMBIENTE (Usuário)
# ==============================================================================
log "INFO" "Configurando ambiente de shell ($REAL_USER)..."

# Copia .bashrc personalizado se existir na pasta configs
if [ -f "$CONFIGS_DIR/user.bashrc" ]; then
    log "INFO" "Instalando .bashrc personalizado..."
    # Backup do original
    [ -f "$REAL_HOME/.bashrc" ] && cp "$REAL_HOME/.bashrc" "$REAL_HOME/.bashrc.bak.$(date +%F)"

    cp "$CONFIGS_DIR/user.bashrc" "$REAL_HOME/.bashrc"

    # Injeta variáveis de ambiente essenciais se não estiverem lá
    if ! grep -q "V3RTECH_ENV_LOADED" "$REAL_HOME/.bashrc"; then
        cat <<EOF >> "$REAL_HOME/.bashrc"

# --- V3RTECH AUTO CONFIG ---
export PATH="\$PATH:/usr/local/bin:$INSTALL_DEST/utils"
export EDITOR=nano
# Carrega aliases se existir
if [ -f "$INSTALL_DEST/configs/aliases.geral" ]; then
    . "$INSTALL_DEST/configs/aliases.geral"
fi
export V3RTECH_ENV_LOADED=1
EOF
    fi
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
fi

# Copia arquivo de aliases global
if [ -f "$CONFIGS_DIR/aliases.geral" ]; then
    $SUDO cp "$CONFIGS_DIR/aliases.geral" "$INSTALL_DEST/configs/"
fi

# ==============================================================================
# 3. DIRETÓRIOS E LINKS SIMBÓLICOS
# ==============================================================================
log "INFO" "Padronizando diretórios pessoais..."

# Garante estrutura XDG (Documents, Downloads, etc)
# Remove pastas em pt-BR se o sistema estiver em inglês ou vice-versa,
# forçando o padrão desejado (Geralmente Inglês para compatibilidade ou Pt-BR)
# Aqui mantemos o padrão do seu script: Links simbólicos para /mnt/trabalho

if [ -d "/mnt/trabalho/Downloads" ]; then
    log "INFO" "Linkando Downloads para /mnt/trabalho/Downloads..."
    rm -rf "$REAL_HOME/Downloads"
    ln -sf "/mnt/trabalho/Downloads" "$REAL_HOME/Downloads"
fi

# Cria diretórios de organização
mkdir -p "$REAL_HOME"/{.config,.local/share,.local/bin,.backup,Desktop}
mkdir -p "$REAL_HOME/.config/autostart"

# Configura user-dirs.dirs se fornecido
if [ -f "$CONFIGS_DIR/user-dirs.dirs" ]; then
    cp "$CONFIGS_DIR/user-dirs.dirs" "$REAL_HOME/.config/"
fi

# Configura Favoritos GTK
if [ -f "$CONFIGS_DIR/bookmarks" ]; then
    mkdir -p "$REAL_HOME/.config/gtk-3.0"
    cp "$CONFIGS_DIR/bookmarks" "$REAL_HOME/.config/gtk-3.0/"
fi

# Ajusta permissões finais
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME"

# ==============================================================================
# 4. RESTAURAÇÃO DE CONFIGURAÇÕES DE APPS
# ==============================================================================
log "INFO" "Restaurando configurações de aplicativos..."

# Função auxiliar de restauração
restore_zip_config() {
    local zip_file="$1"
    local dest_dir="$2"

    if [ -f "$zip_file" ]; then
        log "INFO" "Restaurando $(basename "$zip_file")..."
        mkdir -p "$dest_dir"
        unzip -qo "$zip_file" -d "$dest_dir"
        chown -R "$REAL_USER:$REAL_USER" "$dest_dir"
    fi
}

# Geany
restore_zip_config "$CONFIGS_DIR/geany-$REAL_USER.zip" "$REAL_HOME/.config"

# Antigravity (Google)
restore_zip_config "$CONFIGS_DIR/antigravity-$REAL_USER.zip" "$REAL_HOME"

# Atalhos de Teclado (Baseado no DE detectado)
case "$DESKTOP_ENV" in
    kde)
        restore_zip_config "$CONFIGS_DIR/$REAL_USER-atalhos-kde.zip" "$REAL_HOME/.config"
        ;;
    gnome)
        # Gnome usa dconf, é mais chato. Se for ZIP de dconf dump:
        if [ -f "$CONFIGS_DIR/$REAL_USER-atalhos-gnome.zip" ]; then
            # Extrai temporariamente e carrega
            unzip -p "$CONFIGS_DIR/$REAL_USER-atalhos-gnome.zip" custom-keybindings.dconf | \
            runuser -u "$REAL_USER" -- dconf load /org/gnome/settings-daemon/plugins/media-keys/
        fi
        ;;
    xfce)
        restore_zip_config "$CONFIGS_DIR/$REAL_USER-atalhos-xfce.zip" "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
        ;;
esac

# Grsync
if [ -f "$CONFIGS_DIR/grsync.ini.ubuntu" ]; then
    mkdir -p "$REAL_HOME/.grsync"
    cp "$CONFIGS_DIR/grsync.ini.ubuntu" "$REAL_HOME/.grsync/grsync.ini"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.grsync"
fi

# Git Credentials (CUIDADO: Arquivo contém segredo)
if [ -f "$CONFIGS_DIR/.git-credentials" ]; then
    cp "$CONFIGS_DIR/.git-credentials" "$REAL_HOME/.git-credentials"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.git-credentials"
    runuser -u "$REAL_USER" -- git config --global credential.helper store
    log "WARN" "Credenciais do Git restauradas."
fi

# ==============================================================================
# 5. CONFIGURAÇÃO DE IMPRESSÃO (CUPS)
# ==============================================================================
if command -v cupsd &> /dev/null; then
    log "INFO" "Configurando serviço de impressão (CUPS)..."

    if [ -f "$CONFIGS_DIR/cupsd.conf" ]; then
        $SUDO cp "$CONFIGS_DIR/cupsd.conf" /etc/cups/cupsd.conf
    fi

    # Configura papel padrão para A4
    echo "a4" | $SUDO tee /etc/papersize > /dev/null

    $SUDO systemctl restart cups
    $SUDO systemctl enable cups
fi

# ==============================================================================
# 6. INSTALAÇÃO DE SCRIPTS E ATALHOS (.desktop)
# ==============================================================================
log "INFO" "Instalando scripts utilitários e atalhos..."

# Copia scripts da pasta utils/ para /usr/local/bin (Global)
if [ -d "$UTILS_DIR" ]; then
    # Copia recursivamente, preservando permissões
    $SUDO cp -r "$UTILS_DIR/"* /usr/local/bin/
    $SUDO chmod +x /usr/local/bin/*
fi

# Instalação de Fontes
if [ -d "$RESOURCES_DIR/fonts" ]; then
    log "INFO" "Instalando fontes personalizadas..."
    $SUDO mkdir -p /usr/share/fonts/v3rtech
    $SUDO cp -r "$RESOURCES_DIR/fonts/"* /usr/share/fonts/v3rtech/
    $SUDO fc-cache -f
fi

# Criação de Atalhos .desktop Personalizados
# Lê um array interno ou arquivo de definição.
# Exemplo baseado no seu script:
create_desktop_shortcut() {
    local name="$1"
    local exec="$2"
    local icon="$3"
    local filename="$4"

    cat <<EOF | $SUDO tee "/usr/share/applications/$filename.desktop" > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$exec
Icon=$icon
Terminal=false
Categories=Utility;
EOF
}

# Exemplo de uso para os seus scripts (ajuste os caminhos de ícone conforme necessário)
# create_desktop_shortcut "Copiador de Pastas" "/usr/local/bin/cpa" "folder-copy" "cpa"
# create_desktop_shortcut "Atualizador Geral" "/usr/local/bin/up" "system-upgrade" "upall"

# ==============================================================================
# 7. CONFIGURAÇÃO VISUAL DE BOOT (PLYMOUTH)
# ==============================================================================
log "INFO" "Configurando tema de boot (Plymouth)..."

# Instala o Plymouth se não estiver presente
if ! command -v plymouth &>/dev/null; then
    i plymouth plymouth-themes
fi

# Configura o tema BGRT (Melhor para UEFI, mantém logo da placa mãe)
# Se não for UEFI ou BGRT falhar, spinner é o fallback
if command -v plymouth-set-default-theme &>/dev/null; then
    if [ -d "/usr/share/plymouth/themes/bgrt" ]; then
        log "INFO" "Definindo tema Plymouth: BGRT..."
        $SUDO plymouth-set-default-theme -R bgrt
    else
        log "INFO" "Definindo tema Plymouth: Spinner..."
        $SUDO plymouth-set-default-theme -R spinner
    fi
else
    log "WARN" "Plymouth instalado mas comando de configuração não encontrado."
fi

log "SUCCESS" "Configurações gerais aplicadas."
