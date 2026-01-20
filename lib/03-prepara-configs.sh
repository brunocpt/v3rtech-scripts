#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/03-prepara-configs.sh
# Versão: 8.2.0 (Com Boot Options Multi-Distro)
#
# Descrição: Configurações profundas do sistema.
# Funcionalidades:
#   1. PATH idempotente com marcadores de bloco
#   2. Limpeza de PATH de entradas repetidas
#   3. Aliases com proteção contra duplicação
#   4. Desktop entries para scripts utilitários
#   5. Links simbólicos em /usr/local/bin
#   6. Instalação de fontes
#   7. Configuração de tema de boot (Plymouth) - MULTI-DISTRO
#   8. Configuração de boot options - MULTI-DISTRO
# ==============================================================================

log "STEP" "Iniciando Configurações Gerais de Sistema..."

# Variáveis de Caminho
INSTALL_TARGET="/usr/local/share/scripts/v3rtech-scripts"
UTILS_DIR="$INSTALL_TARGET/utils"
CONFIG_DIR="$INSTALL_TARGET/configs"
RESOURCES_DIR="$INSTALL_TARGET/resources"
SYSTEM_BASHRC="/etc/bash.bashrc"

# ==============================================================================
# FUNÇÃO: Limpar PATH de Entradas Repetidas
# ==============================================================================
clean_path() {
    local path_var="$1"
    local cleaned=""

    # Declara array associativo para rastrear componentes já vistos
    declare -A seen

    # Divide o PATH em componentes e remove duplicatas
    IFS=':' read -ra components <<< "$path_var"

    for component in "${components[@]}"; do
        # Pula entradas vazias
        if [ -z "$component" ]; then
            continue
        fi

        # Se não foi visto antes, adiciona
        if [ -z "${seen[$component]:-}" ]; then
            if [ -z "$cleaned" ]; then
                cleaned="$component"
            else
                cleaned="$cleaned:$component"
            fi
            seen[$component]=1
        fi
    done

    echo "$cleaned"
}

