#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/01-prepara-distro.sh
# Descrição: Prepara dependências básicas e aceleradores de pacote.
# ==============================================================================

log "INFO" "Preparando dependências do sistema..."

# 1. Dependências Universais
case "$DISTRO_FAMILY" in
    debian)
        $SUDO apt update
        $SUDO apt install -y curl git yad aria2 software-properties-common gnupg ca-certificates
        ;;
    arch)
        $SUDO pacman -Sy --noconfirm curl git yad aria2 base-devel
        ;;
    fedora)
        $SUDO dnf install -y curl git yad aria2
        ;;
esac

# 2. Configuração de Aceleradores (Paru / Apt-Fast)

# --- ARCH LINUX (Paru) ---
if [ "$DISTRO_FAMILY" == "arch" ]; then
    if ! command -v paru &>/dev/null; then
        log "INFO" "Instalando Paru (AUR Helper)..."
        # Cria diretório temporário para build
        BUILD_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/paru.git "$BUILD_DIR/paru"
        (cd "$BUILD_DIR/paru" && makepkg -si --noconfirm)
        rm -rf "$BUILD_DIR"
    fi
fi

# --- DEBIAN / UBUNTU (Apt-Fast e Apt-Smart) ---
if [ "$DISTRO_FAMILY" == "debian" ]; then
    log "INFO" "Configurando apt-fast e apt-smart..."

    # Adiciona PPA do apt-fast (Funciona em Ubuntu e Debian via Launchpad)
    if ! command -v apt-fast &>/dev/null; then
        log "INFO" "Adicionando repositório do apt-fast..."
        # Adiciona chave e repo manualmente para garantir compatibilidade Debian
        curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" | $SUDO gpg --dearmor -o /etc/apt/keyrings/apt-fast.gpg
        
        # Define codinome base (focal é safe para apt-fast no Debian Stable/Testing)
        echo "deb [signed-by=/etc/apt/keyrings/apt-fast.gpg] http://ppa.launchpad.net/apt-fast/stable/ubuntu focal main" | $SUDO tee /etc/apt/sources.list.d/apt-fast.list > /dev/null
        
        $SUDO apt update
    fi

    # Instala apt-fast (aria2 já foi instalado nas deps universais)
    $SUDO DEBIAN_FRONTEND=noninteractive apt install -y apt-fast

    # Configuração Dinâmica dos Espelhos (Sua lógica solicitada)
    log "INFO" "Aplicando configuração otimizada do apt-fast..."
    
    if [ "$DISTRO_NAME" == "ubuntu" ]; then
        MIRRORS_LIST="http://archive.ubuntu.com/ubuntu, http://ftp.osuosl.org/pub/ubuntu, http://mirror.leaseweb.com/ubuntu"
    else
        # Debian Brasil + Global
        MIRRORS_LIST="http://ftp.br.debian.org/debian, http://debian.c3sl.ufpr.br/debian, http://deb.debian.org/debian, http://ftp.us.debian.org/debian"
    fi

    # Cria arquivo de configuração
    $SUDO tee /etc/apt-fast.conf > /dev/null <<EOF
MIRRORS=( '$MIRRORS_LIST' )
_MAXNUM=5
_SPLITCON=8
_MINSPLITSZ=1M
_DOWNLOADER="aria2c -c -j \${_MAXNUM} -s \${_SPLITCON} -x \${_SPLITCON} -i \${DLLIST} --min-split-size=\${_MINSPLITSZ}"
DOWNLOADBEFORE=true
EOF

    # Cria o Wrapper apt-smart
    log "INFO" "Criando wrapper apt-smart..."
    cat <<'EOF' | $SUDO tee /usr/local/bin/apt-smart > /dev/null
#!/bin/bash
if command -v apt-fast >/dev/null; then
  sudo DEBIAN_FRONTEND=noninteractive apt-fast "$@"
else
  sudo DEBIAN_FRONTEND=noninteractive apt "$@"
fi
EOF
    $SUDO chmod +x /usr/local/bin/apt-smart
    
    log "SUCCESS" "Apt-fast e Apt-smart configurados."
fi

log "SUCCESS" "Preparação de ambiente concluída."