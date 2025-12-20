#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-setup-boot.sh
# Versão: 2.0.0
#
# Descrição: Otimização avançada de Bootloader e Kernel.
# Suporta GRUB e Systemd-boot.
# Detecta GPU para aplicar flags específicas (Nvidia/AMD/Intel).
# Baseado na lógica do script 'ajusta-boot.sh'.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando otimização de Bootloader e Kernel..."

# Variáveis internas para construção da linha de comando
CMDLINE_ADD=""
NVIDIA_APPLIED=0

# ==============================================================================
# 1. FUNÇÕES AUXILIARES
# ==============================================================================

# Adiciona flag à lista se ainda não estiver presente (Lógica simples)
add_flag() {
    CMDLINE_ADD="$CMDLINE_ADD $1"
}

# Regenera Initramfs (Detecta ferramenta disponível)
regen_initramfs() {
    log "INFO" "Regenerando imagem de boot (Initramfs)..."

    if command -v update-initramfs >/dev/null 2>&1; then
        # Debian/Ubuntu
        $SUDO update-initramfs -u -k all
    elif command -v dracut >/dev/null 2>&1; then
        # Fedora/RHEL
        $SUDO dracut -f
    elif command -v mkinitcpio >/dev/null 2>&1; then
        # Arch
        $SUDO mkinitcpio -P
    else
        log "WARN" "Nenhuma ferramenta de initramfs detectada (update-initramfs, dracut, mkinitcpio)."
    fi
}

# Regenera Configuração do GRUB
update_grub_config() {
    log "INFO" "Atualizando arquivo de configuração do GRUB..."

    if command -v update-grub >/dev/null 2>&1; then
        $SUDO update-grub
    elif command -v grub-mkconfig >/dev/null 2>&1; then
        $SUDO grub-mkconfig -o /boot/grub/grub.cfg
    elif command -v grub2-mkconfig >/dev/null 2>&1; then
        # Fedora/RHEL (lógica UEFI vs BIOS)
        if [ -d /sys/firmware/efi ]; then
            # Tenta achar o caminho correto no Fedora UEFI
            local grub_cfg=$(find /boot/efi -name grub.cfg | head -n 1)
            [ -z "$grub_cfg" ] && grub_cfg="/boot/grub2/grub.cfg"
            $SUDO grub2-mkconfig -o "$grub_cfg"
        else
            $SUDO grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
    else
        log "ERROR" "Ferramenta de atualização do GRUB não encontrada."
    fi
}

# ==============================================================================
# 2. DEFINIÇÃO DE FLAGS (Hardware e Preferências)
# ==============================================================================
log "INFO" "Detectando hardware e definindo parâmetros de kernel..."

# Flags Padrão (Limpeza e Performance)
add_flag "quiet"
add_flag "loglevel=0"
add_flag "rd.udev.log_level=0"
add_flag "systemd.show_status=false"
add_flag "noresume"
add_flag "ipv6.disable=1"
add_flag "nvme_core.default_ps_max_latency_us=5500" # Otimização NVMe

# Detecção de GPU (Lógica portada de ajusta-boot.sh)
GPU_INFO=$(lspci -nnk | grep -iE 'vga|3d|display' | tr '[:upper:]' '[:lower:]' || true)

if [[ "$GPU_INFO" =~ "intel" ]]; then
    log "INFO" "GPU Intel detectada. Aplicando otimizações i915..."
    add_flag "i915.fastboot=1"
    add_flag "i915.enable_psr=2"
    add_flag "i915.enable_fbc=1"
fi

if [[ "$GPU_INFO" =~ "amd" ]] || [[ "$GPU_INFO" =~ "advanced micro devices" ]]; then
    log "INFO" "GPU AMD detectada. Ativando Display Core..."
    add_flag "amdgpu.dc=1"
fi

if [[ "$GPU_INFO" =~ "nvidia" ]]; then
    log "INFO" "GPU NVIDIA detectada. Preparando flags DRM..."
    add_flag "nvidia-drm.modeset=1"
    NVIDIA_APPLIED=1

    # Cria arquivo de modprobe persistente para NVIDIA
    MODPROBE_FILE="/etc/modprobe.d/nvidia-kms.conf"
    if [ ! -f "$MODPROBE_FILE" ] || ! grep -q "modeset=1" "$MODPROBE_FILE"; then
        log "INFO" "Criando $MODPROBE_FILE..."
        echo "options nvidia-drm modeset=1" | $SUDO tee "$MODPROBE_FILE" > /dev/null
    fi
