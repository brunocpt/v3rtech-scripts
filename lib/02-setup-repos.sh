#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/02-setup-repos.sh
# Versão: 2.0.0
#
# Descrição: Configura repositórios de sistema e de terceiros.
# Apenas ativa repositórios de terceiros se o app correspondente estiver marcado
# como TRUE na lista de instalação (data/apps.csv).
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando configuração de repositórios..."

# ==============================================================================
# FUNÇÕES UTILITÁRIAS (Debian/Ubuntu/Fedora)
# ==============================================================================

# Adiciona chave GPG (Debian/Ubuntu)
add_gpg_key() {
    local url="$1"
    local keyring_path="$2"

    # Baixa apenas se não existir ou se forçar update
    if [ ! -f "$keyring_path" ]; then
        curl -fsSL "$url" | gpg --dearmor | $SUDO tee "$keyring_path" > /dev/null
    fi
}

# Cria arquivo .sources (Formato Deb822 moderno)
add_deb_source() {
    local filename="$1"
    local content="$2"
    echo "$content" | $SUDO tee "/etc/apt/sources.list.d/$filename" > /dev/null
}

# Verifica se um app está ativo para instalação
is_app_active() {
    local app_name="$1"
    # Procura no CSV se a linha começa com TRUE e contém o nome
    # O grep retornado 0 se achar, 1 se não.
    grep -q "^TRUE|.*|$app_name|" "$DATA_DIR/apps.csv"
}

# ==============================================================================
# LÓGICA ESPECÍFICA: FEDORA
# ==============================================================================
setup_fedora_repos() {
    log "INFO" "Configurando repositórios Fedora..."
    local fedora_ver=$(rpm -E %fedora)

    # 1. RPM Fusion (Free e Non-Free)
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        log "INFO" "Instalando RPM Fusion..."
        $SUDO dnf install -y --skip-unavailable \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"
    fi

    # 2. Codecs e Drivers (Nvidia / Broadcom)
    log "INFO" "Atualizando grupos de Multimídia e Drivers..."
    $SUDO dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    $SUDO dnf groupupdate -y sound-and-video

    # Nvidia (Verifica hardware detectado no 00-detecta)
    if [[ "$GPU_VENDOR" == "nvidia" ]]; then
        $SUDO dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    fi

    # 3. Repos de Terceiros (Condicional)

    # VS Code
    if is_app_active "VS Code"; then
        $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
        $SUDO sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    fi

    # Microsoft Edge
    if is_app_active "Microsoft Edge"; then
        $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
        $SUDO sh -c 'echo -e "[microsoft-edge]\nname=Microsoft Edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/microsoft-edge.repo'
    fi

    # Google Chrome
    if is_app_active "Google Chrome"; then
        $SUDO dnf install -y fedora-workstation-repositories
        $SUDO dnf config-manager --set-enabled google-chrome
    fi

    # Brave
    if is_app_active "Brave"; then
        $SUDO dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
        $SUDO rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    fi

    # Antigravity (Fedora) - Placeholder, pois URL exata do repo yum não foi fornecida
    if is_app_active "Antigravity"; then
        log "WARN" "Instalação do Antigravity no Fedora requer download manual do RPM por enquanto."
        # Se tiver a URL do .repo do antigravity, adicionamos aqui.
    fi

    $SUDO dnf makecache
}

# ==============================================================================
# LÓGICA ESPECÍFICA: DEBIAN / UBUNTU
# ==============================================================================
setup_debian_repos() {
    log "INFO" "Configurando repositórios Debian/Ubuntu..."

    # --- 1. Modernização do Sources (Apenas Debian Puro) ---
    if [[ "$DISTRO_NAME" == "debian" ]]; then
        # Implementação baseada no seu script 'up-sources-debian.sh'
        if [ -f "/etc/apt/sources.list" ]; then
             log "INFO" "Modernizando sources.list para formato deb822..."
             # (Lógica simplificada para não apagar tudo se já foi rodado)
             # Movemos o antigo apenas se o novo não existir
             if [ ! -f "/etc/apt/sources.list.d/debian.sources" ]; then
                 $SUDO mv /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F)
                 $SUDO touch /etc/apt/sources.list

                 # Detecta versão (bookworm/trixie)
                 DEB_CODENAME="${VERSION_CODENAME:-stable}"

                 add_deb_source "debian.sources" "Types: deb
