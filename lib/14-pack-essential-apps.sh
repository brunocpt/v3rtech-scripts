#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/14-pack-essential-apps.sh
# Versão: 1.0.0
#
# Descrição: Instalação de pacotes e aplicativos essenciais
# 1. Instala pacotes base e headers do kernel.
# 2. Instala e habilita impressão.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando a instalação de pacotes essenciais..."

# 1. Instalação de Dependências e Pacotes Base
log "INFO" "pacotes básicos do sistema..."

case "$DISTRO_FAMILY" in
    debian)
        for pkg in \
          build-essential \
          git \
          ccache \
          pipx \
          jq \
          exfatprogs \
          arj \
          p7zip-full \
          unrar \
          guake \
          duf \
          eza \
          geany geany-plugins \
          zram-tools \
          imagemagick \
          cups \
          cups-client \
          cups-bsd \
          cups-filters \
          foomatic-db-compressed-ppds \
          openprinting-ppds \
          hplip \
          printer-driver-hpcups \
          printer-driver-hpijs \
          hpijs-ppds \
          printer-driver-escpr \
          printer-driver-gutenprint \
          escputil \
          printer-driver-cjet \
          cups-backend-bjnp \
          printer-driver-brlaser \
          printer-driver-ptouch \
          printer-driver-m2300w \
          printer-driver-all \
          exfatprogs \
          ; do
          i "$pkg"  || echo "Falha ao instalar $pkg"
        done
        ;;

    arch)
        for pkg in \
          linux-tools \
          kexec-tools \
          ntfs-3g \
          exa \
          eza \
          bat \
          duf \
          acpi \
          bc \
          cups \
          cups-pdf \
          cups-browsed \
          python-pipx \
          lsb-release \
          bchunk \
          guake \
          geany geany-plugins \
          jq \
          gutenprint \
          foomatic-db-engine \
          foomatic-db \
          foomatic-db-nonfree \
          foomatic-db-ppds \
          foomatic-db-nonfree-ppds \
          foomatic-db-gutenprint-ppds \
          epson-inkjet-printer-escpr \
          cnijfilter2 \
          scangearmp2 \
          cnrdrvcups-lb \
          cups-bjnp \
          exfatprogs \
          ; do
          i "$pkg"  || echo "Falha ao instalar $pkg"
        done
        ;;

    fedora)
        for pkg in \
          cups-pdf exfatprogs jq git ccache pipx \
          gutenprint hplip hplip-gui escputil \
          arj p7zip p7zip-plugins unrar \
          geany geany-plugins grsync \
          aspell-pt aspell-pt_BR ibrazilian \
          translate-shell \
          hyphen-pt hunspell-pt_BR man-pages-pt_BR \
          hunspell-en_AU hunspell-en_CA hunspell-en_ZA \
          hyphen-en \
          bat thefuck \
          duf eza exa \
          exfatprogs \
          ; do
          i "$pkg"  || echo "Falha ao instalar $pkg"
        done
        ;;
esac

# 2. Habilitando serviços essenciais
log "INFO" "Habilitando serviços essenciais..."

# ========== CONFIGURAÇÃO DO CUPS ==========
echo "Configurando CUPS..."
sudo mv /etc/cups/cupsd.conf /etc/cups/cupsd.conf.orig 2>/dev/null
sudo cp /usr/local/share/scripts/v3rtech-scripts/configs/cupsd.conf /etc/cups/cupsd.conf

sudo mv /etc/cups/cups-browsed.conf /etc/cups/cups-browsed.conf.orig 2>/dev/null
echo 'BrowseRemoteProtocols none' | sudo tee /etc/cups/cups-browsed.conf > /dev/null

echo -e "# Tamanho padrão do papel: A4\na4" | sudo tee /etc/papersize > /dev/null

sudo systemctl restart cups
sudo systemctl enable --now cups
echo "CUPS configurado e ativado."
log "INFO" "CUPS configurado e ativado."

log "SUCCESS" "Pacotes essenciais instalados e configurados."
