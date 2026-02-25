#!/bin/bash
# ==============================================================================
# Script: install-essentials.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Instalar pacotes e aplicativos essenciais do sistema
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Instala pacotes base obrigatórios:
# 1. Paru (AUR helper para Arch Linux, se PREFER_NATIVE=true)
# 2. Ferramentas de desenvolvimento (build-essential, git, etc)
# 3. Utilitários de sistema (duf, eza, jq, etc)
# 4. Compactadores (7zip, unrar, arj, etc)
# 5. Sistema de impressão (CUPS e drivers)
# 6. Outros essenciais (imagemagick, speech-dispatcher, etc)
#
# Este script é OBRIGATÓRIO e deve ser executado antes de qualquer outro.
#
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# VALIDAÇÃO INICIAL
# ==============================================================================

if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$(dirname "$0")/../lib/detect-system.sh" || die "Falha ao detectar sistema"
fi

section "Instalação de Pacotes Essenciais"

# ==============================================================================
# INSTALAÇÃO POR DISTRIBUIÇÃO
# ==============================================================================

case "$DISTRO_FAMILY" in
    
    # ========== DEBIAN / UBUNTU ==========
    debian)
        log "STEP" "Instalando pacotes essenciais para Debian/Ubuntu..."
        
        # Atualiza índices de pacotes
        log "INFO" "Atualizando índices de pacotes..."
        $SUDO apt update || log "WARN" "Falha ao atualizar índices"
        
        # Instala pacotes essenciais em lotes
        debian_packages=(
            # Interface gráfica para diálogos
            "zenity" "yad"
            
            # Desenvolvimento
            "build-essential" "git" "ccache" "pipx" "jq"
            
            # Utilitários de sistema
            "curl" "wget" "duf" "eza" "bat" "bash-completion" "rsync"
            
            # Compactadores
            "exfatprogs" "arj" "p7zip-full" "unrar" "zip" "unzip"
            
            # Editores e terminais
            "guake" "geany" "geany-plugins"
            
            # Compressão de RAM
            "zram-tools"
            
            # Processamento de imagem
            "imagemagick"
            
            # Sistema de impressão
            "cups" "cups-client" "cups-bsd" "cups-filters"
            "foomatic-db-compressed-ppds" "openprinting-ppds"
            "hplip" "printer-driver-hpcups" "printer-driver-hpijs"
            "hpijs-ppds" "printer-driver-escpr" "printer-driver-gutenprint"
            "escputil" "printer-driver-cjet" "cups-backend-bjnp"
            "printer-driver-brlaser" "printer-driver-ptouch" "printer-driver-splix"
            "printer-driver-all"
            
            # Internet
            "rclone"
            
            # Acessibilidade
            "speech-dispatcher"
        )
        
        # Instala cada pacote (continua mesmo se alguns falharem)
        for pkg in "${debian_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    
    # ========== ARCH LINUX ==========
    arch)
        log "STEP" "Instalando pacotes essenciais para Arch Linux..."
        
        # Instala Paru se preferir nativo
        if [ "$PREFER_NATIVE" = "true" ] && ! command -v paru &>/dev/null; then
            log "STEP" "Instalando Paru (AUR helper)..."
            
            # Verifica pré-requisitos
            if ! command -v git &>/dev/null; then
                log "INFO" "Git não está instalado, instalando..."
                $SUDO pacman -S --noconfirm git || log "WARN" "Falha ao instalar Git"
            fi
            
            if ! pacman -Qi base-devel &>/dev/null; then
                log "INFO" "base-devel não está instalado, instalando..."
                $SUDO pacman -S --noconfirm base-devel || log "WARN" "Falha ao instalar base-devel"
            fi
            
            # Instala Paru
            TEMP_DIR=$(mktemp -d)
            trap "rm -rf $TEMP_DIR" EXIT
            
            cd "$TEMP_DIR" || die "Falha ao criar diretório temporário"
            
            log "INFO" "Clonando repositório Paru..."
            git clone https://aur.archlinux.org/paru.git 2>/dev/null || log "WARN" "Falha ao clonar Paru"
            
            if [ -d "paru" ]; then
                cd paru || die "Falha ao entrar no diretório paru"
                log "INFO" "Compilando Paru (isso pode levar alguns minutos)..."
                makepkg -si --noconfirm 2>/dev/null || log "WARN" "Falha ao compilar Paru"
                
                # Verifica se Paru foi instalado com sucesso
                if command -v paru &>/dev/null; then
                    log "SUCCESS" "Paru instalado com sucesso"
                else
                    log "WARN" "Paru pode nao estar no PATH. Tente executar: source /etc/profile"
                fi
            fi
        elif [ "$PREFER_NATIVE" = "true" ] && command -v paru &>/dev/null; then
            paru_version=$(paru --version | head -1)
            log "SUCCESS" "Paru ja esta instalado: $paru_version"
        fi
        
        # Instala pacotes essenciais
        arch_packages=(
            # Interface gráfica para diálogos
            "zenity" "yad"
            
            # Desenvolvimento
            "linux-tools" "kexec-tools" "git" "ccache" "python-pipx" "jq"
            
            # Utilitários de sistema
            "curl" "wget" "duf" "eza" "bat" "acpi" "bc" "rsync"
            "lsb-release" "bchunk" "ntfs-3g" "bash-completion"
            
            # Editores e terminais
            "guake" "geany" "geany-plugins"
            
            # Compactadores
            "exfatprogs" "arj" "p7zip" "unrar"
            
            # Sistema de impressão
            "cups" "cups-pdf" "cups-browsed"
            "gutenprint" "foomatic-db-engine" "foomatic-db"
            "foomatic-db-nonfree" "foomatic-db-ppds"
            "foomatic-db-nonfree-ppds" "foomatic-db-gutenprint-ppds"
            "epson-inkjet-printer-escpr" "cnijfilter2" "scangearmp2"
            "samsung-unified-driver" "samsung-ml2160"
            "cnrdrvcups-lb" "cups-bjnp"
            
            # Processamento de imagem
            "imagemagick"
            
            # Acessibilidade
            "speech-dispatcher"
            
            # Utilitários
            "reflector"

            # Internet
            "rclone"
            
            # Nota: Paru é instalado acima se PREFER_NATIVE=true
        )
        
        # Instala cada pacote
        for pkg in "${arch_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    
    # ========== FEDORA ==========
    fedora)
        log "STEP" "Instalando pacotes essenciais para Fedora..."
        
        # Instala pacotes essenciais
        fedora_packages=(
            # Interface gráfica para diálogos
            "zenity" "yad"
            
            # Desenvolvimento
            "git" "ccache" "python3-pip" "jq"
            
            # Utilitários de sistema
            "curl" "wget" "duf" "eza" "exa" "bat" "thefuck"
            "exfatprogs" "bash-completion" "rsync"
            
            # Editores e terminais
            "guake" "geany" "geany-plugins"
            
            # Compactadores
            "arj" "p7zip" "p7zip-plugins" "unrar"
            
            # Sistema de impressão
            "cups-pdf" "gutenprint" "hplip" "hplip-gui"
            "escputil"
            
            # Processamento de imagem
            "imagemagick"
            
            # Dicionários
            "aspell-pt" "aspell-pt_BR" "ibrazilian"
            "translate-shell" "hyphen-pt" "hunspell-pt_BR"
            "man-pages-pt_BR" "hunspell-en_AU" "hunspell-en_CA"
            "hunspell-en_ZA" "hyphen-en"
            
            # Internet
            "rclone"
            
            # Acessibilidade
            "speech-dispatcher"
        )
        
        # Instala cada pacote
        for pkg in "${fedora_packages[@]}"; do
            i "$pkg" || log "WARN" "Falha ao instalar: $pkg"
        done
        ;;
    
    *)
        die "Distribuição não suportada: $DISTRO_FAMILY"
        ;;