fi

log "INFO" "Flags a aplicar: $CMDLINE_ADD"

# ==============================================================================
# 3. APLICAÇÃO NO BOOTLOADER
# ==============================================================================

# --- RAMO SYSTEMD-BOOT ---
if command -v bootctl >/dev/null && bootctl is-installed >/dev/null 2>&1; then
    log "INFO" "Bootloader detectado: systemd-boot"

    # Se existe /etc/kernel/cmdline (padrão Pop!_OS/Systemd-boot nativo)
    if [ -f /etc/kernel/cmdline ]; then
        log "INFO" "Atualizando /etc/kernel/cmdline..."

        # Backup
        $SUDO cp /etc/kernel/cmdline "/etc/kernel/cmdline.bak.$(date +%F-%H%M)"

        # Lê atual
        CURRENT_CMD=$(cat /etc/kernel/cmdline)

        # Remove flags conflitantes antigas (simples replace) para evitar duplicação
        # Nota: Lógica simplificada. Para robustez total, usaríamos loops, mas sed resolve o grosso.
        CLEAN_CMD=$(echo "$CURRENT_CMD" | sed -E 's/(quiet|loglevel=[0-9]+|nvidia-drm.modeset=[0-1])//g')

        # Escreve nova linha
        echo "$CLEAN_CMD $CMDLINE_ADD" | tr -s ' ' | $SUDO tee /etc/kernel/cmdline > /dev/null

        # Atualiza loaders
        $SUDO bootctl update
        if command -v kernel-install >/dev/null; then
             $SUDO kernel-install upgrade "$(uname -r)" 2>/dev/null || true
        fi

    else
        log "WARN" "systemd-boot detectado mas /etc/kernel/cmdline não encontrado. Pulando edição direta."
    fi

    regen_initramfs

# --- RAMO GRUB ---
elif [ -f /etc/default/grub ]; then
    log "INFO" "Bootloader detectado: GRUB"
    GRUB_FILE="/etc/default/grub"

    # Backup
    $SUDO cp "$GRUB_FILE" "${GRUB_FILE}.bak.$(date +%F-%H%M)"

    # Usa arquivo temporário para manipulação segura
    TMP_GRUB=$(mktemp)
    cp "$GRUB_FILE" "$TMP_GRUB"

    # Função sed helper para o arquivo temporário
    set_grub_key() {
        local key="$1"
        local val="$2"
        # Se existe, substitui. Se não, adiciona.
        if grep -q "^${key}=" "$TMP_GRUB"; then
            sed -i "s|^${key}=.*|${key}=${val}|" "$TMP_GRUB"
        elif grep -q "^#${key}=" "$TMP_GRUB"; then
            sed -i "s|^#${key}=.*|${key}=${val}|" "$TMP_GRUB"
        else
            echo "${key}=${val}" >> "$TMP_GRUB"
        fi
    }

    log "INFO" "Aplicando preferências do GRUB (Timeout 0, Hidden)..."
    set_grub_key "GRUB_TIMEOUT_STYLE" "menu"
    set_grub_key "GRUB_TIMEOUT" "0"
    set_grub_key "GRUB_RECORDFAIL_TIMEOUT" "0"
    set_grub_key "GRUB_DISABLE_OS_PROBER" "true"
    set_grub_key "GRUB_DISABLE_SUBMENU" "y"

    # Tratamento da CMDLINE_LINUX_DEFAULT
    # 1. Lê a linha atual
    CURRENT_LINE=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$TMP_GRUB" | cut -d'"' -f2)

    # 2. Concatena com as novas flags (evitando duplicar logica complexa de regex aqui,
    # assumimos que o usuário quer adicionar/sobrescrever no final)
    NEW_LINE="$CURRENT_LINE $CMDLINE_ADD"

    # 3. Limpa espaços duplicados
    NEW_LINE=$(echo "$NEW_LINE" | tr -s ' ')

    # 4. Aplica no arquivo
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_LINE\"|" "$TMP_GRUB"

    # Instala o novo arquivo
    $SUDO cp "$TMP_GRUB" "$GRUB_FILE"
    rm "$TMP_GRUB"

    # Regenera configurações
    regen_initramfs
    update_grub_config

else
    log "WARN" "Nenhum bootloader suportado (GRUB/Systemd-boot config) encontrado."
fi

log "SUCCESS" "Otimização de boot concluída."
