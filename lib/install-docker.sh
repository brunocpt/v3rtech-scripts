#!/bin/bash
# ==============================================================================
# Script: install-docker.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar e configurar Docker e Docker Compose
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Instala:
# - Docker Engine
# - Docker Compose (versão standalone)
# - Configura permissões
# - Habilita serviço
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

section "Instalação de Docker"

# ==============================================================================
# INSTALAÇÃO DO DOCKER
# ==============================================================================

log "STEP" "Instalando Docker..."

case "$DISTRO_FAMILY" in
    debian)
        # Remove instalações antigas
        $SUDO apt remove -y docker docker.io docker-engine 2>/dev/null || true
        
        # Instala dependências
        i "ca-certificates" "curl" "gnupg" "lsb-release"
        
        # Adiciona repositório oficial do Docker
        $SUDO mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
            $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        $SUDO apt update
        i "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
        ;;
    
    arch)
        i "docker" "docker-compose"
        ;;
    
    fedora)
        i "docker" "docker-compose"
        ;;
    
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

# ==============================================================================
# CONFIGURAÇÃO PÓS-INSTALAÇÃO
# ==============================================================================

log "STEP" "Configurando Docker..."

# Cria grupo docker se não existir
if ! getent group docker > /dev/null; then
    $SUDO groupadd docker
    log "INFO" "Grupo docker criado"
fi

# Adiciona usuário ao grupo docker
$SUDO usermod -aG docker "$REAL_USER"
log "INFO" "Usuário $REAL_USER adicionado ao grupo docker"

# Habilita serviço
$SUDO systemctl enable --now docker || true
log "INFO" "Serviço Docker habilitado"

# ==============================================================================
# VERIFICAÇÃO
# ==============================================================================

log "STEP" "Verificando instalação..."

if command -v docker &>/dev/null; then
    docker_version=$(docker --version)
    log "SUCCESS" "Docker instalado: $docker_version"
else
    log "ERROR" "Falha ao instalar Docker"
    exit 1
fi

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

section "Docker Instalado"
log "SUCCESS" "Instalação de Docker concluída!"
log "INFO" "Você pode precisar fazer logout e login novamente para usar Docker sem sudo"
log "INFO" "Ou execute: newgrp docker"
