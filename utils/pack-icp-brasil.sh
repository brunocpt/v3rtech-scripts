#!/bin/bash

################################################################################
# Script Multi-Distribuição para Instalação da Cadeia ICP-Brasil
# 
# Compatibilidade: Arch Linux, Ubuntu, Debian, Fedora e distribuições derivadas
# Características: Agnóstico, Idempotente, com detecção automática de distro
#
# Autor: Desenvolvido para compatibilidade universal
# Data: 2026
################################################################################

set -euo pipefail

# ======================================================
# CORES PARA LEGIBILIDADE
# ======================================================
VERMELHO=$(tput setaf 1 2>/dev/null || echo "")
VERDE=$(tput setaf 2 2>/dev/null || echo "")
AMARELO=$(tput setaf 3 2>/dev/null || echo "")
AZUL=$(tput setaf 4 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")

# ======================================================
# FUNÇÕES AUXILIARES
# ======================================================

log_info() {
    echo "${AZUL}[INFO]${RESET} $*"
}

log_sucesso() {
    echo "${VERDE}[SUCESSO]${RESET} $*"
}

log_erro() {
    echo "${VERMELHO}[ERRO]${RESET} $*"
}

log_aviso() {
    echo "${AMARELO}[AVISO]${RESET} $*"
}

# Detectar distribuição Linux
detectar_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID}"
    else
        log_erro "Não foi possível detectar a distribuição Linux"
        exit 1
    fi
}

# Detectar versão da distribuição
detectar_versao_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${VERSION_ID:-${PRETTY_NAME:-unknown}}"
    else
        echo "unknown"
    fi
}

# Verificar se é Debian/Ubuntu ou derivada
eh_debian_like() {
    local distro="$1"
    case "$distro" in
        debian|ubuntu|linuxmint|pop|elementary|zorin|kali|parrot)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Verificar se é Fedora/RHEL/CentOS ou derivada
eh_fedora_like() {
    local distro="$1"
    case "$distro" in
        fedora|rhel|centos|rocky|alma|nobara)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Verificar se é Arch ou derivada
eh_arch_like() {
    local distro="$1"
    case "$distro" in
        arch|manjaro|endeavouros|garuda|artix)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Executar comando com tratamento de erro
executar_comando() {
    local descricao="$1"
    shift
    
    log_info "$descricao"
    if "$@"; then
        log_sucesso "$descricao concluído."
        return 0
    else
        log_erro "Falha ao executar: $descricao"
        return 1
    fi
}

# ======================================================
# DETECÇÃO DE DISTRIBUIÇÃO
# ======================================================

log_info "Iniciando a instalação da cadeia de certificados ICP-Brasil..."

DISTRO=$(detectar_distro)
VERSAO=$(detectar_versao_distro)

log_info "Distribuição detectada: $DISTRO (versão: $VERSAO)" || log_info "Distribuição detectada: $DISTRO"

# ======================================================
# INSTALAÇÃO PARA DEBIAN/UBUNTU
# ======================================================

if eh_debian_like "$DISTRO"; then
    log_info "Configurando para Debian/Ubuntu..."
    
    # Verificar e instalar repositório SERPRO se necessário
    SERPRO_REPO_FILE="/etc/apt/sources.list.d/serpro.sources"
    SERPRO_KEY_FILE="/etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc"
    
    if [ ! -f "$SERPRO_REPO_FILE" ] || [ ! -f "$SERPRO_KEY_FILE" ]; then
        log_info "Configurando repositório Assinador SERPRO..."
        
        # Baixar e instalar chave GPG
        if ! sudo test -f "$SERPRO_KEY_FILE"; then
            executar_comando "Baixando chave GPG do SERPRO" \
                wget -qO- https://assinadorserpro.estaleiro.serpro.gov.br/repository/AssinadorSERPROpublic.asc \| sudo tee "$SERPRO_KEY_FILE" > /dev/null
        fi
        
        # Configurar repositório DEB822
        if ! sudo test -f "$SERPRO_REPO_FILE"; then
            executar_comando "Configurando repositório SERPRO" \
                bash -c "echo 'Types: deb
