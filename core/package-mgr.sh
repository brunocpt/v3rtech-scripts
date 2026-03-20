#!/bin/bash
# ==============================================================================
# Arquivo: core/package-mgr.sh
# Versão: 7.0.0
# Data: 2026-03-20
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

    # Instala Paru num subshell isolado para não afetar o trap EXIT do processo pai
    local temp_dir
    temp_dir=$(mktemp -d)

    (
        trap 'rm -rf "$temp_dir"' EXIT
        cd "$temp_dir" || exit 1

        log "INFO" "Clonando repositório Paru..."
        git clone https://aur.archlinux.org/paru.git 2>/dev/null || {
            log "WARN" "Falha ao clonar Paru"
            exit 1
        }

        cd paru || exit 1
        log "INFO" "Compilando Paru (isso pode levar alguns minutos)..."
        makepkg -si --noconfirm 2>/dev/null || log "WARN" "Falha ao compilar Paru"
    )
    local subshell_status=$?
    rm -rf "$temp_dir"

    if [ $subshell_status -ne 0 ]; then
        log "ERROR" "Falha ao instalar Paru"
        return 1
    fi

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
        return 1
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

    # Garante que o remote Flathub esteja configurado antes de instalar qualquer app
    if ! flatpak remote-list 2>/dev/null | grep -q "^flathub"; then
        log "INFO" "Adicionando remote Flathub..."
        $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
            || log "WARN" "Falha ao adicionar remote Flathub"
    fi

    log "INFO" "Instalando Flatpak: $flatpak_id"

    $SUDO flatpak install -y flathub "$flatpak_id"

    return $?
}

# --- 8. FUNÇÃO: INSTALAR VIA PIPX ---

install_pipx() {
    local packages_str="$1"
    if [ -z "$packages_str" ]; then
        log "WARN" "install_pipx chamado sem nome de pacote"
        return 1
    fi
    if ! _check_cmd pipx; then
        log "INFO" "Instalando Pipx..."
        i pipx || return 1
    fi
    local overall_status=0
    for pkg in $packages_str; do
        log "INFO" "Instalando via Pipx: $pkg"
        pipx install "$pkg" || overall_status=1
    done
    return $overall_status
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

# --- 11. FUNÇÕES: INSTALAR APP (NATIVO / FLATPAK / ROTEADOR) ---
#
# Centralizadas aqui para evitar duplicação nos scripts install-apps-*.sh
# Dependem de APP_MAP_* (populados por apps-data.sh) estarem no ambiente.

install_native_app() {
    local app_name="$1"
    local package="${APP_MAP_NATIVE[$app_name]}"
    if [ -z "$package" ]; then
        log "DEBUG" "Sem pacote nativo para '$app_name' em $DISTRO_FAMILY"
        return 1
    fi
    if is_installed "$package"; then
        log "INFO" "Pacote '$package' ($app_name) já está instalado."
        return 10
    fi
    log "INFO" "Instalando $app_name (nativo)..."
    i "$package"
    return $?
}

install_flatpak_app() {
    local app_name="$1"
    local flatpak_id="${APP_MAP_FLATPAK[$app_name]}"
    if [ -z "$flatpak_id" ]; then return 1; fi
    # flatpak info verifica instalações de sistema e de usuário
    if flatpak info "$flatpak_id" &>/dev/null; then
        log "INFO" "Flatpak '$flatpak_id' ($app_name) já está instalado."
        return 10
    fi
    log "INFO" "Instalando $app_name (Flatpak)..."
    install_flatpak "$flatpak_id"
    return $?
}

install_app() {
    local app_name="$1"
    local app_method="${APP_MAP_METHOD[$app_name]}"
    local prefer_native="${PREFER_NATIVE:-false}"
    local install_status=1
    local install_type=""

    if [ "$app_method" = "custom" ]; then return 0; fi

    log "STEP" "Processando $app_name..."

    if [ "$app_method" = "pipx" ]; then
        # Pacotes pipx ficam no campo flatpak_id; pode ser lista separada por espaço
        local pipx_pkg="${APP_MAP_FLATPAK[$app_name]}"
        install_pipx "$pipx_pkg"; install_status=$?; install_type="pipx"
    elif [ "$app_method" = "flatpak" ]; then
        # Instalação forçada via Flatpak, sem fallback
        install_flatpak_app "$app_name"; install_status=$?; install_type="flatpak"
    elif [ "$app_method" = "native" ]; then
        # Instalação forçada via pacote nativo, sem fallback (ex: ferramentas de sistema)
        install_native_app "$app_name"; install_status=$?; install_type="native"
    elif [ "$prefer_native" = "true" ]; then
        # auto: tenta nativo primeiro, cai em flatpak se falhar
        install_native_app "$app_name"; install_status=$?; install_type="native"
        if [ $install_status -ne 0 ] && [ $install_status -ne 10 ]; then
            install_flatpak_app "$app_name"; install_status=$?; install_type="flatpak"
        fi
    else
        # auto: tenta flatpak primeiro, cai em nativo se falhar
        install_flatpak_app "$app_name"; install_status=$?; install_type="flatpak"
        if [ $install_status -ne 0 ] && [ $install_status -ne 10 ]; then
            install_native_app "$app_name"; install_status=$?; install_type="native"
        fi
    fi

    if [ $install_status -eq 0 ] || [ $install_status -eq 10 ]; then
        [ $install_status -eq 0 ] && log "SUCCESS" "$app_name instalado via $install_type"
        return 0
    fi
    log "WARN" "Falha ao instalar $app_name"
    return 1
}

# --- 12. EXPORTAÇÃO DE FUNÇÕES ---

export -f \
_check_cmd \
i \
r \
up \
s \
is_installed \
install_flatpak \
install_pipx \
configure_flatpak_overrides \
detect_package_manager \
install_native_app \
install_flatpak_app \
install_app