# ==============================================================================
# FUNÇÃO: Instalar Plymouth (Multi-Distro)
# ==============================================================================
install_plymouth() {
    log "STEP" "Configurando tema de boot (Plymouth)..."

    case "$DISTRO_FAMILY" in
        debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
            log "INFO" "Instalando Plymouth para Debian/Ubuntu..."
            $SUDO apt update 2>/dev/null || true
            $SUDO apt install -y plymouth plymouth-themes 2>/dev/null || true

            # Define tema padrão
            if command -v plymouth-set-default-theme &>/dev/null; then
                if [ -d "/usr/share/plymouth/themes/spinner" ]; then
                    $SUDO plymouth-set-default-theme -R spinner 2>/dev/null || true
                    log "SUCCESS" "✓ Tema Plymouth definido: spinner"
                elif [ -d "/usr/share/plymouth/themes/bgrt" ]; then
                    $SUDO plymouth-set-default-theme -R bgrt 2>/dev/null || true
                    log "SUCCESS" "✓ Tema Plymouth definido: bgrt"
                fi
            fi

            # Configura boot options no GRUB
            configure_grub_boot_options
            ;;

        arch|manjaro|endeavouros|biglinux)
            log "INFO" "Instalando Plymouth para Arch Linux..."
            $SUDO pacman -S --noconfirm --needed plymouth 2>/dev/null || true

            # Backup de mkinitcpio.conf
            if [ -f /etc/mkinitcpio.conf ]; then
                log "INFO" "Fazendo backup de mkinitcpio.conf..."
                $SUDO cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak.$(date +%Y%m%d-%H%M%S)"
            fi

            # Adiciona plymouth aos HOOKS
            log "INFO" "Configurando mkinitcpio.conf..."
            if grep -q "^HOOKS=" /etc/mkinitcpio.conf; then
                # Insere 'plymouth' após 'udev'
                $SUDO sed -i -E 's/(HOOKS=\(.*)(udev.*)/\1plymouth \2/' /etc/mkinitcpio.conf
                log "SUCCESS" "✓ Plymouth adicionado aos HOOKS"
            fi

            # Regenera initramfs
            log "INFO" "Regenerando initramfs..."
            $SUDO mkinitcpio -P 2>/dev/null || true

            # Configura boot options
            log "INFO" "Configurando boot options..."
            BOOT_ENTRY=$($SUDO find /boot/loader/entries/ -name "*.conf" 2>/dev/null | head -n1)

            if [ -f "$BOOT_ENTRY" ]; then
                log "INFO" "Encontrado: $BOOT_ENTRY"

                # Backup da entrada de boot
                $SUDO cp "$BOOT_ENTRY" "${BOOT_ENTRY}.bak.$(date +%Y%m%d-%H%M%S)"

                # Extrai opções atuais
                OLD_OPTS=$($SUDO grep -E '^options' "$BOOT_ENTRY" | sed -E 's/^options //' || echo "")

                # Define opções desejadas
                DESIRED_OPTS="quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 zswap.enabled=1"

                # Combina e remove duplicatas
                if [ -n "$OLD_OPTS" ]; then
                    COMBINED=$(echo "$OLD_OPTS $DESIRED_OPTS" | tr -s ' ' | tr ' ' '\n' | sort -u | tr '\n' ' ')
                else
                    COMBINED="$DESIRED_OPTS"
                fi

                # Remove linha de opções antiga
                $SUDO sed -i '/^options/d' "$BOOT_ENTRY"

                # Adiciona novas opções
                echo "options $COMBINED" | $SUDO tee -a "$BOOT_ENTRY" > /dev/null
                log "SUCCESS" "✓ Boot options configuradas"
            else
                log "WARN" "⚠ Entrada de boot não encontrada em /boot/loader/entries/"
            fi

            # Define tema padrão
            if command -v plymouth-set-default-theme &>/dev/null; then
                $SUDO plymouth-set-default-theme bgrt 2>/dev/null || true
                log "SUCCESS" "✓ Tema Plymouth definido: bgrt"

                # Regenera initramfs novamente com novo tema
                $SUDO mkinitcpio -P 2>/dev/null || true
            fi
            ;;

        fedora|redhat|almalinux|nobara)
            log "INFO" "Instalando Plymouth para Fedora..."
            $SUDO dnf install -y plymouth plymouth-theme-spinner 2>/dev/null || true

            # Define tema padrão
            if command -v plymouth-set-default-theme &>/dev/null; then
                $SUDO plymouth-set-default-theme spinner 2>/dev/null || true
                log "SUCCESS" "✓ Tema Plymouth definido: spinner"
            fi

            # Configura boot options no GRUB
            configure_grub2_boot_options

            # Regenera initramfs
            log "INFO" "Regenerando initramfs..."
            $SUDO dracut -f 2>/dev/null || true
            ;;

        *)
            log "WARN" "⚠ Distribuição não suportada para Plymouth: $DISTRO_FAMILY"
            ;;
    esac
}

# ==============================================================================
# FUNÇÃO: Configurar Boot Options GRUB (Debian/Ubuntu)
# ==============================================================================
configure_grub_boot_options() {
    log "INFO" "Configurando boot options (GRUB)..."

    if [ ! -f /etc/default/grub ]; then
        log "WARN" "⚠ /etc/default/grub não encontrado"
        return 1
    fi

    log "INFO" "Encontrado: /etc/default/grub"

    # Backup do arquivo
    $SUDO cp /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)"

    # Define opções desejadas
    DESIRED_OPTS="quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 zswap.enabled=1"

    # Remove opções antigas (quiet, splash, loglevel, etc)
    $SUDO sed -i 's/quiet//g; s/splash//g; s/loglevel=[0-9]//g; s/systemd.show_status=[^ ]*//g; s/rd.udev.log_level=[^ ]*//g; s/zswap.enabled=[^ ]*//g' /etc/default/grub

    # Adiciona novas opções
    $SUDO sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$DESIRED_OPTS /" /etc/default/grub

    # Remove espaços duplicados
    $SUDO sed -i 's/ \+/ /g' /etc/default/grub

    # Regenera GRUB
    if command -v grub-mkconfig &>/dev/null; then
        log "INFO" "Regenerando configuração GRUB..."
        $SUDO grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        log "SUCCESS" "✓ Boot options configuradas"
    fi
}

