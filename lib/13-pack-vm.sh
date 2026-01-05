#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/13-pack-vm.sh
# Versão: 1.0.0
#
# Descrição: Instalação e Otimização do VirtualBox.
# 1. Instala pacotes base e headers do kernel.
# 2. Instala/Configura o Extension Pack (com aceite de licença automático).
# 3. Adiciona usuário ao grupo vboxusers (USB support).
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando configuração de Virtualização (VirtualBox)..."

# 1. Instalação de Dependências e Pacotes Base
log "INFO" "Instalando VirtualBox e módulos do kernel..."

case "$DISTRO_FAMILY" in
    debian)
        # Prepara aceite de licença para o Extension Pack (Debian/Ubuntu)
        # Isso evita que o apt trave pedindo confirmação interativa
        echo virtualbox-ext-pack virtualbox-ext-pack/license select true | $SUDO debconf-set-selections

        # Instala VirtualBox, DKMS (compilação de módulos) e Extension Pack
        i virtualbox virtualbox-dkms virtualbox-ext-pack build-essential dkms linux-headers-$(uname -r)
        ;;

    arch)
        # No Arch, precisamos decidir entre módulos pré-compilados ou DKMS.
        # DKMS é mais seguro se você mudar de kernel (LTS/Zen).
        i virtualbox virtualbox-host-dkms virtualbox-guest-iso linux-headers dkms

        # Extension Pack no Arch geralmente é via AUR (virtualbox-ext-oracle).
        # Se o 'i' (paru) estiver configurado, ele resolve.
        if command -v paru &>/dev/null; then
            i virtualbox-ext-oracle
        else
            log "WARN" "Paru não detectado. Extension Pack deve ser instalado manualmente no Arch."
        fi
        ;;

    fedora)
        # Fedora geralmente requer RPMFusion (já configurado no 02-setup-repos.sh)
        i VirtualBox akmod-VirtualBox kernel-devel

        # Recompila módulos
        $SUDO akmods
        ;;
esac

# 2. Configuração de Permissões (Crítico para USB)
log "INFO" "Configurando permissões de usuário..."

# Cria grupo se não existir
if ! getent group vboxusers > /dev/null; then
    $SUDO groupadd vboxusers
fi

# Adiciona usuário
if ! groups "$REAL_USER" | grep -q "\bvboxusers\b"; then
    $SUDO usermod -aG vboxusers "$REAL_USER"
    log "SUCCESS" "Usuário $REAL_USER adicionado ao grupo 'vboxusers'."
else
    log "INFO" "Usuário já pertence ao grupo vboxusers."
fi

# 3. Carregamento de Módulos
log "INFO" "Carregando módulos do kernel..."
$SUDO modprobe vboxdrv 2>/dev/null
$SUDO modprobe vboxnetflt 2>/dev/null
$SUDO modprobe vboxnetadp 2>/dev/null

# 4. Verificação
if systemctl list-unit-files | grep -q vboxdrv; then
    $SUDO systemctl enable --now vboxdrv
fi

log "SUCCESS" "VirtualBox configurado. Reinicie a sessão para ativar o suporte USB."
