#!/bin/bash
# ==============================================================================
# Script: setup-system.sh
# Versão: 4.8.0
# Data: 2026-02-25
# Objetivo: Script completo para configuração de sistema
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Configura:
# 1. PATH global com scripts do projeto
# 2. Aliases globais em /etc/bash.bashrc
# 3. Sudo sem senha (avançado)
# 4. Otimizações de kernel (sysctl)
# 5. Limites de journald
# 6. Diretórios de configuração e logs
# 7. Diretórios de usuário, links, bookmarks, FUSE, .hushlogin e grupos
# 8. Mounts de rede (fstab e hosts)
# 9. Plymouth (com hooks) e otimizações de Bootloader (GRUB/Systemd-boot)
# 10. Restauração de atalhos de teclado por ambiente de desktop
# 11. Criação de desktop entries para scripts utilitários
#
# ==============================================================================

# Carrega dependências
BASE_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts"
[ ! -d "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"
UTILS_DIR="$BASE_DIR/utils"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# VALIDAÇÃO INICIAL
# ==============================================================================

if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$BASE_DIR/lib/detect-system.sh" || die "Falha ao detectar sistema"
fi

section "Configuração de Sistema"

# ==============================================================================
# 1. CONFIGURAÇÃO DE PATH GLOBAL
# ==============================================================================

log "STEP" "Configurando PATH global..."
PATH_MARKER_BEGIN="# === V3RTECH SCRIPTS: Global PATH BEGIN ===="
PATH_MARKER_END="# === V3RTECH SCRIPTS: Global PATH END ===="

if grep -q "$PATH_MARKER_BEGIN" /etc/bash.bashrc 2>/dev/null; then
    log "INFO" "Removendo PATH anterior..."
    $SUDO sed -i "/$PATH_MARKER_BEGIN/,/$PATH_MARKER_END/d" /etc/bash.bashrc
fi

log "INFO" "Adicionando PATH global para $UTILS_DIR..."
cat << EOF | $SUDO tee -a /etc/bash.bashrc > /dev/null
# === V3RTECH SCRIPTS: Global PATH BEGIN ====
if [ -d "$UTILS_DIR" ]; then
    if [[ ":\$PATH:" != *":$UTILS_DIR:"* ]]; then
        export PATH="\$PATH:$UTILS_DIR"
    fi
fi
# === V3RTECH SCRIPTS: Global PATH END ====
EOF
log "SUCCESS" "PATH global configurado"

# ==============================================================================
# 2. CONFIGURAÇÃO DE ALIASES GLOBAIS
# ==============================================================================

log "STEP" "Configurando aliases globais..."
ALIAS_MARKER_BEGIN="# === V3RTECH SCRIPTS: Aliases BEGIN ===="
ALIAS_MARKER_END="# === V3RTECH SCRIPTS: Aliases END ===="

if grep -q "$ALIAS_MARKER_BEGIN" /etc/bash.bashrc 2>/dev/null; then
    log "INFO" "Removendo aliases anteriores..."
    $SUDO sed -i "/$ALIAS_MARKER_BEGIN/,/$ALIAS_MARKER_END/d" /etc/bash.bashrc
fi

if [ -f "$CONFIGS_DIR/aliases.geral" ]; then
    log "INFO" "Carregando aliases de $CONFIGS_DIR/aliases.geral..."
    cat << EOF | $SUDO tee -a /etc/bash.bashrc > /dev/null
# === V3RTECH SCRIPTS: Aliases BEGIN ====
if [ -f "$CONFIGS_DIR/aliases.geral" ]; then
    source "$CONFIGS_DIR/aliases.geral"
fi
# === V3RTECH SCRIPTS: Aliases END ====
EOF
    log "SUCCESS" "Aliases globais configurados"
else
    log "WARN" "Arquivo de aliases não encontrado: $CONFIGS_DIR/aliases.geral"
fi

# ==============================================================================
# 3. CONFIGURAÇÃO DE SUDO SEM SENHA (AVANÇADO)
# ==============================================================================

log "STEP" "Configurando sudo sem senha..."
sudo_group="sudo"
if [ "$DISTRO_FAMILY" = "arch" ] || [ "$DISTRO_FAMILY" = "fedora" ]; then
    sudo_group="wheel"
fi

if ! id -nG "$REAL_USER" 2>/dev/null | grep -qw "$sudo_group"; then
    log "INFO" "Adicionando $REAL_USER ao grupo $sudo_group..."
    $SUDO usermod -aG "$sudo_group" "$REAL_USER"
fi

if id -nG "$REAL_USER" 2>/dev/null | grep -qw "$sudo_group"; then
    log "INFO" "Usuário $REAL_USER está no grupo $sudo_group"
    sudoers_file="/etc/sudoers.d/v3rtech-$REAL_USER"
    if [ -f "$sudoers_file" ]; then
        log "INFO" "Removendo sudoers anterior..."
        $SUDO rm -f "$sudoers_file"
    fi
    
    SUDOERS_TMP=$($SUDO mktemp)
    echo "$REAL_USER ALL=(ALL) NOPASSWD:ALL" | $SUDO tee "$SUDOERS_TMP" > /dev/null
    
    if $SUDO visudo -cf "$SUDOERS_TMP" &>/dev/null; then
        $SUDO install -m 0440 -o root -g root "$SUDOERS_TMP" "$sudoers_file"
        log "SUCCESS" "Sudo sem senha configurado para $REAL_USER"
    else
        log "ERROR" "Falha ao validar sudoers"
    fi
    $SUDO rm -f "$SUDOERS_TMP"
else
    log "WARN" "Usuário $REAL_USER não está no grupo $sudo_group"
    log "INFO" "Sudo sem senha não foi configurado"
fi

# ==============================================================================
# 4. OTIMIZAÇÕES DE KERNEL (sysctl)
# ==============================================================================

log "STEP" "Aplicando otimizações de kernel..."
SYSCTL_MARKER_BEGIN="# === V3RTECH SCRIPTS: Kernel Optimizations BEGIN ===="
SYSCTL_MARKER_END="# === V3RTECH SCRIPTS: Kernel Optimizations END ===="

if grep -q "$SYSCTL_MARKER_BEGIN" /etc/sysctl.d/99-v3rtech.conf 2>/dev/null; then
    log "INFO" "Removendo otimizações anteriores..."
    $SUDO sed -i "/$SYSCTL_MARKER_BEGIN/,/$SYSCTL_MARKER_END/d" /etc/sysctl.d/99-v3rtech.conf
fi

cat << 'EOF' | $SUDO tee /etc/sysctl.d/99-v3rtech.conf > /dev/null
# === V3RTECH SCRIPTS: Kernel Optimizations BEGIN ===
fs.file-max = 2097152
fs.nr_open = 2097152
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
kernel.sysrq = 0
# === V3RTECH SCRIPTS: Kernel Optimizations END ===
EOF

$SUDO sysctl -p /etc/sysctl.d/99-v3rtech.conf > /dev/null 2>&1 || true
log "SUCCESS" "Otimizações de kernel aplicadas"

# ==============================================================================
# 5. CONFIGURAÇÃO DE JOURNALD
# ==============================================================================

log "STEP" "Configurando journald (limites de log)..."
$SUDO mkdir -p /etc/systemd/journald.conf.d/
cat << 'EOF' | $SUDO tee /etc/systemd/journald.conf.d/99-v3rtech.conf > /dev/null
# === V3RTECH SCRIPTS: Journald Config BEGIN ===
SystemMaxUse=500M
SystemMaxFileSize=100M
MaxRetentionSec=7day
# === V3RTECH SCRIPTS: Journald Config END ===
EOF
$SUDO systemctl restart systemd-journald || true
log "SUCCESS" "Journald configurado"

# ==============================================================================
# 6. CRIAÇÃO DE DIRETÓRIOS NECESSÁRIOS
# ==============================================================================

log "STEP" "Criando diretórios necessários..."
mkdir -p "$CONFIG_HOME" "$LOG_DIR"
chmod 700 "$CONFIG_HOME"
log "SUCCESS" "Diretórios criados"

# ==============================================================================
# 7. DIRETÓRIOS DE USUÁRIO, LINKS, BOOKMARKS, GRUPOS E FUSE
# ==============================================================================

log "STEP" "Configurando diretórios de usuário, links, bookmarks, grupos e FUSE..."

# --- 7.1. Criação de Diretórios Essenciais ---
mkdir -p "$REAL_HOME"/{.backup,.config/autostart,.config/systemd/user,Desktop,Documents,Pictures,Music,Videos,.local/bin}
$SUDO mkdir -p /etc/sudoers.d
$SUDO chmod 755 /usr/local/bin

# --- 7.2. Links Simbólicos (com proteção de loop) ---
create_safe_symlink() {
    local target="$1"; local link_path="$2"; local link_name="$3"
    if [ ! -d "$target" ]; then log "DEBUG" "Alvo não existe: $target"; return 1; fi
    local target_real=$(cd "$target" 2>/dev/null && pwd -P)
    local link_real=""
    if [ -L "$link_path" ]; then link_real=$(cd "$(dirname "$link_path")" 2>/dev/null && pwd -P)/$(basename "$(readlink "$link_path")"); fi
    if [ "$link_real" = "$target_real" ]; then log "DEBUG" "Link já existe e está correto: $link_name"; return 0; fi
    if [[ "$target_real" == "$link_path"* ]]; then log "WARN" "⚠ Loop detectado! Não criando link: $link_name"; return 1; fi
    if [ -L "$link_path" ]; then rm -f "$link_path"; fi
    if ln -sf "$target" "$link_path"; then log "SUCCESS" "Link criado: $link_name → $target"; return 0; else log "WARN" "⚠ Falha ao criar link: $link_name"; return 1; fi
}

if [ -d "$REAL_HOME/Downloads" ] && [ ! -L "$REAL_HOME/Downloads" ]; then rm -rf "$REAL_HOME/Downloads"; fi
create_safe_symlink "/mnt/trabalho/Downloads" "$REAL_HOME/Downloads" "~/Downloads"
if [ ! -e "$REAL_HOME/Downloads" ]; then mkdir -p "$REAL_HOME/Downloads"; log "INFO" "Diretório local criado: ~/Downloads"; fi

# --- 7.3. Bookmarks GTK ---
GTK_BOOKMARKS="$REAL_HOME/.config/gtk-3.0/bookmarks"
mkdir -p "$(dirname "$GTK_BOOKMARKS")"
[ -f "$GTK_BOOKMARKS" ] && rm -f "$GTK_BOOKMARKS"
BOOKMARKS_SOURCE="$BASE_DIR/configs/$REAL_USER-bookmarks"
if [ -f "$BOOKMARKS_SOURCE" ]; then
    cp "$BOOKMARKS_SOURCE" "$GTK_BOOKMARKS"
else
    {
        echo "file://$REAL_HOME Desktop"
        echo "file://$REAL_HOME/Downloads Downloads"
        if [ -d "/mnt/trabalho" ]; then echo "file:///mnt/trabalho Trabalho"; fi
    } > "$GTK_BOOKMARKS"
fi
chown "$REAL_USER:$REAL_USER" "$GTK_BOOKMARKS"

# --- 7.4. Diretórios XDG ---
XDG_DIRS="$REAL_HOME/.config/user-dirs.dirs"
mkdir -p "$(dirname "$XDG_DIRS")"
cat > "$XDG_DIRS" <<EOF
XDG_DESKTOP_DIR="\$HOME/Desktop"
XDG_DOWNLOAD_DIR="\$HOME/Downloads"
XDG_DOCUMENTS_DIR="\$HOME/Documents"
XDG_MUSIC_DIR="\$HOME/Music"
XDG_PICTURES_DIR="\$HOME/Pictures"
XDG_VIDEOS_DIR="\$HOME/Videos"
EOF
chown "$REAL_USER:$REAL_USER" "$XDG_DIRS"
$SUDO -u "$REAL_USER" xdg-user-dirs-update 2>/dev/null || true

# --- 7.5. Login Silencioso (.hushlogin) ---
touch "$REAL_HOME/.hushlogin"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.hushlogin"

# --- 7.6. Grupos de Usuário ---
if ! id -nG "$REAL_USER" | grep -qw "fuse"; then $SUDO usermod -aG fuse "$REAL_USER"; fi
$SUDO groupadd -r autologin 2>/dev/null || true
$SUDO gpasswd -a "$REAL_USER" autologin 2>/dev/null || true

# --- 7.7. FUSE (com deduplicação) ---
FUSE_CONF="/etc/fuse.conf"
if [ -f "$FUSE_CONF" ]; then
    OCURRENCIAS=$(grep -cE "^#?[[:space:]]*user_allow_other[[:space:]]*$" "$FUSE_CONF")
    if [ "$OCURRENCIAS" -gt 1 ]; then
        $SUDO sed -i '0,/^#\?[[:space:]]*user_allow_other[[:space:]]*$/{s/^#\?[[:space:]]*user_allow_other[[:space:]]*$/USER_KEEP_MARKER/}; /^#\?[[:space:]]*user_allow_other[[:space:]]*$/d; s/USER_KEEP_MARKER/user_allow_other/' "$FUSE_CONF"
    fi
    if grep -qE "^user_allow_other[[:space:]]*$" "$FUSE_CONF"; then
        log "INFO" "user_allow_other já está configurado em $FUSE_CONF"
    elif grep -qE "^#[[:space:]]*user_allow_other[[:space:]]*$" "$FUSE_CONF"; then
        $SUDO sed -i "s|^#[[:space:]]*user_allow_other[[:space:]]*$|user_allow_other|" "$FUSE_CONF"
    else
        echo "user_allow_other" | $SUDO tee -a "$FUSE_CONF" > /dev/null
    fi
else
    echo "user_allow_other" | $SUDO tee "$FUSE_CONF" > /dev/null
fi
log "SUCCESS" "Diretórios, links, bookmarks, grupos e FUSE configurados"

# ==============================================================================
# 8. CONFIGURAÇÃO DE MOUNTS DE REDE (FSTAB)
# ==============================================================================

log "STEP" "Configurando mounts de rede (fstab)..."
HOSTS_FILE="$BASE_DIR/configs/hosts"
FSTAB_LAN_FILE="$BASE_DIR/configs/fstab.lan"

if [ -f "$HOSTS_FILE" ]; then
    if grep -q "# === V3RTECH SCRIPTS: HOSTS BEGIN ===" /etc/hosts 2>/dev/null; then
        $SUDO sed -i '/# === V3RTECH SCRIPTS: HOSTS BEGIN ===/,/# === V3RTECH SCRIPTS: HOSTS END ===/d' /etc/hosts
    fi
    echo "# === V3RTECH SCRIPTS: HOSTS BEGIN ===" | $SUDO tee -a /etc/hosts > /dev/null
    cat "$HOSTS_FILE" | $SUDO tee -a /etc/hosts > /dev/null
    echo "# === V3RTECH SCRIPTS: HOSTS END ===" | $SUDO tee -a /etc/hosts > /dev/null
fi

if [ -f "$FSTAB_LAN_FILE" ]; then
    i cifs-utils
    if grep -q "# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===" /etc/fstab 2>/dev/null; then
        $SUDO sed -i '/# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===/,/# === V3RTECH SCRIPTS: FSTAB MOUNTS END ===/d' /etc/fstab
    fi
    echo "# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===" | $SUDO tee -a /etc/fstab > /dev/null
    cat "$FSTAB_LAN_FILE" | $SUDO tee -a /etc/fstab > /dev/null
    echo "# === V3RTECH SCRIPTS: FSTAB MOUNTS END ===" | $SUDO tee -a /etc/fstab > /dev/null
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        mount_point=$(echo "$line" | awk '{print $2}')
        if [[ "$mount_point" =~ ^/mnt/ ]]; then $SUDO mkdir -p "$mount_point"; fi
    done < "$FSTAB_LAN_FILE"
    log "SUCCESS" "Mounts de rede configurados"
fi

# ==============================================================================
# 9. PLYMOUTH E BOOTLOADER
# ==============================================================================

log "STEP" "Configurando Plymouth e otimizando Bootloader..."

# --- 9.1. Instalação e Configuração de Hooks ---
log "INFO" "Instalando e configurando Plymouth..."

case "$DISTRO_FAMILY" in
    debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
        i plymouth plymouth-themes
        if command -v plymouth-set-default-theme &>/dev/null; then
            if [ -d "/usr/share/plymouth/themes/spinner" ]; then
                $SUDO plymouth-set-default-theme -R spinner 2>/dev/null || true
            elif [ -d "/usr/share/plymouth/themes/bgrt" ]; then
                $SUDO plymouth-set-default-theme -R bgrt 2>/dev/null || true
            fi
        fi
        ;;
    arch|manjaro|endeavouros|biglinux)
        i plymouth
        if [ -f /etc/mkinitcpio.conf ]; then
            if ! grep -q "^HOOKS=.*plymouth" /etc/mkinitcpio.conf; then
                $SUDO cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak.$(date +%Y%m%d-%H%M%S)"
                $SUDO sed -i -E 's/(HOOKS=\(.*)(udev.*)/\1plymouth \2/' /etc/mkinitcpio.conf
            fi
        fi
        if command -v plymouth-set-default-theme &>/dev/null; then
            $SUDO plymouth-set-default-theme bgrt 2>/dev/null || true
        fi
        ;;
    fedora|redhat|almalinux|nobara)
        i plymouth plymouth-theme-spinner
        if command -v plymouth-set-default-theme &>/dev/null; then
            $SUDO plymouth-set-default-theme spinner 2>/dev/null || true
        fi
        ;;