URIs: https://www.assinadorserpro.estaleiro.serpro.gov.br/repository/
Suites: universal
Components: stable
Architectures: amd64
Signed-By: $SERPRO_KEY_FILE' | sudo tee '$SERPRO_REPO_FILE' > /dev/null"
        else
            log_aviso "Repositório SERPRO já configurado em $SERPRO_REPO_FILE"
        fi
        
        # Atualizar cache de pacotes
        executar_comando "Atualizando cache de pacotes" sudo apt-get update
    else
        log_aviso "Repositório SERPRO já configurado. Pulando configuração."
    fi
    
    # Instalar pacotes
    log_info "Instalando pacotes para Debian/Ubuntu..."
    executar_comando "Instalando ca-certificates-icp-br" \
        sudo apt-get install -y --no-install-recommends ca-certificates-icp-br || true
    
    executar_comando "Instalando assinador-serpro" \
        sudo apt-get install -y --no-install-recommends assinador-serpro || true
    
    # Instalar lacuna-webpki baixando diretamente
    log_info "Instalando lacuna-webpki..."
    LACUNA_DEB="/tmp/lacuna-webpki.deb"
    if curl -fsSL -o "$LACUNA_DEB" "https://get.webpkiplugin.com/Downloads/2.13.5/setup-deb-64"; then
        if sudo apt-get install -y "$LACUNA_DEB" 2>/dev/null; then
            log_sucesso "lacuna-webpki instalado com sucesso."
            rm -f "$LACUNA_DEB"
        else
            log_aviso "Falha ao instalar lacuna-webpki (pode já estar instalado)."
        fi
    else
        log_aviso "Falha ao baixar lacuna-webpki."
    fi

# ======================================================
# INSTALAÇÃO PARA FEDORA/RHEL/CENTOS
# ======================================================

elif eh_fedora_like "$DISTRO"; then
    log_info "Configurando para Fedora/RHEL/CentOS..."
    
    # Usar o script universal do SERPRO para Fedora
    log_info "Instalando Assinador SERPRO via script universal..."
    executar_comando "Instalando Assinador SERPRO" \
        bash -c "curl -fsSL https://assinadorserpro.estaleiro.serpro.gov.br/downloads/instalar.sh | sudo bash" || true
    
    # Instalar ca-certificates se disponível
    executar_comando "Atualizando ca-certificates" \
        sudo dnf install -y ca-certificates || true
    
    # Instalar lacuna-webpki baixando diretamente
    log_info "Instalando lacuna-webpki..."
    LACUNA_RPM="/tmp/lacuna-webpki.rpm"
    if curl -fsSL -o "$LACUNA_RPM" "https://get.webpkiplugin.com/Downloads/2.13.5/setup-rpm-64"; then
        if sudo dnf install -y "$LACUNA_RPM" 2>/dev/null; then
            log_sucesso "lacuna-webpki instalado com sucesso."
            rm -f "$LACUNA_RPM"
        else
            log_aviso "Falha ao instalar lacuna-webpki (pode já estar instalado)."
        fi
    else
        log_aviso "Falha ao baixar lacuna-webpki."
    fi

# ======================================================
# INSTALAÇÃO PARA ARCH LINUX
# ======================================================

elif eh_arch_like "$DISTRO"; then
    log_info "Configurando para Arch Linux..."
    
    # Verificar se paru ou yay estão instalados
    if command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    else
        log_aviso "Nenhum auxiliar AUR encontrado (paru/yay). Usando pacman direto."
        AUR_HELPER=""
    fi
    
    if [ -n "$AUR_HELPER" ]; then
        # Instalar via AUR
        log_info "Instalando pacotes via $AUR_HELPER..."
        
        # serpro-signer está disponível no AUR
        executar_comando "Instalando serpro-signer" \
            "$AUR_HELPER" -S --noconfirm --needed serpro-signer || true
        
        # lacuna-webpki pode estar no AUR
        executar_comando "Instalando lacuna-webpki do AUR" \
            "$AUR_HELPER" -S --noconfirm --needed lacuna-webpki || true
    else
        log_aviso "Instalação manual de AUR não suportada sem paru/yay. Pulando pacotes AUR."
    fi
    
    # Atualizar ca-certificates do repositório oficial
    executar_comando "Atualizando ca-certificates" \
        sudo pacman -Syu --noconfirm ca-certificates || true

