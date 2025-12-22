#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/12-pack-certificates.sh
# Versão: 1.0.0
# Descrição: Instalação de certificados digitais e ferramentas ICP-Brasil
# Suporta: Arch Linux, Debian/Ubuntu, Fedora
# ==============================================================================

# --- CARREGA VARIÁVEIS GLOBAIS ---
# Espera que core/env.sh já tenha sido carregado
# Variáveis esperadas: SUDO, DISTRO_FAMILY, REAL_USER, BASE_DIR

# ==============================================================================
# FUNÇÃO: Instalar Certificados
# ==============================================================================
install_certificates() {
    log "STEP" "Instalando certificados digitais ICP-Brasil..."
    
    # Diretório de certificados (ajustar conforme necessário)
    local CERT_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/config/CertificadoDigital"
    
    # Verifica se diretório de certificados existe
    if [ ! -d "$CERT_DIR" ]; then
        log "WARN" "Diretório de certificados não encontrado: $CERT_DIR"
        log "WARN" "Pulando instalação de certificados"
        return 0
    fi
    
    log "INFO" "Copiando certificados para o sistema..."
    
    case "$DISTRO_FAMILY" in
        debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
            # Debian/Ubuntu: /etc/ssl/certs
            local ANCHORS_DIR="/etc/ssl/certs"
            $SUDO mkdir -p "$ANCHORS_DIR"
            
            # Copia certificados (crt, pem, cer)
            for ext in crt pem cer; do
                $SUDO cp -v "$CERT_DIR"/*."$ext" "$ANCHORS_DIR/" 2>/dev/null || true
                $SUDO cp -v "$CERT_DIR"/CertificadoDigital/*."$ext" "$ANCHORS_DIR/" 2>/dev/null || true
            done
            
            # Atualiza cadeia de certificados
            log "INFO" "Atualizando cadeia de certificados..."
            $SUDO update-ca-certificates 2>/dev/null || true
            ;;
            
        arch|manjaro|endeavouros|biglinux)
            # Arch: /etc/ca-certificates/trust-source/anchors
            local ANCHORS_DIR="/etc/ca-certificates/trust-source/anchors"
            $SUDO mkdir -p "$ANCHORS_DIR"
            
            # Copia certificados
            for ext in crt pem cer; do
                $SUDO cp -v "$CERT_DIR"/*."$ext" "$ANCHORS_DIR/" 2>/dev/null || true
                $SUDO cp -v "$CERT_DIR"/CertificadoDigital/*."$ext" "$ANCHORS_DIR/" 2>/dev/null || true
            done
            
            # Atualiza cadeia de certificados
            log "INFO" "Atualizando cadeia de certificados..."
            $SUDO trust extract-compat 2>/dev/null || true
            ;;
            
        fedora|redhat|almalinux|nobara)
            # Fedora: /etc/pki/ca-trust/source/anchors
            local ANCHORS_DIR="/etc/pki/ca-trust/source/anchors"
            $SUDO mkdir -p "$ANCHORS_DIR"
            
            # Copia certificados
            for ext in crt pem cer; do
                $SUDO cp -v "$CERT_DIR"/*."$ext" "$ANCHORS_DIR/" 2>/dev/null || true
                $SUDO cp -v "$CERT_DIR"/CertificadoDigital/*."$ext" "$ANCHORS_DIR/" 2>/dev/null || true
            done
            
            # Atualiza cadeia de certificados
            log "INFO" "Atualizando cadeia de certificados..."
            $SUDO update-ca-trust extract 2>/dev/null || true
            ;;
    esac
    
    log "SUCCESS" "✓ Certificados instalados"
}

# ==============================================================================
# FUNÇÃO: Instalar Dependências de Token/Smartcard
# ==============================================================================
install_smartcard_tools() {
    log "STEP" "Instalando ferramentas de token/smartcard..."
    
    case "$DISTRO_FAMILY" in
        debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
            log "INFO" "Instalando pcsc-lite, opensc..."
            $SUDO apt install -y pcsc-lite opensc pcscd 2>/dev/null || true
            ;;
            
        arch|manjaro|endeavouros|biglinux)
            log "INFO" "Instalando pcsc-lite, opensc..."
            $SUDO pacman -S --noconfirm pcsc-lite opensc 2>/dev/null || true
            ;;
            
        fedora|redhat|almalinux|nobara)
            log "INFO" "Instalando pcsc-lite, opensc..."
            $SUDO dnf install -y pcsc-lite pcsc-lite-ccid opensc 2>/dev/null || true
            ;;
    esac
    
    log "SUCCESS" "✓ Ferramentas de token/smartcard instaladas"
}

# ==============================================================================
# FUNÇÃO: Instalar Assinador SERPRO (Debian/Ubuntu)
# ==============================================================================
install_serpro() {
    log "STEP" "Instalando Assinador SERPRO..."
    
    case "$DISTRO_FAMILY" in
        debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
            log "INFO" "Adicionando repositório SERPRO..."
            
            # Adiciona chave GPG
            if wget -qO- https://assinadorserpro.estaleiro.serpro.gov.br/repository/AssinadorSERPROpublic.asc 2>/dev/null | \
               $SUDO tee /etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc > /dev/null; then
                log "SUCCESS" "✓ Chave GPG adicionada"
            else
                log "WARN" "⚠ Falha ao adicionar chave GPG do SERPRO"
                return 1
            fi
            
            # Adiciona repositório
            if echo "Types: deb
URIs: https://www.assinadorserpro.estaleiro.serpro.gov.br/repository/
Suites: universal
Components: stable
Architectures: amd64
Signed-By: /etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc" | \
               $SUDO tee /etc/apt/sources.list.d/serpro.sources > /dev/null; then
                log "SUCCESS" "✓ Repositório SERPRO adicionado"
            else
                log "WARN" "⚠ Falha ao adicionar repositório SERPRO"
                return 1
            fi
            
            # Atualiza lista de pacotes
            log "INFO" "Atualizando lista de pacotes..."
            $SUDO apt update 2>/dev/null || true
            
            # Instala assinador
            log "INFO" "Instalando assinador-serpro..."
            if $SUDO apt install -y assinador-serpro 2>/dev/null; then
                log "SUCCESS" "✓ Assinador SERPRO instalado"
            else
                log "WARN" "⚠ Falha ao instalar assinador-serpro"
                return 1
            fi
            ;;
            
        arch|manjaro|endeavouros|biglinux)
            log "INFO" "Instalando assinador-serpro do AUR..."
            
            # Verifica se yay ou paru estão disponíveis
            if command -v yay &>/dev/null; then
                yay -S --noconfirm serpro-signer serproid 2>/dev/null || true
                log "SUCCESS" "✓ Assinador SERPRO instalado (yay)"
            elif command -v paru &>/dev/null; then
                paru -S --noconfirm assinador-serpro 2>/dev/null || true
                log "SUCCESS" "✓ Assinador SERPRO instalado (paru)"
            else
                log "WARN" "⚠ yay ou paru não encontrados. Instale manualmente: yay -S assinador-serpro"
            fi
            ;;
            
        fedora|redhat|almalinux|nobara)
            log "WARN" "⚠ Assinador SERPRO não está disponível para Fedora"
            log "WARN" "⚠ Você pode usar alternativas como LibreOffice ou ferramentas web"
            ;;
    esac
}

# ==============================================================================
# FUNÇÃO: Instalar PyHanko (Opcional)
# ==============================================================================
install_pyhanko() {
    log "STEP" "Instalando PyHanko (assinatura PDF)..."
    
    # Verifica se pipx está disponível
    if ! command -v pipx &>/dev/null; then
        log "WARN" "pipx não encontrado. Instalando..."
        
        case "$DISTRO_FAMILY" in
            debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
                $SUDO apt install -y python3-pip 2>/dev/null || true
                ;;
            arch|manjaro|endeavouros|biglinux)
                $SUDO pacman -S --noconfirm python-pip 2>/dev/null || true
                ;;
            fedora|redhat|almalinux|nobara)
                $SUDO dnf install -y python3-pip 2>/dev/null || true
                ;;
        esac
        
        # Instala pipx
        python3 -m pip install --user pipx 2>/dev/null || true
    fi
    
    # Instala PyHanko
    if command -v pipx &>/dev/null; then
        log "INFO" "Instalando pyHanko com suporte completo..."
        if pipx install 'pyHanko[pkcs11,image-support,opentype,xmp]' 2>/dev/null; then
            log "SUCCESS" "✓ PyHanko instalado"
            
            # Cria link simbólico
            if [ ! -f /usr/local/bin/pyhanko ]; then
                $SUDO ln -sf "$HOME/.local/bin/pyhanko" /usr/local/bin/pyhanko 2>/dev/null || true
            fi
        else
            log "WARN" "⚠ Falha ao instalar PyHanko"
        fi
    else
        log "WARN" "⚠ pipx não disponível. PyHanko não será instalado"
    fi
}

# ==============================================================================
# FUNÇÃO: Pós-Instalação de Certificados
# ==============================================================================
post_install_certificates() {
    log "INFO" "Executando pós-instalação de certificados..."
    
    # Inicia serviço pcscd (se disponível)
    if command -v systemctl &>/dev/null; then
        log "INFO" "Iniciando serviço pcscd..."
        $SUDO systemctl enable pcscd 2>/dev/null || true
        $SUDO systemctl start pcscd 2>/dev/null || true
    fi
    
    log "SUCCESS" "✓ Pós-instalação de certificados concluída"
}

# ==============================================================================
# EXECUÇÃO PRINCIPAL
# ==============================================================================

# Verifica se core/env.sh foi carregado
if [ -z "$SUDO" ]; then
    log "ERROR" "Variáveis globais não carregadas. Execute core/env.sh primeiro."
    exit 1
fi

log "STEP" "Configurando certificados digitais e ferramentas ICP-Brasil..."

# 1. Instala certificados
install_certificates

# 2. Instala ferramentas de token/smartcard
install_smartcard_tools

# 3. Instala Assinador SERPRO (se aplicável)
install_serpro

# 4. Instala PyHanko (opcional)
# Descomente se desejar instalar automaticamente
# install_pyhanko

# 5. Pós-instalação
post_install_certificates

log "SUCCESS" "✓ Certificados digitais e ferramentas configurados com sucesso!"