esac

# --- 9.2. Definição de Flags de Kernel ---
log "INFO" "Detectando hardware e definindo parâmetros de kernel..."
CMDLINE_ADD="quiet splash loglevel=0 rd.udev.log_level=0 systemd.show_status=false noresume ipv6.disable=1 nvme_core.default_ps_max_latency_us=5500"

GPU_INFO=$(lspci -nnk | grep -iE 'vga|3d|display' | tr '[:upper:]' '[:lower:]' || true)

if [[ "$GPU_INFO" =~ "intel" ]]; then
    log "INFO" "GPU Intel detectada. Aplicando otimizações i915..."
    CMDLINE_ADD="$CMDLINE_ADD i915.fastboot=1 i915.enable_psr=2 i915.enable_fbc=1"
fi

if [[ "$GPU_INFO" =~ "amd" ]] || [[ "$GPU_INFO" =~ "advanced micro devices" ]]; then
    log "INFO" "GPU AMD detectada. Ativando Display Core..."
    CMDLINE_ADD="$CMDLINE_ADD amdgpu.dc=1"
fi

if [[ "$GPU_INFO" =~ "nvidia" ]]; then
    log "INFO" "GPU NVIDIA detectada. Preparando flags DRM..."
    CMDLINE_ADD="$CMDLINE_ADD nvidia-drm.modeset=1"
    MODPROBE_FILE="/etc/modprobe.d/nvidia-kms.conf"
    if [ ! -f "$MODPROBE_FILE" ] || ! grep -q "modeset=1" "$MODPROBE_FILE"; then
        log "INFO" "Criando $MODPROBE_FILE..."
        echo "options nvidia-drm modeset=1" | $SUDO tee "$MODPROBE_FILE" > /dev/null
    fi
