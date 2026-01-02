#!/bin/bash

# Script Universal para Instalação do Driver NVIDIA Proprietário com Wayland
# Compatível com: Arch Linux, Debian, Ubuntu, Fedora, openSUSE, CentOS e derivadas
# Autor: Manus AI
# Data: 01/01/2026
# Descrição: Detecta automaticamente a distribuição e instala/configura o driver NVIDIA
#            proprietário com suporte completo a Wayland

# --- Configurações Globais ---

set -e
set -u

# Cores para output
VERDE='\033[0;32m'
AMARELO='\033[0;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m'

# Variáveis globais
DISTRO=""
DISTRO_FAMILY=""
DRIVER_PACKAGE=""
INIT_SYSTEM=""
BOOTLOADER=""

# --- Funções Auxiliares ---

log() {
    echo -e "${VERDE}[INFO]${NC} $1"
}

warn() {
    echo -e "${AMARELO}[AVISO]${NC} $1"
}

error() {
    echo -e "${VERMELHO}[ERRO]${NC} $1" >&2
    exit 1
}

info() {
    echo -e "${AZUL}[SISTEMA]${NC} $1"
}

# Função para executar comandos com privilégios
run_as_root() {
    local cmd="$1"
    
    if [ "$(id -u)" -eq 0 ]; then
        # Já é root
        eval "$cmd"
    else
        # Solicita senha uma vez
        if ! sudo -n true 2>/dev/null; then
            echo -e "${AMARELO}Este script requer privilégios de administrador.${NC}"
            echo "Por favor, insira sua senha:"
        fi
        sudo bash -c "$cmd"
    fi
}

# Função para detectar a distribuição
detect_distro() {
    log "Detectando a distribuição Linux..."
    
    # Inicializa variáveis
    DISTRO=""
    DISTRO_FAMILY=""
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID:-}"
        DISTRO_FAMILY="${ID_LIKE:-}"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$(echo "${DISTRIB_ID:-}" | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/redhat-release ]; then
        DISTRO=$(cat /etc/redhat-release | awk '{print tolower($1)}')
    else
        error "Não foi possível detectar a distribuição Linux."
    fi
    
    if [ -z "$DISTRO" ]; then
        error "Não foi possível determinar o ID da distribuição."
    fi
    
    info "Distribuição detectada: $DISTRO"
    
    # Determina a família da distribuição baseado no ID
    case "$DISTRO" in
        arch|manjaro|endeavouros)
            DISTRO_FAMILY="arch"
            ;;
        debian|ubuntu|linuxmint|pop|elementary|zorin)
            DISTRO_FAMILY="debian"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            DISTRO_FAMILY="fedora"
            ;;
        opensuse*)
            DISTRO_FAMILY="opensuse"
            ;;
        *)
            # Se não foi detectada a família, tenta usar ID_LIKE
            if [ -n "$DISTRO_FAMILY" ]; then
                warn "Distribuição '$DISTRO' pode não ser totalmente suportada. Tentando usar a família: $DISTRO_FAMILY"
            else
                error "Não foi possível determinar a família da distribuição para: $DISTRO"
            fi
            ;;
    esac
    
    info "Família de distribuição: $DISTRO_FAMILY"
}

# Função para detectar o bootloader
detect_bootloader() {
    log "Detectando o bootloader..."
    
    if [ -d /boot/grub ]; then
        BOOTLOADER="grub"
        info "Bootloader detectado: GRUB"
    elif [ -d /boot/efi/EFI ] && [ -f /boot/loader/loader.conf ]; then
        BOOTLOADER="systemd-boot"
        info "Bootloader detectado: systemd-boot"
    elif [ -f /boot/grub2/grub.cfg ]; then
        BOOTLOADER="grub2"
        info "Bootloader detectado: GRUB2"
    else
        warn "Bootloader não detectado automaticamente. Configuração manual pode ser necessária."
        BOOTLOADER="unknown"
    fi
}