esac

# ==============================================================================
# CONFIGURAÇÃO DO CUPS (IMPRESSÃO)
# ==============================================================================

log "STEP" "Configurando sistema de impressão (CUPS)..."

# Cria backup da configuração original
if [ -f /etc/cups/cupsd.conf ]; then
    $SUDO cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.bak
    log "INFO" "Backup de cupsd.conf criado"
fi

# Copia configuração padrão se existir
if [ -f "$CONFIGS_DIR/cupsd.conf" ]; then
    $SUDO cp "$CONFIGS_DIR/cupsd.conf" /etc/cups/cupsd.conf
    log "INFO" "Configuração CUPS restaurada"
fi

# Configura cups-browsed
if [ -f /etc/cups/cups-browsed.conf ]; then
    $SUDO cp /etc/cups/cups-browsed.conf /etc/cups/cups-browsed.conf.bak
    echo 'BrowseRemoteProtocols none' | $SUDO tee /etc/cups/cups-browsed.conf > /dev/null
    log "INFO" "cups-browsed configurado"
fi

# Define tamanho padrão do papel como A4
echo "a4" | $SUDO tee /etc/papersize > /dev/null

# Reinicia e habilita CUPS
$SUDO systemctl restart cups 2>/dev/null || true
$SUDO systemctl enable --now cups 2>/dev/null || true

log "SUCCESS" "CUPS configurado e ativado"

# ==============================================================================
# VERIFICAÇÃO FINAL
# ==============================================================================

log "STEP" "Verificando instalação..."

# Verifica se pacotes críticos foram instalados
critical_packages=("git" "curl" "sudo")
missing_packages=()

for pkg in "${critical_packages[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        missing_packages+=("$pkg")
    fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
    log "WARN" "Pacotes críticos não instalados: ${missing_packages[*]}"
else
    log "SUCCESS" "Todos os pacotes críticos foram instalados"
fi

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

section "Pacotes Essenciais Instalados"
log "SUCCESS" "Instalação de pacotes essenciais concluída!"
log "INFO" "O sistema está pronto para a próxima etapa de configuração."