fi

log "INFO" "Flags de kernel a aplicar: $CMDLINE_ADD"

# --- 9.3. Aplicação no Bootloader ---

# --- RAMO SYSTEMD-BOOT ---
if $SUDO bootctl is-installed >/dev/null 2>&1; then
    log "INFO" "Bootloader detectado: systemd-boot"
    
    # Ajusta timeout em /boot/loader/loader.conf
    if [ -f /boot/loader/loader.conf ]; then
        log "INFO" "Atualizando /boot/loader/loader.conf..."
        $SUDO cp /boot/loader/loader.conf "/boot/loader/loader.conf.bak.$(date +%F-%H%M)"
        if grep -q "^timeout" /boot/loader/loader.conf; then
            $SUDO sed -i 's/^timeout.*/timeout 1/' /boot/loader/loader.conf
        else
            echo "timeout 1" | $SUDO tee -a /boot/loader/loader.conf > /dev/null
        fi
    fi
    
    # Atualiza parâmetros de kernel nos arquivos de entrada
    if [ -d /boot/loader/entries ]; then
        log "INFO" "Atualizando parâmetros de kernel em /boot/loader/entries/..."
        for entry_file in /boot/loader/entries/*.conf; do
            if [ -f "$entry_file" ]; then
                $SUDO cp "$entry_file" "$entry_file.bak.$(date +%F-%H%M)"
                # Remove parâmetros antigos
                $SUDO sed -i 's/quiet//g; s/splash//g; s/loglevel=[0-9]//g; s/systemd.show_status=[^ ]*//g; s/rd.udev.log_level=[^ ]*//g; s/zswap.enabled=[^ ]*//g; s/nvidia-drm.modeset=[^ ]*//g; s/i915\.[^ ]*//g; s/amdgpu\.[^ ]*//g' "$entry_file"
                # Adiciona novos parâmetros
                $SUDO sed -i "s/^options /options $CMDLINE_ADD /" "$entry_file"
                # Remove espaços duplicados
                $SUDO sed -i 's/ \+/ /g' "$entry_file"
            fi
        done
        log "SUCCESS" "Parâmetros de kernel atualizados no systemd-boot"
    elif [ -f /etc/kernel/cmdline ]; then
        # Fallback para sistemas com /etc/kernel/cmdline (Fedora)
        log "INFO" "Atualizando /etc/kernel/cmdline..."
        $SUDO cp /etc/kernel/cmdline "/etc/kernel/cmdline.bak.$(date +%F-%H%M)"
        CURRENT_CMD=$(cat /etc/kernel/cmdline)
        CLEAN_CMD=$(echo "$CURRENT_CMD" | sed -E 's/(quiet|loglevel=[0-9]+|nvidia-drm.modeset=[0-1])//g')
        echo "$CLEAN_CMD $CMDLINE_ADD" | tr -s ' ' | $SUDO tee /etc/kernel/cmdline > /dev/null
        if command -v kernel-install >/dev/null; then
            $SUDO kernel-install upgrade "$(uname -r)" 2>/dev/null || true
        fi
    else
        log "WARN" "systemd-boot detectado mas nenhum arquivo de configuração foi encontrado"
    fi
    
    # Atualiza bootctl
    $SUDO bootctl update