else
    log_erro "Distribuição não suportada: $DISTRO"
    log_info "Distribuições suportadas: Arch, Ubuntu, Debian, Fedora e derivadas"
    exit 1
fi

# ======================================================
# DOWNLOAD E EXTRAÇÃO DO KEYSTORE (Universal)
# ======================================================

log_info "Processando cadeia de certificados ICP-Brasil..."

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR"

log_info "Baixando cadeia de certificados ICP-Brasil..."
if wget -c --no-check-certificate http://iti.gov.br/images/repositorio/navegadores/keystore_ICP_Brasil.jks.tar.gz -O keystore_ICP_Brasil.jks.tar.gz 2>/dev/null; then
    log_sucesso "Download concluído."
    
    log_info "Extraindo keystore..."
    if tar -xf keystore_ICP_Brasil.jks.tar.gz; then
        log_sucesso "Extração concluída."
        
        # Copiar keystore para local permanente
        if [ -f "$TEMP_DIR/keystore_ICP_Brasil.jks" ]; then
            sudo mkdir -p /opt/icp-brasil
            sudo cp "$TEMP_DIR/keystore_ICP_Brasil.jks" /opt/icp-brasil/
            log_sucesso "Keystore copiado para /opt/icp-brasil/"
        fi
    else
        log_erro "Falha na extração do keystore."
    fi
else
    log_aviso "Falha ao baixar a cadeia de certificados. Continuando com outras operações..."
fi

# ======================================================
# IMPORTAÇÃO PARA JAVA (Se disponível)
# ======================================================

# Verificar se keystore foi baixado com sucesso
KEYSTORE_SRC="/opt/icp-brasil/keystore_ICP_Brasil.jks"

if [ -f "$KEYSTORE_SRC" ]; then
    log_info "Procurando instalações Java..."
    
    JAVA_KEYSTORES=(
        "/usr/lib/jvm/java-8-openjdk/jre/lib/security/cacerts"
        "/usr/lib/jvm/java-11-openjdk/lib/security/cacerts"
        "/usr/lib/jvm/java-17-openjdk/lib/security/cacerts"
        "/usr/lib/jvm/java-21-openjdk/lib/security/cacerts"
        "/usr/lib/jvm/default/lib/security/cacerts"
    )
    SRC_PASS="12345678"
    DEST_PASS="changeit"
    
    JAVA_ENCONTRADA=false
    IMPORT_REALIZADO=false
    
    for java_keystore in "${JAVA_KEYSTORES[@]}"; do
        if [ -f "$java_keystore" ]; then
            JAVA_ENCONTRADA=true
            log_info "Importando certificados para $java_keystore..."
            
            if sudo keytool -importkeystore \
                -srckeystore "$KEYSTORE_SRC" \
                -srcstorepass "$SRC_PASS" \
                -destkeystore "$java_keystore" \
                -deststorepass "$DEST_PASS" 2>/dev/null; then
                log_sucesso "Certificados importados para $java_keystore"
                IMPORT_REALIZADO=true
            else
                log_aviso "Falha ao importar para $java_keystore (pode já estar importado)"
            fi
        fi
    done
    
    if [ "$JAVA_ENCONTRADA" = false ]; then
        log_aviso "Java não encontrado no sistema. Pulando importação de certificados."
    elif [ "$IMPORT_REALIZADO" = true ]; then
        log_sucesso "Cadeia de certificados ICP-Brasil importada com sucesso para Java."
    fi
else
    log_aviso "Keystore ICP-Brasil não encontrado. Pulando importação Java."
fi

# ======================================================
# CÓPIA DE CERTIFICADOS PERSONALIZADOS (Opcional)
# ======================================================