# ==============================================================================
# FUNÇÃO: Configurar Boot Options GRUB2 (Fedora)
# ==============================================================================
configure_grub2_boot_options() {
    log "INFO" "Configurando boot options (GRUB2)..."

    if [ ! -f /etc/default/grub ]; then
        log "WARN" "⚠ /etc/default/grub não encontrado"
        return 1
    fi

    log "INFO" "Encontrado: /etc/default/grub"

    # Backup do arquivo
    $SUDO cp /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)"

    # Define opções desejadas
    DESIRED_OPTS="quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 zswap.enabled=1"

    # Remove opções antigas
    $SUDO sed -i 's/quiet//g; s/splash//g; s/loglevel=[0-9]//g; s/systemd.show_status=[^ ]*//g; s/rd.udev.log_level=[^ ]*//g; s/zswap.enabled=[^ ]*//g' /etc/default/grub

    # Adiciona novas opções
    $SUDO sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$DESIRED_OPTS /" /etc/default/grub

    # Remove espaços duplicados
    $SUDO sed -i 's/ \+/ /g' /etc/default/grub

    # Regenera GRUB2
    if command -v grub2-mkconfig &>/dev/null; then
        log "INFO" "Regenerando configuração GRUB2..."
        $SUDO grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
        log "SUCCESS" "✓ Boot options configuradas"
    fi
}

# ==============================================================================
# 1. CONFIGURAÇÃO DE PATH
# ==============================================================================
log "INFO" "Configurando PATH global..."

# Detecta PATH duplicado
CURRENT_PATH=$(clean_path "$PATH")
if [ "$CURRENT_PATH" != "$PATH" ]; then
    log "WARN" "PATH contém duplicatas. Limpando..."
    export PATH="$CURRENT_PATH"
fi