# --- RAMO GRUB ---
elif [ -f /etc/default/grub ]; then
    log "INFO" "Bootloader detectado: GRUB"
    GRUB_FILE="/etc/default/grub"
    $SUDO cp "$GRUB_FILE" "${GRUB_FILE}.bak.$(date +%F-%H%M)"
    TMP_GRUB=$(mktemp)
    cp "$GRUB_FILE" "$TMP_GRUB"

    set_grub_key() { local key="$1"; local val="$2"; if grep -q "^${key}=" "$TMP_GRUB"; then sed -i "s|^${key}=.*|${key}=${val}|" "$TMP_GRUB"; elif grep -q "^#${key}=" "$TMP_GRUB"; then sed -i "s|^#${key}=.*|${key}=${val}|" "$TMP_GRUB"; else echo "${key}=${val}" >> "$TMP_GRUB"; fi; }

    log "INFO" "Aplicando preferências do GRUB (Timeout 1, Hidden)..."
    set_grub_key "GRUB_TIMEOUT_STYLE" "menu"
    set_grub_key "GRUB_TIMEOUT" "1"
    set_grub_key "GRUB_RECORDFAIL_TIMEOUT" "1"
    set_grub_key "GRUB_DISABLE_OS_PROBER" "true"
    set_grub_key "GRUB_DISABLE_SUBMENU" "y"

    CURRENT_LINE=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$TMP_GRUB" | cut -d'"' -f2)
    NEW_LINE="$CURRENT_LINE $CMDLINE_ADD"
    NEW_LINE=$(echo "$NEW_LINE" | tr -s ' ')
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\\"$NEW_LINE\\"|" "$TMP_GRUB"

    $SUDO cp "$TMP_GRUB" "$GRUB_FILE"
    rm "$TMP_GRUB"