URIs: http://deb.debian.org/debian/
Suites: $DEB_CODENAME ${DEB_CODENAME}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: ${DEB_CODENAME}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg"
             fi
        fi
    fi

    # --- 2. Repositórios de Apps de Terceiros (Condicional) ---

    # Google Chrome
    if is_app_active "Google Chrome"; then
        add_gpg_key "https://dl.google.com/linux/linux_signing_key.pub" "/etc/apt/keyrings/google-chrome.gpg"
        add_deb_source "google-chrome.sources" "Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/google-chrome.gpg"
    fi

    # Microsoft Edge
    if is_app_active "Microsoft Edge"; then
        add_gpg_key "https://packages.microsoft.com/keys/microsoft.asc" "/usr/share/keyrings/microsoft.gpg"
        add_deb_source "microsoft-edge.sources" "Types: deb
URIs: https://packages.microsoft.com/repos/edge/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg"
    fi

    # VS Code
    if is_app_active "VS Code"; then
        add_gpg_key "https://packages.microsoft.com/keys/microsoft.asc" "/usr/share/keyrings/microsoft.gpg"
        add_deb_source "vscode.sources" "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg"
    fi

    # Wavebox
    if is_app_active "Wavebox"; then
        add_gpg_key "https://download.wavebox.app/static/wavebox_repo.key" "/etc/apt/keyrings/wavebox.gpg"
        add_deb_source "wavebox.sources" "Types: deb
URIs: https://download.wavebox.app/stable/linux/deb/
Suites: amd64/
Components:
Architectures: amd64
Signed-By: /etc/apt/keyrings/wavebox.gpg"
    fi

    # Vivaldi
    if is_app_active "Vivaldi"; then
        add_gpg_key "https://repo.vivaldi.com/stable/linux_signing_key.pub" "/etc/apt/keyrings/vivaldi.gpg"
        add_deb_source "vivaldi.sources" "Types: deb
URIs: http://repo.vivaldi.com/stable/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/vivaldi.gpg"
    fi

    # Brave
    if is_app_active "Brave"; then
        add_gpg_key "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" "/usr/share/keyrings/brave-browser-archive-keyring.gpg"
        add_deb_source "brave-browser-release.sources" "Types: deb
URIs: https://brave-browser-apt-release.s3.brave.com
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/brave-browser-archive-keyring.gpg"
    fi

    # Antigravity (Google)
    if is_app_active "Antigravity"; then
        add_gpg_key "https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg" "/etc/apt/keyrings/antigravity-repo-key.gpg"
        add_deb_source "antigravity.sources" "Types: deb
URIs: https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/
Suites: antigravity-debian
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/antigravity-repo-key.gpg"
    fi

    # Assinador SERPRO
    # (Adicionado sempre se for distro Debian/Ubuntu pois é utilitário gov)
    add_gpg_key "https://assinadorserpro.estaleiro.serpro.gov.br/repository/AssinadorSERPROpublic.asc" "/etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc"
    add_deb_source "serpro.sources" "Types: deb
URIs: https://www.assinadorserpro.estaleiro.serpro.gov.br/repository/
Suites: universal
Components: stable
Architectures: amd64
Signed-By: /etc/apt/trusted.gpg.d/AssinadorSERPROpublic.asc"

    # Atualiza caches
    log "INFO" "Atualizando apt cache..."
    $SUDO apt-get update
}

# ==============================================================================
# CHAMADA PRINCIPAL
# ==============================================================================

case "$DISTRO_FAMILY" in
    fedora)
        setup_fedora_repos
        ;;
    debian)
        setup_debian_repos
        ;;
    arch)
        log "INFO" "Arch Linux: Repositórios são gerenciados via Pacman/AUR (Paru). Pulando setup de repos externos."
        ;;
    *)
        log "WARN" "Família de distro desconhecida para configuração de repositórios: $DISTRO_FAMILY"
        ;;
esac

log "SUCCESS" "Configuração de repositórios concluída."
