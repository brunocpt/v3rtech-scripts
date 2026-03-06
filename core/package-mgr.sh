#!/bin/bash
# ==============================================================================
# Arquivo: core/package-mgr.sh
# Versão: 4.1.0
# Data: 2026-03-06
# Objetivo: Abstração dos gerenciadores de pacotes (multi-distro)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# --- 1. FUNÇÃO AUXILIAR INTERNA ---

_check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# --- 2. FUNÇÃO: ENSURE PARU (Arch Linux) ---

ensure_paru() {
    if [[ "$DISTRO_FAMILY" != "arch" ]]; then
        return 0
    fi

    if _check_cmd paru; then
        return 0
    fi

    log "STEP" "Instalando Paru (AUR helper)..."

    # Verifica pré-requisitos
    if ! _check_cmd git; then
        log "INFO" "Git não está instalado, instalando..."
        $SUDO pacman -S --noconfirm git || log "WARN" "Falha ao instalar Git"
    fi

    if ! pacman -Qi base-devel &>/dev/null; then
        log "INFO" "base-devel não está instalado, instalando..."
        $SUDO pacman -S --noconfirm base-devel || log "WARN" "Falha ao instalar base-devel"
    fi

    # Instala Paru
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    pushd "$temp_dir" >/dev/null || return 1

    log "INFO" "Clonando repositório Paru..."
    git clone https://aur.archlinux.org/paru.git 2>/dev/null || {
        log "WARN" "Falha ao clonar Paru"
        popd >/dev/null || true
        return 1
    }

    if [ -d "paru" ]; then
        cd paru || { popd >/dev/null || true; return 1; }
        log "INFO" "Compilando Paru (isso pode levar alguns minutos)..."
        makepkg -si --noconfirm 2>/dev/null || log "WARN" "Falha ao compilar Paru"
    fi

    popd >/dev/null || true

    if _check_cmd paru; then
        log "SUCCESS" "Paru instalado com sucesso"
        return 0
    else
        log "ERROR" "Falha ao instalar Paru"
        return 1
    fi
}

# --- 3. FUNÇÃO: INSTALL ---

i() {
    # Coleta todos os argumentos e os separa por espaços, depois reconstrói o array
    # Isso permite passar "pkg1 pkg2" como um único argumento e ainda assim separá-los
    local all_args="$*"
    local packages=($all_args)

    if [ ${#packages[@]} -eq 0 ]; then
        log "WARN" "Função 'i' chamada sem argumentos."
        return 1
    fi

    case "$DISTRO_FAMILY" in

        debian)
            if _check_cmd apt-fast; then
                $SUDO apt-fast install -y "${packages[@]}"
            else
                $SUDO apt install -y "${packages[@]}"
            fi
            ;;

        arch)
            ensure_paru
            paru -S --noconfirm --needed "${packages[@]}"
            ;;

        fedora)
            $SUDO dnf install -y --skip-unavailable "${packages[@]}"
            ;;

        *)

            log "ERROR" "Distro não suportada para instalação: $DISTRO_FAMILY"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        [ "$VERBOSE" -eq 1 ] && log "DEBUG" "Pacotes instalados: ${packages[*]}"
        return 0
    else
        log "WARN" "Falha ao instalar: ${packages[*]}"
        return 1
    fi
}

# --- 3. FUNÇÃO: REMOVE ---

r() {
    local all_args="$*"
    local packages=($all_args)
    if [ ${#packages[@]} -eq 0 ]; then
        log "WARN" "Função 'r' chamada sem argumentos."
        return 1
    fi
    log "INFO" "Removendo: ${packages[*]}"
    case "$DISTRO_FAMILY" in
        debian)
            $SUDO apt remove -y "${packages[@]}"
            ;;
        arch)
            paru -Rs --noconfirm "${packages[@]}"
            ;;
        fedora)
            $SUDO dnf remove -y "${packages[@]}"
            ;;
    esac
    return $?
}

# --- 4. FUNÇÃO: UPDATE ---

up() {
    log "INFO" "Iniciando atualização do sistema..."
    case "$DISTRO_FAMILY" in
        debian)
            if _check_cmd apt-fast; then
                $SUDO apt-fast update && $SUDO apt-fast upgrade -y
            else
                $SUDO apt update && $SUDO apt upgrade -y
            fi
            ;;
        arch)
            ensure_paru
            paru -Syu --noconfirm
            ;;
        fedora)
            $SUDO dnf upgrade -y
            ;;
    esac

    if [ $? -eq 0 ]; then
        log "SUCCESS" "Sistema atualizado com sucesso"
        return 0
    else
        log "ERROR" "Falha ao atualizar sistema"
        return 1
    fi
}