fi

# --- 9.4. Regeneração de Imagens e Configs ---
log "INFO" "Regenerando imagem de boot e configurações..."

if command -v update-initramfs >/dev/null 2>&1; then
    $SUDO update-initramfs -u -k all
elif command -v dracut >/dev/null 2>&1; then
    $SUDO dracut -f
elif command -v mkinitcpio >/dev/null 2>&1; then
    $SUDO mkinitcpio -P
fi

if command -v update-grub >/dev/null 2>&1; then
    $SUDO update-grub
elif command -v grub-mkconfig >/dev/null 2>&1; then
    $SUDO grub-mkconfig -o /boot/grub/grub.cfg
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    if [ -d /sys/firmware/efi ]; then
        grub_cfg=$(find /boot/efi -name grub.cfg | head -n 1)
        [ -z "$grub_cfg" ] && grub_cfg="/boot/grub2/grub.cfg"
        $SUDO grub2-mkconfig -o "$grub_cfg"
    else
        $SUDO grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
fi

log "SUCCESS" "Plymouth e Bootloader configurados"

# ==============================================================================
# 10. RESTAURAÇÃO DE ATALHOS DE TECLADO
# ==============================================================================

log "STEP" "Restaurando atalhos de teclado..."
SHORTCUTS_BACKUP_DIR="$BASE_DIR/backups"
DE="$DESKTOP_ENV"

