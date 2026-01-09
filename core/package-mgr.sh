#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: core/package-mgr.sh
# Versão: 2.0.0 (Shortcode Edition)
#
# Descrição: Abstração dos gerenciadores de pacotes com sintaxe minimalista.
# Comandos disponíveis:
#   i  -> Install (Instalar)
#   r  -> Remove (Remover)
#   up -> Update (Atualizar sistema)
#   s  -> Show/Search (Informações do pacote)
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Função auxiliar interna (não exportada)
_check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# i : INSTALL (Instalar pacotes)
# ------------------------------------------------------------------------------
i() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        log "WARN" "Função 'i' chamada sem argumentos."
        return 1
    fi

    # log "INFO" "i: Instalando ${packages[*]}..."
    # (Comentado para reduzir verbosidade no terminal, logs já pegam)

    case "$DISTRO_FAMILY" in
        debian)
            if _check_cmd apt-fast; then
                $SUDO apt-fast install -y "${packages[@]}"
            else
                $SUDO apt install -y "${packages[@]}"
            fi
            ;;

        arch)
            # Prioriza Paru/Yay para cobrir AUR e Repo Oficial
            if _check_cmd paru; then
                paru -S --noconfirm --needed "${packages[@]}"
            elif _check_cmd yay; then
                yay -S --noconfirm --needed "${packages[@]}"
            else
                $SUDO pacman -S --noconfirm --needed "${packages[@]}"
            fi
            ;;

        fedora)
            $SUDO dnf install -y "${packages[@]}"
            ;;

        *)
            log "ERROR" "Distro não suportada para instalação: $DISTRO_FAMILY"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# r : REMOVE (Remover pacotes)
# ------------------------------------------------------------------------------
r() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then return 1; fi

    log "INFO" "Removendo: ${packages[*]}"

    case "$DISTRO_FAMILY" in
        debian)
            $SUDO apt remove -y "${packages[@]}"
            ;;
        arch)
            # -Rs remove o pacote e dependências não usadas (limpeza)
            $SUDO pacman -Rs --noconfirm "${packages[@]}"
            ;;
        fedora)
            $SUDO dnf remove -y "${packages[@]}"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# up : UPDATE (Atualizar sistema completo)
# ------------------------------------------------------------------------------
up() {
    log "INFO" "Iniciando atualização do sistema (up)..."

    case "$DISTRO_FAMILY" in
        debian)
            if _check_cmd apt-fast; then
                $SUDO apt-fast update && $SUDO apt-fast full-upgrade -y
            else
                $SUDO apt update && $SUDO apt full-upgrade -y
            fi
            $SUDO apt autoremove -y
            ;;
        arch)
            if _check_cmd paru; then
                paru -Syu --noconfirm
            else
                $SUDO pacman -Syu --noconfirm
            fi
            ;;
        fedora)
            $SUDO dnf upgrade --refresh -y
            ;;
    esac
}

# ------------------------------------------------------------------------------
# s : SHOW/SEARCH (Verificar informações/existência)
# ------------------------------------------------------------------------------
s() {
    local package="$1"
    [ -z "$package" ] && return 1

    echo -e "${CYAN}>>> Informações sobre: $package${NC}"

    case "$DISTRO_FAMILY" in
        debian)
            apt show "$package" 2>/dev/null
            ;;
        arch)
            pacman -Si "$package" 2>/dev/null || paru -Si "$package" 2>/dev/null
            ;;
        fedora)
            dnf info "$package" 2>/dev/null
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Wrappers Específicos (Flatpak/Pipx)
# ------------------------------------------------------------------------------

# Wrapper para Flatpak (mantive nome longo para evitar confusão com 'i')
install_flatpak() {
    local app_id="$1"

    if ! _check_cmd flatpak; then
        log "ERROR" "Comando 'flatpak' não encontrado. A etapa de configuração do Flatpak deveria ter sido executada antes."
        return 1
    fi

    log "INFO" "Instalando Flatpak: $app_id"
    if ! flatpak install -y --or-update flathub "$app_id"; then
        log "ERROR" "Falha ao instalar Flatpak: $app_id"
        # Não retorna 1 para não parar o script inteiro, apenas loga o erro.
    else
        log "SUCCESS" "Instalado com sucesso via Flatpak: $app_id"
    fi
}

# Wrapper para Pipx
install_pipx() {
    local pkg_name="$1"

    if ! _check_cmd pipx; then
        i pipx
        pipx ensurepath
    fi
    pipx install "$pkg_name"
    pipx ensurepath
}
