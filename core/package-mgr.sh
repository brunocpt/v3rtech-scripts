#!/bin/bash
# ==============================================================================
# Arquivo: core/package-mgr.sh
# Versão: 4.0.0
# Data: 2026-02-23
# Objetivo: Abstração dos gerenciadores de pacotes (multi-distro)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Fornece uma interface unificada para instalar/remover pacotes em qualquer
# distribuição Linux suportada (Debian, Arch, Fedora).
#
# Comandos disponíveis:
#   i <pacote>     -> Install (Instalar)
#   r <pacote>     -> Remove (Remover)
#   up             -> Update (Atualizar sistema)
#   s <pacote>     -> Show/Search (Informações do pacote)
#
# ==============================================================================

# --- 1. FUNÇÃO AUXILIAR INTERNA ---

# Verifica se um comando existe
_check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# --- 2. FUNÇÃO: INSTALL (Instalar pacotes) ---

# Instala um ou mais pacotes
# Uso: i pacote1 pacote2 pacote3
i() {
    local packages=("$@")
    
    # Validação
    if [ ${#packages[@]} -eq 0 ]; then
        log "WARN" "Função 'i' chamada sem argumentos."
        return 1
    fi
    
    # Detecta distro e instala
    case "$DISTRO_FAMILY" in
        debian)
            # Prioriza apt-fast se disponível
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
            $SUDO dnf install -y --skip-unavailable "${packages[@]}"
            ;;
        
        *)
            log "ERROR" "Distro não suportada para instalação: $DISTRO_FAMILY"
            return 1
            ;;
    esac
    
    # Verifica resultado
    if [ $? -eq 0 ]; then
        [ "$VERBOSE" -eq 1 ] && log "DEBUG" "Pacotes instalados: ${packages[*]}"
        return 0
    else
        log "WARN" "Falha ao instalar: ${packages[*]}"
        return 1
    fi
}

# --- 3. FUNÇÃO: REMOVE (Remover pacotes) ---

# Remove um ou mais pacotes
# Uso: r pacote1 pacote2
r() {
    local packages=("$@")
    
    # Validação
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
            # -Rs remove o pacote e dependências não usadas
            $SUDO pacman -Rs --noconfirm "${packages[@]}"
            ;;
        fedora)
            $SUDO dnf remove -y "${packages[@]}"
            ;;
    esac
    
    return $?
}

# --- 4. FUNÇÃO: UPDATE (Atualizar sistema) ---

# Atualiza todos os pacotes do sistema
up() {
    log "INFO" "Iniciando atualização do sistema..."
    
    case "$DISTRO_FAMILY" in
        debian)
            # Prioriza apt-fast
            if _check_cmd apt-fast; then
                $SUDO apt-fast update && $SUDO apt-fast upgrade -y
            else
                $SUDO apt update && $SUDO apt upgrade -y
            fi
            ;;
        
        arch)
            # Prioriza Paru
            if _check_cmd paru; then
                $SUDO paru -Syu --noconfirm
            elif _check_cmd yay; then
                $SUDO yay -Syu --noconfirm
            else
                $SUDO pacman -Syu --noconfirm
            fi
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

# --- 5. FUNÇÃO: SEARCH (Pesquisar pacote) ---

# Pesquisa informações sobre um pacote
# Uso: s pacote
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
            pacman -Si "$package" || pacman -Ss "$package"
            ;;
        fedora)
            dnf info "$package"
            ;;
    esac
}

# --- 6. FUNÇÃO: INSTALAR FLATPAK ---

# Instala um aplicativo via Flatpak
# Uso: install_flatpak com.example.App
install_flatpak() {
    local flatpak_id="$1"
    
    if [ -z "$flatpak_id" ]; then
        log "WARN" "install_flatpak chamado sem ID de Flatpak"
        return 1
    fi
    
    # Verifica se Flatpak está instalado
    if ! _check_cmd flatpak; then
        log "INFO" "Instalando Flatpak..."
        i flatpak || return 1
    fi
    
    # Instala a aplicação
    log "INFO" "Instalando Flatpak: $flatpak_id"
    $SUDO flatpak install -y flathub "$flatpak_id" || return 1
    
    # Aplica overrides globais do Flatpak
    log "INFO" "Aplicando overrides do Flatpak para $flatpak_id..."
    if $SUDO flatpak override --filesystem=xdg-config/gtk-3.0 "$flatpak_id" && \
       $SUDO flatpak override --filesystem=xdg-config/gtk-4.0 "$flatpak_id" && \
       $SUDO flatpak override --filesystem=~/.themes "$flatpak_id" && \
       $SUDO flatpak override --filesystem=~/.icons "$flatpak_id" && \
       $SUDO flatpak override --filesystem=/mnt "$flatpak_id" && \
       $SUDO flatpak override --filesystem=host-etc "$flatpak_id"; then
        log "SUCCESS" "Overrides do Flatpak aplicados com sucesso para $flatpak_id"
    else
        log "WARN" "Falha ao aplicar alguns overrides do Flatpak para $flatpak_id"
    fi
    
    return 0
}

# --- 7. FUNÇÃO: INSTALAR VIA PIPX ---

# Instala um pacote Python via Pipx
# Uso: install_pipx package-name
install_pipx() {
    local package="$1"
    
    if [ -z "$package" ]; then
        log "WARN" "install_pipx chamado sem nome de pacote"
        return 1
    fi
    
    # Verifica se Pipx está instalado
    if ! _check_cmd pipx; then
        log "INFO" "Instalando Pipx..."
        i pipx || return 1
    fi
    
    # Instala o pacote
    log "INFO" "Instalando via Pipx: $package"
    pipx install "$package"
    
    return $?
}

# --- 8. FUNÇÃO: DETECTAR GERENCIADOR DE PACOTES ---

# Detecta qual gerenciador de pacotes está disponível
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

# --- 9. EXPORTAÇÃO DE FUNÇÕES ---

# Garante que as funções estejam disponíveis em subshells
export -f i r up s install_flatpak install_pipx detect_package_manager