# --- 5. FUNÇÃO: SEARCH ---

s() {
    local package="$1"
    if [ -z "$package" ]; then
        log "WARN" "Função 's' chamada sem argumentos."
        return 1
    fi
    case "$DISTRO_FAMILY" in
        debian)
            apt show "$package"
            ;;
        arch)
            paru -Si "$package" || paru -Ss "$package"
            ;;
        fedora)
            dnf info "$package"
            ;;
    esac
}

# --- 6. FUNÇÃO: CONFIGURAR OVERRIDES GLOBAIS DO FLATPAK ---

configure_flatpak_overrides() {
    if ! _check_cmd flatpak; then
        log "WARN" "Flatpak não instalado; overrides globais não aplicados."
        return 1
    fi
    log "INFO" "Verificando overrides globais do Flatpak..."

    # Verifica se já existe override configurado
    if flatpak override --system --show | grep -q "/mnt"; then
        log "DEBUG" "Overrides globais do Flatpak já configurados."
        return 0
    fi
    log "INFO" "Aplicando overrides globais do Flatpak..."

    if $SUDO flatpak override --system \
        --filesystem=xdg-config/gtk-3.0 \
        --filesystem=xdg-config/gtk-4.0 \
        --filesystem=~/.themes \
        --filesystem=~/.icons \
        --filesystem=/mnt \
        --filesystem=host-etc \
        --env=TMPDIR=/tmp ; then
        log "SUCCESS" "Overrides globais do Flatpak aplicados com sucesso."

    else
        log "WARN" "Falha ao aplicar alguns overrides globais do Flatpak."
    fi
}

# --- 7. FUNÇÃO: INSTALAR FLATPAK APP ---

install_flatpak() {
    local flatpak_id="$1"
    if [ -z "$flatpak_id" ]; then
        log "WARN" "install_flatpak chamado sem ID de Flatpak"
        return 1
    fi

    if ! _check_cmd flatpak; then
        log "INFO" "Instalando Flatpak..."
        i flatpak || return 1
    fi
    log "INFO" "Instalando Flatpak: $flatpak_id"

    $SUDO flatpak install -y flathub "$flatpak_id"

    return $?
}

# --- 8. FUNÇÃO: INSTALAR VIA PIPX ---

install_pipx() {
    local package="$1"
    if [ -z "$package" ]; then
        log "WARN" "install_pipx chamado sem nome de pacote"
        return 1
    fi
    if ! _check_cmd pipx; then
        log "INFO" "Instalando Pipx..."
        i pipx || return 1
    fi
    log "INFO" "Instalando via Pipx: $package"
    pipx install "$package"
    return $?
}

# --- 9. FUNÇÃO: DETECTAR GERENCIADOR DE PACOTES ---

detect_package_manager() {
    if [ -z "$DISTRO_FAMILY" ]; then
        log "ERROR" "DISTRO_FAMILY não definido. Execute detect-system.sh primeiro."
        return 1
    fi
    case "$DISTRO_FAMILY" in
        debian)
            PKG_MANAGER="apt"
            ;;
        arch)
            PKG_MANAGER="pacman"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            ;;
        *)
            log "ERROR" "Gerenciador de pacotes desconhecido para: $DISTRO_FAMILY"
            return 1
            ;;
    esac
    log "DEBUG" "Gerenciador de pacotes detectado: $PKG_MANAGER"

    return 0
}

# --- 10. FUNÇÃO: VERIFICAR SE PACOTE ESTÁ INSTALADO ---

is_installed() {
    local all_args="$*"
    local packages=($all_args)
    if [ ${#packages[@]} -eq 0 ]; then
        log "WARN" "Função 'is_installed' chamada sem argumentos."
        return 1
    fi

    for package in "${packages[@]}"; do
        case "$DISTRO_FAMILY" in
            debian)
                if ! dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
                    return 1
                fi
                ;;
            arch)
                if _check_cmd paru; then
                    if ! paru -Q "$package" >/dev/null 2>&1; then
                        return 1
                    fi
                else
                    if ! pacman -Q "$package" >/dev/null 2>&1; then
                        return 1
                    fi
                fi
                ;;
            fedora)
                if ! rpm -q "$package" >/dev/null 2>&1; then
                    return 1
                fi
                ;;
            *)
                log "ERROR" "Distro não suportada para verificação de instalação: $DISTRO_FAMILY"
                return 1
                ;;
        esac
    done
    return 0
}

# --- 11. EXPORTAÇÃO DE FUNÇÕES ---

export -f \
i \
r \
up \
s \
is_installed \
install_flatpak \
install_pipx \
configure_flatpak_overrides \
detect_package_manager