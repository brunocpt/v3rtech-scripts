#!/bin/bash
# ==============================================================================
# Script: install-desktop-cosmic.sh
# Versão: 5.2.0
# Data: 2026-03-05
# Objetivo: Instalar COSMIC Desktop e Componentes Independentes (Arch/Ubuntu/Fedora)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

if [ -z "$DISTRO_FAMILY" ]; then
    source "$(dirname "$0")/detect-system.sh" || die "Falha ao detectar sistema"
fi

section "Instalação do COSMIC Desktop Environment"

# Lista de componentes independentes conforme documentação do Arch
# Adaptado para funcionar como array para a função 'i'
COSMIC_INDEPENDENT=("cosmic-text-editor" "cosmic-files" "cosmic-terminal" "cosmic-player" "cosmic-wallpapers" "gnome-keyring")

case "$DISTRO_FAMILY" in
    debian)
        if grep -iq "ubuntu" /etc/os-release; then
            log "STEP" "Configurando PPA System76 para Ubuntu..."
            $SUDO apt update && $SUDO apt install -y software-properties-common
            $SUDO add-apt-repository -y ppa:system76/cosmic-beta
            $SUDO apt update
        fi
        log "STEP" "Instalando metapacote cosmic e componentes independentes..."
        # No Ubuntu/Debian, cosmic-text-editor pode ser apenas cosmic-edit em algumas versões do PPA
        i "cosmic" || log "WARN" "Alguns componentes independentes podem não estar disponíveis no PPA"
        i "${COSMIC_INDEPENDENT[@]}" || log "WARN" "Alguns componentes independentes podem não estar disponíveis no PPA"
        ;;

    arch)
        log "STEP" "Instalando COSMIC via Arch Extra..."
        # Grupo 'cosmic' + componentes independentes citados na Wiki
        i "cosmic" "packagekit" "power-profiles-daemon" || log "WARN" "Falha na instalação de componentes"
        i "${COSMIC_INDEPENDENT[@]}" || log "WARN" "Falha na instalação de componentes"

        log "INFO" "Habilitando serviços de sistema essenciais..."
        $SUDO systemctl enable --now power-profiles-daemon
        ;;

    fedora)
        log "STEP" "Configurando repositório COPR para Fedora..."
        $SUDO dnf copr enable -y ryanbr/cosmic
        i "cosmic-desktop" || log "WARN" "Falha ao instalar pacotes no Fedora"
        i "${COSMIC_INDEPENDENT[@]}" || log "WARN" "Falha ao instalar pacotes no Fedora"
        ;;

    *)
        log "ERROR" "COSMIC não suportado nativamente em: $DISTRO_FAMILY"
        exit 1
        ;;
esac

# Configuração de Portais XDG (Essencial para o funcionamento do cosmic-files e diálogos)
log "STEP" "Configurando Portais XDG..."
i "xdg-desktop-portal-cosmic" "xdg-desktop-portal-gtk"

log "SUCCESS" "COSMIC Desktop e Componentes Independentes instalados!"
log "INFO" "Componentes instalados: ${COSMIC_INDEPENDENT[*]}"

save_config "DESKTOP_ENV" "cosmic"