if [ "$DE" = "kde" ]; then
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-kde.zip"
    if [ -f "$SHORTCUTS_ZIP" ]; then unzip -o "$SHORTCUTS_ZIP" -d "$REAL_HOME/.config/" 2>/dev/null; fi
elif [ "$DE" = "gnome" ] || [ "$DE" = "budgie" ]; then
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-gnome.zip"
    if [ -f "$SHORTCUTS_ZIP" ]; then unzip -p "$SHORTCUTS_ZIP" "custom-keybindings.dconf" 2>/dev/null | $SUDO -u "$REAL_USER" dconf load /org/gnome/settings-daemon/plugins/media-keys/ 2>/dev/null; fi
elif [ "$DE" = "xfce" ]; then
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-xfce.zip"
    if [ -f "$SHORTCUTS_ZIP" ]; then
        mkdir -p "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
        unzip -o "$SHORTCUTS_ZIP" -d "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>/dev/null
        $SUDO -u "$REAL_USER" xfce4-panel -r 2>/dev/null || true
    fi
fi
$SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/" 2>/dev/null || true
log "SUCCESS" "Restauração de atalhos concluída (se aplicável)"



# ==============================================================================
# 11. CRIAÇÃO DE DESKTOP ENTRIES
# ==============================================================================

log "STEP" "Criando desktop entries para scripts utilitários..."

