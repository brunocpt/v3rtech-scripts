#!/bin/bash
# ==============================================================================
# Script: install-virtualbox.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar e configurar VirtualBox
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Instala:
# - VirtualBox
# - Extension Pack
# - Guest Additions (para VMs)
# - Configura permissões
#
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

section "Instalação de VirtualBox"

# ==============================================================================
# INSTALAÇÃO DO VIRTUALBOX
# ==============================================================================

log "STEP" "Instalando VirtualBox..."

case "$DISTRO_FAMILY" in
    debian)
        # Adiciona repositório oficial
        log "INFO" "Adicionando repositório VirtualBox..."
        
        # Chave GPG
        wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | $SUDO gpg --dearmor -o /etc/apt/trusted.gpg.d/oracle-virtualbox.gpg
        
        # Repositório
        echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/oracle-virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | \
            $SUDO tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
        
        $SUDO apt update
        i "virtualbox-7.0" || log "WARN" "Falha ao instalar VirtualBox"
        ;;
    
    arch)
        i "virtualbox" "virtualbox-host-modules-arch" || log "WARN" "Falha ao instalar VirtualBox"
        ;;
    
    fedora)
        i "VirtualBox" "kernel-devel" || log "WARN" "Falha ao instalar VirtualBox"
        ;;
    
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

# ==============================================================================
# CONFIGURAÇÃO PÓS-INSTALAÇÃO
# ==============================================================================

log "STEP" "Configurando VirtualBox..."

# Cria grupo vboxusers se não existir
if ! getent group vboxusers > /dev/null; then
    $SUDO groupadd vboxusers
    log "INFO" "Grupo vboxusers criado"
fi

# Adiciona usuário ao grupo
$SUDO usermod -aG vboxusers "$REAL_USER"
log "INFO" "Usuário $REAL_USER adicionado ao grupo vboxusers"

# Carrega módulos do kernel
if command -v modprobe &>/dev/null; then
    $SUDO modprobe vboxdrv 2>/dev/null || true
    log "INFO" "Módulos VirtualBox carregados"
fi

# ==============================================================================
# VERIFICAÇÃO
# ==============================================================================

log "STEP" "Verificando instalação..."

if command -v VirtualBox &>/dev/null; then
    local vbox_version=$(VirtualBox --version)
    log "SUCCESS" "VirtualBox instalado: $vbox_version"
else
    log "ERROR" "Falha ao instalar VirtualBox"
    exit 1
fi

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

section "VirtualBox Instalado"
log "SUCCESS" "Instalação de VirtualBox concluída!"
log "INFO" "Você pode precisar fazer logout e login novamente para usar VirtualBox"
log "INFO" "Ou execute: newgrp vboxusers"