# Diretórios padrão para certificados personalizados
CUSTOM_CERT_SOURCES=(
    "$HOME/CertificadoDigital"
    "$HOME/Documentos/CertificadoDigital"
    "$HOME/Documents/CertificadoDigital"
    "/opt/certificados"
)

ANCHORS_DIR="/etc/ca-certificates/trust-source/anchors"
TRUST_DIR="/usr/share/ca-certificates/trust-source"

CUSTOM_CERTS_FOUND=false

for source_dir in "${CUSTOM_CERT_SOURCES[@]}"; do
    if [ -d "$source_dir" ]; then
        CUSTOM_CERTS_FOUND=true
        log_info "Encontrado diretório de certificados personalizados: $source_dir"
        
        sudo mkdir -p "$ANCHORS_DIR" "$TRUST_DIR"
        
        if [ -d "$source_dir/CertificadoDigital" ]; then
            log_info "Copiando certificados de $source_dir/CertificadoDigital..."
            sudo cp -Rf "$source_dir/CertificadoDigital/"* "$ANCHORS_DIR" 2>/dev/null && \
                log_sucesso "Certificados copiados para anchors." || \
                log_aviso "Falha ao copiar para anchors."
            
            sudo cp -Rf "$source_dir/CertificadoDigital/"* "$TRUST_DIR" 2>/dev/null && \
                log_sucesso "Certificados copiados para trust-source." || \
                log_aviso "Falha ao copiar para trust-source."
        else
            log_info "Copiando certificados de $source_dir..."
            sudo cp -Rf "$source_dir/"* "$ANCHORS_DIR" 2>/dev/null && \
                log_sucesso "Certificados copiados para anchors." || \
                log_aviso "Falha ao copiar para anchors."
            
            sudo cp -Rf "$source_dir/"* "$TRUST_DIR" 2>/dev/null && \
                log_sucesso "Certificados copiados para trust-source." || \
                log_aviso "Falha ao copiar para trust-source."
        fi
    fi
done

if [ "$CUSTOM_CERTS_FOUND" = false ]; then
    log_aviso "Nenhum diretório de certificados personalizados encontrado. Pulando cópia personalizada."
fi

# ======================================================
# ATUALIZAÇÃO DO SISTEMA DE CERTIFICADOS
# ======================================================

log_info "Atualizando cadeias de certificados do sistema..."

# Para sistemas com trust (Fedora, Arch, etc)
if command -v trust &> /dev/null; then
    executar_comando "Executando trust extract-compat" \
        sudo trust extract-compat || true
fi

# Para sistemas com update-ca-trust (RHEL/Fedora)
if command -v update-ca-trust &> /dev/null; then
    executar_comando "Executando update-ca-trust" \
        sudo update-ca-trust || true
fi

# Para sistemas com update-ca-certificates (Debian/Ubuntu)
if command -v update-ca-certificates &> /dev/null; then
    executar_comando "Executando update-ca-certificates" \
        sudo update-ca-certificates || true
fi

# ======================================================
# REMOVER AUTOSTART (Opcional)
# ======================================================

log_info "Removendo entradas de autostart desnecessárias..."

AUTOSTART_ENTRIES=(
    "/etc/xdg/autostart/SACMonitor.desktop"
    "/etc/xdg/autostart/serpro-signer.desktop"
    "$HOME/.config/autostart/SACMonitor.desktop"
    "$HOME/.config/autostart/serpro-signer.desktop"
)

for entry in "${AUTOSTART_ENTRIES[@]}"; do
    if [ -f "$entry" ]; then
        sudo rm -f "$entry" 2>/dev/null && \
            log_sucesso "Removido: $entry" || \
            log_aviso "Falha ao remover: $entry"
    fi
done

# ======================================================
# FINALIZAÇÃO
# ======================================================

log_sucesso "Instalação da cadeia ICP-Brasil concluída!"
log_info "Sistema: $DISTRO $VERSAO"
log_info "Para mais informações, visite: https://www.iti.gov.br"

exit 0