# Função para detectar a GPU
detect_gpu() {
    log "Detectando a GPU NVIDIA..."
    
    if ! command -v lspci &> /dev/null; then
        error "O comando 'lspci' não foi encontrado. Instale o pacote 'pciutils' ou 'pci-utils'."
    fi

    GPU_INFO=$(lspci -k -d ::0300 2>/dev/null || true)
    
    if [ -z "$GPU_INFO" ]; then
        error "Nenhuma GPU NVIDIA foi detectada. Verifique sua configuração de hardware."
    fi

    # Extrai o nome da GPU - tenta múltiplos formatos
    GPU_NAME=$(echo "$GPU_INFO" | grep -oP 'NVIDIA Corporation \[\K[^\]]+' || true)
    
    if [ -z "$GPU_NAME" ]; then
        GPU_NAME=$(echo "$GPU_INFO" | grep -oP 'NVIDIA Corporation \K[^\n]+' | head -1 || true)
    fi
    
    if [ -z "$GPU_NAME" ]; then
        GPU_NAME=$(echo "$GPU_INFO" | sed -n 's/.*NVIDIA Corporation //p' | head -1 || true)
    fi
    
    if [ -z "$GPU_NAME" ]; then
        error "Não foi possível extrair o nome da GPU. Saída de lspci: $GPU_INFO"
    fi

    log "GPU Detectada: $GPU_NAME"

    # Seleciona o driver apropriado
    if echo "$GPU_NAME" | grep -qiE "GA[0-9]{3}|AD[0-9]{3}|RTX [34][0-9]{3}|RTX [45][0-9]{3}|Turing|Ada|Ampere|GeForce RTX [34][0-9]{3}|GeForce RTX [45][0-9]{3}"; then
        log "GPU Turing/Ada/Ampere detectada."
        DRIVER_PACKAGE="nvidia-driver"
    elif echo "$GPU_NAME" | grep -qiE "GM[0-9]{3}|GP[0-9]{3}|Maxwell|Pascal|GeForce GTX [9][0-9]{2}|GeForce GTX [0-9]{4}|GeForce RTX [0-9]{4}"; then
        log "GPU Maxwell/Pascal detectada."
        DRIVER_PACKAGE="nvidia-driver"
    elif echo "$GPU_NAME" | grep -qiE "GK[0-9]{3}|Kepler|GeForce GTX [67][0-9]{2}|GeForce GTX Titan"; then
        log "GPU Kepler detectada."
        DRIVER_PACKAGE="nvidia-driver-470"
    elif echo "$GPU_NAME" | grep -qiE "GF[0-9]{3}|Fermi|GeForce GTX [45][0-9]{2}|GeForce GTS"; then
        log "GPU Fermi detectada."
        DRIVER_PACKAGE="nvidia-driver-390"
    else
        error "Não foi possível determinar um driver compatível para a sua GPU: $GPU_NAME"
    fi
}

# --- Funções Específicas por Distribuição ---

# Arch Linux
install_arch() {
    log "Instalando driver NVIDIA para Arch Linux..."
    
    # Atualizar sistema
    log "Atualizando o sistema..."
    run_as_root "pacman -Syu --noconfirm"
    
    # Instalar dependências
    log "Instalando dependências..."
    run_as_root "pacman -S base-devel linux-headers git pciutils --noconfirm --needed"
    
    # Habilitar multilib
    log "Habilitando repositório multilib..."
    run_as_root "sed -i '/^\[multilib\]/,/Include/s/^#//' /etc/pacman.conf"
    run_as_root "pacman -Syu --noconfirm"
    
    # Instalar driver NVIDIA
    log "Instalando driver NVIDIA (nvidia-dkms)..."
    run_as_root "pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils --noconfirm --needed"
    
    # Configurar mkinitcpio
    configure_mkinitcpio_arch
    
    # Configurar bootloader
    configure_bootloader_arch
    
    # Variáveis de ambiente
    set_environment_variables
    
    # Hook do Pacman
    create_pacman_hook_arch
}

configure_mkinitcpio_arch() {
    log "Configurando mkinitcpio..."
    local MKINITCPIO_CONF="/etc/mkinitcpio.conf"
    
    run_as_root "cp $MKINITCPIO_CONF $MKINITCPIO_CONF.bak"
    log "Backup criado: $MKINITCPIO_CONF.bak"
    
    if ! run_as_root "grep -q 'nvidia' $MKINITCPIO_CONF"; then
        run_as_root "sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' $MKINITCPIO_CONF"
        log "Módulos NVIDIA adicionados."
    fi
    
    if run_as_root "grep -q 'kms' $MKINITCPIO_CONF"; then
        run_as_root "sed -i 's/\(HOOKS=([^)]*\)kms\([^)]*)\)/\1\2/' $MKINITCPIO_CONF"
        log "Hook 'kms' removido."
    fi
    
    log "Regenerando initramfs..."
    run_as_root "mkinitcpio -P"
}

configure_bootloader_arch() {
    log "Configurando bootloader..."
    local KERNEL_PARAMS="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
    
    if [ "$BOOTLOADER" = "grub" ]; then
        local GRUB_CONF="/etc/default/grub"
        if ! run_as_root "grep -q '$KERNEL_PARAMS' $GRUB_CONF"; then
            run_as_root "sed -i \"s/GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\(.*\\)\\\"/GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\1 $KERNEL_PARAMS\\\"/\" $GRUB_CONF"
            run_as_root "grub-mkconfig -o /boot/grub/grub.cfg"
            log "Configuração GRUB atualizada."
        fi
    elif [ "$BOOTLOADER" = "systemd-boot" ]; then
        configure_systemd_boot "$KERNEL_PARAMS"
    fi
}

