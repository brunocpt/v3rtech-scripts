#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/01-prepara-distro.sh
# Versão: 1.0.0
#
# Descrição: Prepara o terreno da distribuição.
# 1. Atualiza o sistema base.
# 2. Instala dependências de compilação/básicas (git, curl, base-devel).
# 3. Instala gerenciadores auxiliares (paru, apt-fast).
# 4. Instala a interface gráfica do instalador (YAD).
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando preparação do sistema base..."

# ------------------------------------------------------------------------------
# 1. Atualização Inicial e Dependências Críticas
# ------------------------------------------------------------------------------
log "INFO" "Atualizando cache de repositórios e instalando ferramentas base..."

# Garante ferramentas básicas antes de qualquer coisa
# Usamos o gerenciador nativo diretamente aqui para evitar loops,
# pois os aceleradores (paru/apt-fast) ainda não existem.

case "$DISTRO_FAMILY" in
    debian)
        $SUDO apt-get update
        $SUDO apt-get install -y git curl wget software-properties-common build-essential
        ;;
    arch)
        # Sincroniza e garante base-devel (necessário para compilar paru)
        $SUDO pacman -Sy --noconfirm --needed git curl wget base-devel

        # Habilita repositório Multilib (Essencial para Steam/Wine/Gaming)
        if grep -q "#\[multilib\]" /etc/pacman.conf; then
            log "INFO" "Habilitando repositório Multilib (Arch)..."
            $SUDO sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
            $SUDO pacman -Sy
        fi
        ;;
    fedora)
        $SUDO dnf install -y git curl wget @development-tools
        ;;
esac

# ------------------------------------------------------------------------------
# 2. Instalação de Aceleradores (Paru / Apt-Fast)
# ------------------------------------------------------------------------------

# --- Lógica para ARCH LINUX (Paru) ---
if [[ "$DISTRO_FAMILY" == "arch" ]]; then
    if ! command -v paru &> /dev/null; then
        log "INFO" "Instalando PARU (AUR Helper)..."

        # Cria diretório temporário
        mkdir -p /tmp/paru_install
        cd /tmp/paru_install

        # Clona a versão bin (mais rápida, não precisa compilar rust)
        if git clone https://aur.archlinux.org/paru-bin.git .; then
            # makepkg não pode rodar como root, mas nosso script roda como user, então ok.
            # -s: instala dependencias, -i: instala o pacote
            makepkg -si --noconfirm
            log "SUCCESS" "Paru instalado com sucesso."
        else
            log "ERROR" "Falha ao clonar Paru. O sistema continuará usando Pacman."
        fi

        # Limpeza
        cd "$BASE_DIR"
        rm -rf /tmp/paru_install
    else
        log "INFO" "Paru já está instalado."
    fi
fi

# --- Lógica para DEBIAN/UBUNTU (Apt-Fast) ---
if [[ "$DISTRO_FAMILY" == "debian" ]]; then
    # Verifica se é Ubuntu ou derivado (Mint, Pop, Zorin, etc)
    if [[ "$DISTRO_NAME" == "ubuntu" || "$ID_LIKE" =~ "ubuntu" ]]; then
        if ! command -v apt-fast &> /dev/null; then
            log "INFO" "Instalando APT-FAST (Acelerador de downloads)..."

            # Adiciona PPA
            $SUDO add-apt-repository -y ppa:apt-fast/stable
            $SUDO apt-get update

            # O apt-fast pede configuração interativa.
            # Tentamos configurar as variáveis de ambiente para evitar o prompt (non-interactive)
            echo "apt-fast apt-fast/maxdownloads string 5" | $SUDO debconf-set-selections
            echo "apt-fast apt-fast/dlflag boolean true" | $SUDO debconf-set-selections
            echo "apt-fast apt-fast/aptmanager string apt-get" | $SUDO debconf-set-selections

            # Instalação suprimindo interface
            DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y apt-fast aria2

            log "SUCCESS" "Apt-fast configurado."
        else
            log "INFO" "Apt-fast já está instalado."
        fi
    else
        log "WARN" "Distro Debian Pura detectada. Apt-fast ignorado para evitar instabilidade."
    fi
fi

# ------------------------------------------------------------------------------
# 3. Instalação da Interface Gráfica (YAD)
# ------------------------------------------------------------------------------
log "INFO" "Verificando dependência de Interface (YAD)..."

if ! command -v yad &> /dev/null; then
    log "INFO" "Instalando YAD..."

    # Agora já podemos usar nossa função 'i' pois os aceleradores (se existirem) já estão lá
    i yad

    # Verificação pós-instalação
    if ! command -v yad &> /dev/null; then
        # Fallback extremo: tenta compilar ou baixar (raro falhar nos repos oficiais hoje em dia)
        die "Falha crítica: YAD não pôde ser instalado. O script não pode exibir a interface."
    fi
else
    log "INFO" "YAD já está instalado."
fi

# ------------------------------------------------------------------------------
# 4. Atualização Completa do Sistema
# ------------------------------------------------------------------------------
# Agora que temos os aceleradores configurados, fazemos o full-upgrade
log "INFO" "Realizando atualização completa do sistema (Full Upgrade)..."
up

log "SUCCESS" "Sistema base preparado com sucesso."