create_desktop_entries() {
    local LOCATION_DEST="$REAL_HOME/.local/share/applications"
    local SCRIPT_BASE="$UTILS_DIR"
    local ICON_BASE="$RESOURCES_DIR/atalhos"

    # Cria pasta de destino, se necessário
    mkdir -p "$LOCATION_DEST"

    # Array de entradas: "id|nome|script|ícone"
    local ENTRADAS=(
        "metaflatpaks|Instalador de Metapacks Flatpaks|metaflatpaks.sh|metapacks.svg"
        "cpa|Copiador de Pastas|cpa|cpa.svg"
        "cpplay|Copiador de Playlists para Pendrive|cpplay.sh|cpplay.svg"
        "upall|Atualizador de Aplicativos|upall.sh|upall.svg"
        "wtt|Whisper Transcriber|wtt.sh|wtt.svg"
        "extrai-legendas|Extrai Legendas|extrai-legendas.sh|extrai-legendas.svg"
        "video-converter-gui|Converte arquivos de vídeo|video-converter-gui.sh|video-converter-gui.svg"
        "restaura-config|Restaurar Configurações|restaura-config.sh|restaura-config.svg"
        "configs-zip|Backup de Configurações Pessoais|configs-zip.sh|configs-zip.svg"
        "ts|Tradutor de Legendas|ts.sh|ts.svg"
    )

    local DESKTOP_ENTRIES_CREATED=0
    local DESKTOP_ENTRIES_FAILED=0

    for entry in "${ENTRADAS[@]}"; do
        IFS="|" read -r file name script_file icon_file <<< "$entry"
        local EXEC_CMD="$SCRIPT_BASE/$script_file"
        local ICON_PATH="$ICON_BASE/$icon_file"
        local DESKTOP_FILE="$LOCATION_DEST/${file}.desktop"

        # Idempotência: Verifica se o arquivo .desktop já existe e tem o conteúdo correto
        if [ -f "$DESKTOP_FILE" ]; then
            if grep -q "Exec=$EXEC_CMD" "$DESKTOP_FILE" && grep -q "Icon=$ICON_PATH" "$DESKTOP_FILE"; then
                log "DEBUG" "Desktop entry ✓ $file já está atualizada."
                continue
            fi
        fi

        # Verifica se o script existe e é executável
        if [ ! -f "$EXEC_CMD" ]; then
            log "WARN" "Script não encontrado: $EXEC_CMD"
            ((DESKTOP_ENTRIES_FAILED++))
            continue
        fi

        # Torna o script executável
        $SUDO chmod +x "$EXEC_CMD" 2>/dev/null || true

        # Verifica se o ícone existe
        if [ ! -f "$ICON_PATH" ]; then
            log "WARN" "Ícone não encontrado: $ICON_PATH (usando ícone padrão)"
            ICON_PATH="application-x-executable"
        fi

        # Cria o arquivo .desktop
        log "DEBUG" "Criando/Atualizando desktop entry: $file"
        tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=$name
Comment=
Exec=$EXEC_CMD
Icon=$ICON_PATH
Type=Application
Terminal=false
NoDisplay=false
Categories=Utility
X-KDE-Trusted=true
EOF

        # Ajusta permissões do arquivo .desktop
        $SUDO chmod 644 "$DESKTOP_FILE"
        log "SUCCESS" "✓ Desktop entry criada/atualizada: $file"
        ((DESKTOP_ENTRIES_CREATED++))
    done

    log "INFO" "Desktop entries: $DESKTOP_ENTRIES_CREATED criadas/atualizadas, $DESKTOP_ENTRIES_FAILED falhadas"
}

# Chama a função para criar os desktop entries
create_desktop_entries

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

section "Sistema Configurado"
log "SUCCESS" "Configuração de sistema concluída!"
log "INFO" "PATH, aliases, sudo, kernel, boot, Plymouth, mounts, atalhos e desktop entries foram configurados globalmente"
log "INFO" "Reinicie o terminal ou a sessão para aplicar todas as mudanças"