create_pacman_hook_arch() {
    log "Criando hook do Pacman..."
    local HOOK_DIR="/etc/pacman.d/hooks"
    local HOOK_FILE="$HOOK_DIR/nvidia.hook"
    
    run_as_root "mkdir -p $HOOK_DIR"
    
    run_as_root "cat > $HOOK_FILE <<'EOF'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF"
    
    log "Hook do Pacman criado."
}

# Debian/Ubuntu
install_debian() {
    log "Instalando driver NVIDIA para Debian/Ubuntu..."
    
    # Atualizar sistema
    log "Atualizando o sistema..."
    run_as_root "apt-get update && apt-get upgrade -y"
    
    # Instalar dependências
    log "Instalando dependências..."
    run_as_root "apt-get install -y build-essential linux-headers-\$(uname -r) git pciutils"
    
    # Habilitar repositório non-free (se necessário)
    if grep -q "non-free" /etc/apt/sources.list 2>/dev/null || grep -q "non-free" /etc/apt/sources.list.d/* 2>/dev/null; then
        log "Repositório non-free já está habilitado."
    else
        log "Habilitando repositório non-free..."
        run_as_root "sed -i 's/main/main non-free/' /etc/apt/sources.list"
        run_as_root "apt-get update"
    fi
    
    # Instalar driver NVIDIA
    log "Instalando driver NVIDIA..."
    run_as_root "apt-get install -y nvidia-driver"
    
    # Configurar DKMS
    log "Configurando DKMS..."
    run_as_root "apt-get install -y nvidia-dkms"
    
    # Instalar suporte a 32-bit
    log "Instalando suporte a 32-bit..."
    run_as_root "apt-get install -y lib32-nvidia-utils 2>/dev/null || true"
    
    # Configurar bootloader
    configure_bootloader_debian
    
    # Variáveis de ambiente
    set_environment_variables
}

configure_bootloader_debian() {
    log "Configurando bootloader..."
    local KERNEL_PARAMS="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
    
    if [ "$BOOTLOADER" = "grub" ] || [ "$BOOTLOADER" = "grub2" ]; then
        local GRUB_CONF="/etc/default/grub"
        if ! run_as_root "grep -q '$KERNEL_PARAMS' $GRUB_CONF"; then
            run_as_root "sed -i \"s/GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\(.*\\)\\\"/GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\1 $KERNEL_PARAMS\\\"/\" $GRUB_CONF"
            run_as_root "update-grub"
            log "Configuração GRUB atualizada."
        fi
    elif [ "$BOOTLOADER" = "systemd-boot" ]; then
        configure_systemd_boot "$KERNEL_PARAMS"
    fi
}

# Fedora/RHEL/CentOS
install_fedora() {
    log "Instalando driver NVIDIA para Fedora/RHEL/CentOS..."
    
    # Atualizar sistema
    log "Atualizando o sistema..."
    run_as_root "dnf upgrade -y"
    
    # Instalar dependências
    log "Instalando dependências..."
    run_as_root "dnf install -y gcc kernel-devel kernel-headers git pciutils"
    
    # Habilitar repositório RPM Fusion
    log "Habilitando repositório RPM Fusion..."
    run_as_root "dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm || true"
    
    # Instalar driver NVIDIA
    log "Instalando driver NVIDIA..."
    run_as_root "dnf install -y akmod-nvidia xorg-x11-drv-nvidia-libs.i686"
    
    # Aguardar compilação do akmod
    log "Aguardando compilação do módulo NVIDIA (pode levar alguns minutos)..."
    run_as_root "akmods --force"
    
    # Configurar bootloader
    configure_bootloader_fedora
    
    # Variáveis de ambiente
    set_environment_variables
}

configure_bootloader_fedora() {
    log "Configurando bootloader..."
    local KERNEL_PARAMS="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
    
    if [ "$BOOTLOADER" = "grub2" ]; then
        local GRUB_CONF="/etc/default/grub"
        if ! run_as_root "grep -q '$KERNEL_PARAMS' $GRUB_CONF"; then
            run_as_root "sed -i \"s/GRUB_CMDLINE_LINUX=\\\"\\(.*\\)\\\"/GRUB_CMDLINE_LINUX=\\\"\\1 $KERNEL_PARAMS\\\"/\" $GRUB_CONF"
            run_as_root "grub2-mkconfig -o /etc/grub2.cfg"
            log "Configuração GRUB2 atualizada."
        fi
    fi
}

# openSUSE
install_opensuse() {
    log "Instalando driver NVIDIA para openSUSE..."
    
    # Atualizar sistema
    log "Atualizando o sistema..."
    run_as_root "zypper refresh && zypper update -y"
    
    # Instalar dependências
    log "Instalando dependências..."
    run_as_root "zypper install -y gcc kernel-devel kernel-default-devel git pciutils"
    
    # Adicionar repositório NVIDIA
    log "Adicionando repositório NVIDIA..."
    run_as_root "zypper addrepo https://download.nvidia.com/opensuse/leap/\$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '\"') NVIDIA"
    run_as_root "zypper refresh"
    
    # Instalar driver NVIDIA
    log "Instalando driver NVIDIA..."
    run_as_root "zypper install -y nvidia-driver nvidia-driver-32bit"
    
    # Configurar bootloader
    configure_bootloader_opensuse
    
    # Variáveis de ambiente
    set_environment_variables
}

configure_bootloader_opensuse() {
    log "Configurando bootloader..."
    local KERNEL_PARAMS="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
    
    if [ "$BOOTLOADER" = "grub2" ]; then
        local GRUB_CONF="/etc/default/grub"
        if ! run_as_root "grep -q '$KERNEL_PARAMS' $GRUB_CONF"; then
            run_as_root "sed -i \"s/GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\(.*\\)\\\"/GRUB_CMDLINE_LINUX_DEFAULT=\\\"\\1 $KERNEL_PARAMS\\\"/\" $GRUB_CONF"
            run_as_root "grub2-mkconfig -o /boot/grub2/grub.cfg"
            log "Configuração GRUB2 atualizada."
        fi
    fi
}

# --- Funções Comuns ---

configure_systemd_boot() {
    local KERNEL_PARAMS="$1"
    local ENTRIES_DIR="/boot/loader/entries"
    
    if [ ! -d "$ENTRIES_DIR" ]; then
        warn "Diretório $ENTRIES_DIR não encontrado."
        return
    fi
    
    for entry in "$ENTRIES_DIR"/*.conf; do
        if [ -f "$entry" ]; then
            if ! run_as_root "grep -q '$KERNEL_PARAMS' $entry"; then
                run_as_root "sed -i \"/^options/ s/\$/ $KERNEL_PARAMS/\" $entry"
                log "Entrada $entry atualizada."
            fi
        fi
    done
}

set_environment_variables() {
    log "Configurando variáveis de ambiente para Wayland..."
    local ENV_FILE="/etc/environment"
    
    run_as_root "touch $ENV_FILE"
    
    if ! run_as_root "grep -q 'GBM_BACKEND=nvidia-drm' $ENV_FILE"; then
        run_as_root "echo 'GBM_BACKEND=nvidia-drm' >> $ENV_FILE"
        log "Variável GBM_BACKEND adicionada."
    fi
    
    if ! run_as_root "grep -q '__GLX_VENDOR_LIBRARY_NAME=nvidia' $ENV_FILE"; then
        run_as_root "echo '__GLX_VENDOR_LIBRARY_NAME=nvidia' >> $ENV_FILE"
        log "Variável __GLX_VENDOR_LIBRARY_NAME adicionada."
    fi
}

verify_installation() {
    log "Verificando a instalação..."
    
    if command -v nvidia-smi &> /dev/null; then
        log "Driver NVIDIA instalado com sucesso!"
        nvidia-smi --query-gpu=index,name,driver_version --format=csv,noheader
    else
        warn "nvidia-smi não foi encontrado. Verifique a instalação."
    fi
}

# --- Função Principal ---

main() {
    echo ""
    log "=========================================="
    log "Instalação Universal do Driver NVIDIA"
    log "com Suporte a Wayland"
    log "=========================================="
    echo ""
    
    # Detectar distribuição
    detect_distro
    detect_bootloader
    detect_gpu
    
    echo ""
    info "Resumo da instalação:"
    info "  Distribuição: $DISTRO ($DISTRO_FAMILY)"
    info "  Bootloader: $BOOTLOADER"
    info "  GPU: $GPU_NAME"
    info "  Driver: $DRIVER_PACKAGE"
    echo ""
    
    # Instalar driver baseado na distribuição
    case "$DISTRO_FAMILY" in
        arch)
            install_arch
            ;;
        debian)
            install_debian
            ;;
        fedora)
            install_fedora
            ;;
        opensuse)
            install_opensuse
            ;;
        *)
            error "Distribuição '$DISTRO_FAMILY' não é suportada por este script."
            ;;
    esac
    
    # Verificar instalação
    verify_installation
    
    echo ""
    log "=========================================="
    log "Instalação concluída com sucesso!"
    log "=========================================="
    warn "É NECESSÁRIO reiniciar o sistema."
    warn "Após reiniciar, selecione a sessão Wayland na tela de login."
    echo ""
    log "Para verificar se o DRM está habilitado após o reboot:"
    log "  cat /sys/module/nvidia_drm/parameters/modeset"
    log "  (deve retornar 'Y')"
    echo ""
}

# --- Execução ---

main "$@"
