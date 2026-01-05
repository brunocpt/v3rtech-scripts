#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/00-detecta-distro.sh
# Versão: 1.1.0
#
# Descrição: Módulo de inteligência e detecção.
# Identifica a distribuição (base e derivada), o ambiente de desktop (DE),
# o servidor gráfico (X11/Wayland) e o hardware de vídeo principal.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando detecção de ambiente..."

# ------------------------------------------------------------------------------
# 1. Identificação da Distribuição e Família
# ------------------------------------------------------------------------------

if [ -f /etc/os-release ]; then
    # Carrega variáveis padrão do sistema (ID, ID_LIKE, VERSION, etc.)
    source /etc/os-release
else
    die "Arquivo /etc/os-release não encontrado. Sistema incompatível."
fi

# Normaliza ID para minúsculas
DISTRO_ID="${ID,,}"
DISTRO_LIKE="${ID_LIKE,,}"

# Lógica de Família (Define o Gerenciador de Pacotes)
# Prioridade: Verificar se é Arch, Debian ou Fedora (ou baseados neles)

if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" =~ "arch" ]]; then
    DISTRO_FAMILY="arch"
    PKG_MANAGER="pacman"
    log "INFO" "Sistema detectado: Base Arch Linux ($PRETTY_NAME)"

elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" =~ "fedora" ]]; then
    DISTRO_FAMILY="fedora"
    PKG_MANAGER="dnf"
    log "INFO" "Sistema detectado: Base Fedora ($PRETTY_NAME)"

elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_LIKE" =~ "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" =~ "ubuntu" ]]; then
    DISTRO_FAMILY="debian"
    PKG_MANAGER="apt"
    log "INFO" "Sistema detectado: Base Debian/Ubuntu ($PRETTY_NAME)"

else
    DISTRO_FAMILY="unknown"
    PKG_MANAGER="unknown"
    log "WARN" "Distribuição não suportada nativamente: $PRETTY_NAME"
    log "WARN" "A instalação automática de pacotes pode falhar."
fi

# Salva o nome específico da distro para logs (ex: 'pop', 'manjaro', 'kali')
DISTRO_NAME="$DISTRO_ID"

# ------------------------------------------------------------------------------
# 2. Identificação do Ambiente Desktop (DE)
# ------------------------------------------------------------------------------

# Tenta capturar via XDG_CURRENT_DESKTOP
RAW_DE="${XDG_CURRENT_DESKTOP,,}" # converte para minúsculo

if [[ "$RAW_DE" =~ "gnome" ]]; then
    DESKTOP_ENV="gnome"
elif [[ "$RAW_DE" =~ "kde" || "$RAW_DE" =~ "plasma" ]]; then
    DESKTOP_ENV="kde"
elif [[ "$RAW_DE" =~ "xfce" ]]; then
    DESKTOP_ENV="xfce"
elif [[ "$RAW_DE" =~ "cinnamon" ]]; then
    DESKTOP_ENV="cinnamon"
elif [[ "$RAW_DE" =~ "mate" ]]; then
    DESKTOP_ENV="mate"
elif [[ "$RAW_DE" =~ "budgie" ]]; then
    DESKTOP_ENV="budgie"
elif [[ "$RAW_DE" =~ "deepin" ]]; then
    DESKTOP_ENV="deepin"
elif [[ "$RAW_DE" =~ "cosmic" ]]; then
    DESKTOP_ENV="cosmic"
elif [[ "$RAW_DE" =~ "lxqt" ]]; then
    DESKTOP_ENV="lxqt"
elif [[ "$RAW_DE" =~ "sway" || "$RAW_DE" =~ "hyprland" ]]; then
    DESKTOP_ENV="tiling-wm" # Gerenciadores de janela tiling
else
    DESKTOP_ENV="generic"
    log "WARN" "Ambiente Desktop não identificado claramente (Raw: $XDG_CURRENT_DESKTOP). Assumindo 'generic'."
fi

log "INFO" "Ambiente Gráfico: $DESKTOP_ENV"

# ------------------------------------------------------------------------------
# 3. Identificação do Servidor Gráfico (Session)
# ------------------------------------------------------------------------------

SESSION_TYPE="${XDG_SESSION_TYPE,,}"

if [ -z "$SESSION_TYPE" ]; then
    SESSION_TYPE="unknown"
fi

log "INFO" "Tipo de Sessão: $SESSION_TYPE"

# ------------------------------------------------------------------------------
# 4. Detecção de Hardware Crítico (GPU)
# ------------------------------------------------------------------------------
# Usa lspci para encontrar o controlador VGA/3D

if command -v lspci &> /dev/null; then
    GPU_RAW=$(lspci | grep -E -i "vga|3d|display")

    if [[ "$GPU_RAW" =~ "NVIDIA" || "$GPU_RAW" =~ "Nvidia" ]]; then
        GPU_VENDOR="nvidia"
        log "INFO" "GPU: NVIDIA detectada (Drivers proprietários podem ser necessários)."
    elif [[ "$GPU_RAW" =~ "AMD" || "$GPU_RAW" =~ "Advanced Micro Devices" ]]; then
        GPU_VENDOR="amd"
        log "INFO" "GPU: AMD detectada (Drivers open-source recomendados)."
    elif [[ "$GPU_RAW" =~ "Intel" ]]; then
        GPU_VENDOR="intel"
        log "INFO" "GPU: Intel detectada."
    else
        GPU_VENDOR="generic"
        log "INFO" "GPU: Genérica ou Virtualizada."
    fi
else
    GPU_VENDOR="unknown"
    log "WARN" "Comando 'lspci' não encontrado. Pulei detecção de GPU."
fi

# ------------------------------------------------------------------------------
# 5. Exportação de Variáveis
# ------------------------------------------------------------------------------
# Exporta para garantir que scripts filhos (child processes) tenham acesso

export DISTRO_FAMILY DISTRO_NAME PKG_MANAGER
export DESKTOP_ENV SESSION_TYPE
export GPU_VENDOR

log "SUCCESS" "Detecção concluída: $DISTRO_FAMILY ($PKG_MANAGER) | DE: $DESKTOP_ENV"