# Adiciona PATH do projeto (se ainda não estiver)
if [[ ":$PATH:" != *":$UTILS_DIR:"* ]]; then
    log "INFO" "Adicionando $UTILS_DIR ao PATH..."

    # Remove bloco antigo se existir
    $SUDO sed -i '/# === V3RTECH SCRIPTS: Global PATH BEGIN ===/,/# === V3RTECH SCRIPTS: Global PATH END ===/d' "$SYSTEM_BASHRC"

    # Adiciona novo bloco
    {
        echo "# === V3RTECH SCRIPTS: Global PATH BEGIN ==="
        echo "if [ -d \"$UTILS_DIR\" ]; then"
        echo "    case \":\$PATH:\" in"
        echo "        *:\"$UTILS_DIR\":*) ;;"
        echo "        *) export PATH=\"\$PATH:$UTILS_DIR\" ;;"
        echo "    esac"
        echo "fi"
        echo "# === V3RTECH SCRIPTS: Global PATH END ==="
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null

    log "SUCCESS" "PATH configurado"
fi

# ==============================================================================
# 2. CONFIGURAÇÃO DE ALIASES
# ==============================================================================
log "INFO" "Configurando aliases..."

ALIASES_FILE="$CONFIG_DIR/aliases.geral"

if [ -f "$ALIASES_FILE" ]; then
    # Remove bloco antigo se existir
    $SUDO sed -i '/# === V3RTECH SCRIPTS: Global Aliases BEGIN ===/,/# === V3RTECH SCRIPTS: Global Aliases END ===/d' "$SYSTEM_BASHRC"

    # Adiciona novo bloco
    {
        echo "# === V3RTECH SCRIPTS: Global Aliases BEGIN ==="
        cat "$ALIASES_FILE"
        echo "# === V3RTECH SCRIPTS: Global Aliases END ==="
    } | $SUDO tee -a "$SYSTEM_BASHRC" > /dev/null

    log "SUCCESS" "Aliases configurados"
fi

# ==============================================================================
# 3. PERMISSÕES DE SCRIPTS
# ==============================================================================
log "INFO" "Ajustando permissões de scripts..."

if [ -d "$UTILS_DIR" ]; then
    $SUDO chmod +x "$UTILS_DIR"/* 2>/dev/null || true
    log "SUCCESS" "Permissões ajustadas"
fi

# ==============================================================================
# 4. DESKTOP ENTRIES
# ==============================================================================
log "INFO" "Criando desktop entries para scripts utilitários..."

LOCATION_DEST="/usr/share/applications"
SCRIPT_BASE="$UTILS_DIR"
ICON_BASE="$RESOURCES_DIR/atalhos"

# Cria pasta de destino, se necessário
$SUDO mkdir -p "$LOCATION_DEST"

# Array de entradas: "id|nome|script|ícone"
ENTRADAS=(
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

DESKTOP_ENTRIES_CREATED=0
DESKTOP_ENTRIES_FAILED=0

for entry in "${ENTRADAS[@]}"; do
    IFS="|" read -r file name script_file icon_file <<< "$entry"

    EXEC_CMD="$SCRIPT_BASE/$script_file"
    ICON_PATH="$ICON_BASE/$icon_file"
    DESKTOP_FILE="$LOCATION_DEST/${file}.desktop"

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
    log "DEBUG" "Criando desktop entry: $file"

    $SUDO tee "$DESKTOP_FILE" > /dev/null <<EOF
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

    log "SUCCESS" "✓ Desktop entry criada: $file"
    ((DESKTOP_ENTRIES_CREATED++))
done

log "INFO" "Desktop entries: $DESKTOP_ENTRIES_CREATED criadas, $DESKTOP_ENTRIES_FAILED falhadas"

# ==============================================================================
# 5. RESTAURAÇÃO DE CONFIGURAÇÕES
# ==============================================================================
log "INFO" "Restaurando configurações de usuário..."

CONFIG_SRC_DIR="$CONFIG_DIR/user-configs"
CUSTOM_BASHRC="$CONFIG_DIR/.bashrc"

if [ -f "$CUSTOM_BASHRC" ]; then
    if [ -f "$REAL_HOME/.bashrc" ]; then
        log "INFO" "Fazendo backup de .bashrc..."
        cp "$REAL_HOME/.bashrc" "$REAL_HOME/.bashrc.bak"
        cat "$CUSTOM_BASHRC" >> "$REAL_HOME/.bashrc"
    fi
fi

# Restaura Zips
if [ -d "$CONFIG_SRC_DIR" ]; then
    for zipfile in "$CONFIG_SRC_DIR"/*.zip; do
        [ -e "$zipfile" ] || continue
        filename=$(basename "$zipfile")
        log "INFO" "Restaurando configurações: $filename..."
        unzip -o -q "$zipfile" -d "$REAL_HOME/"
    done
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME"
fi

# ==============================================================================
# 6. INSTALAÇÃO DE SCRIPTS UTILITÁRIOS (LINKS)
# ==============================================================================
log "INFO" "Criando links simbólicos..."

# Cria links em /usr/local/bin (Garantia extra caso o PATH falhe)
if [ -d "$UTILS_DIR" ]; then
    LINKS_CREATED=0
    for script in "$UTILS_DIR"/*; do
        [ -e "$script" ] || continue
        script_name=$(basename "$script")

        # Pula arquivos que não são executáveis
        [ -x "$script" ] || continue

        $SUDO ln -sf "$script" "/usr/local/bin/$script_name"
        ((LINKS_CREATED++))
    done

    log "SUCCESS" "✓ $LINKS_CREATED links simbólicos criados"
fi

# Fontes
if [ -d "$RESOURCES_DIR/fonts" ]; then
    log "INFO" "Instalando fontes..."
    $SUDO mkdir -p /usr/share/fonts/v3rtech
    $SUDO cp -r "$RESOURCES_DIR/fonts/"* /usr/share/fonts/v3rtech/ 2>/dev/null || true

    if command -v fc-cache &>/dev/null; then
        $SUDO fc-cache -f
        log "SUCCESS" "Fontes instaladas"
    fi
fi

# ==============================================================================
# 7. CONFIGURAÇÃO VISUAL DE BOOT (PLYMOUTH)
# ==============================================================================
install_plymouth

# ==============================================================================
# RESUMO FINAL
# ==============================================================================

log "SUCCESS" "✓ Configurações aplicadas com sucesso."
log "INFO" "Reinicie o terminal para aplicar mudanças de PATH e aliases."
