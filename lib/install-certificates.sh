#!/bin/bash
# ==============================================================================
# Script: install-certificates.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar certificados ICP-Brasil e ferramentas de assinatura digital
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Instala:
# - Assinador SERPRO (certificados ICP-Brasil)
# - LibreOffice com suporte a certificados
# - Utilitários de criptografia
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

section "Instalação de Certificados ICP-Brasil"

log "WARN" "Este script instala ferramentas de assinatura digital brasileira"

# ==============================================================================
# INSTALAÇÃO DO ASSINADOR SERPRO
# ==============================================================================

log "STEP" "Instalando Assinador SERPRO..."

case "$DISTRO_FAMILY" in
    debian)
        # Adiciona repositório SERPRO
        log "INFO" "Adicionando repositório SERPRO..."
        
        # Baixa e instala chave de assinatura
        wget -qO- https://assinadorserpro.estaleiro.serpro.gov.br/repository/AssinadorSERPROpublic.asc | \
            $SUDO tee /etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc > /dev/null
        
        # Adiciona repositório
        echo "Types: deb
URIs: https://www.assinadorserpro.estaleiro.serpro.gov.br/repository/
Suites: universal
Components: stable
Architectures: amd64
Signed-By: /etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc" | \
            $SUDO tee /etc/apt/sources.list.d/serpro.sources > /dev/null
        
        # Atualiza e instala
        $SUDO apt update
        i "assinador-serpro" || log "WARN" "Falha ao instalar Assinador SERPRO"
        ;;
    
    arch)
        log "WARN" "Assinador SERPRO não está disponível no repositório Arch"
        log "INFO" "Você pode instalar via AUR ou usar a versão AppImage"
        ;;
    
    fedora)
        log "WARN" "Assinador SERPRO não está disponível no repositório Fedora"
        log "INFO" "Você pode instalar via AppImage ou compilar do código-fonte"
        ;;
    
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

# ==============================================================================
# INSTALAÇÃO DE UTILITÁRIOS DE CRIPTOGRAFIA
# ==============================================================================

log "STEP" "Instalando utilitários de criptografia..."

case "$DISTRO_FAMILY" in
    debian)
        i "openssl" "ca-certificates" "gnupg" "libpcsclite1" || log "WARN" "Falha ao instalar utilitários"
        ;;
    arch)
        i "openssl" "ca-certificates" "gnupg" "pcsclite" || log "WARN" "Falha ao instalar utilitários"
        ;;
    fedora)
        i "openssl" "ca-certificates" "gnupg" "pcsc-lite-libs" || log "WARN" "Falha ao instalar utilitários"
        ;;
esac

# ==============================================================================
# CONFIGURAÇÃO DE CERTIFICADOS
# ==============================================================================

log "STEP" "Configurando certificados..."

# Atualiza certificados do sistema
$SUDO update-ca-certificates 2>/dev/null || true

log "INFO" "Certificados do sistema atualizados"

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

section "Certificados ICP-Brasil Configurados"
log "SUCCESS" "Instalação de certificados concluída!"
log "INFO" "Você pode agora usar certificados digitais em aplicativos"
log "INFO" "Para usar em navegadores, importe o certificado nas preferências"
