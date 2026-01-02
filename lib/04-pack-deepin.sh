#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-deepin.sh
# Descrição: Instalação do Deepin Desktop Environment (DDE)
# ==============================================================================

log "INFO" "Iniciando configuração do Deepin Desktop..."

# 1. Instalação de Pacotes
PKGS_DEEPIN=(
    "deepin"           # Meta-pacote base
    "deepin-extra"     # Apps extras
    "lightdm"          # Display Manager recomendado
    "ulauncher"        # Launcher adicional
)

# No Arch, o grupo deepin instala muita coisa.
# O 'i' abstrai isso, mas a instalação pode ser longa.
i "${PKGS_DEEPIN[@]}"

# 2. Configuração do Display Manager (LightDM)
log "INFO" "Habilitando LightDM..."

# Verifica se o lightdm foi instalado corretamente
if command -v lightdm &>/dev/null; then
    # Habilita o serviço. Se outro DM (GDM/SDDM) estiver ativo, pode haver conflito.
    # O ideal seria desabilitar outros antes, mas o systemctl -f costuma lidar com o link.
    $SUDO systemctl enable --now lightdm.service
else
    log "WARN" "LightDM não encontrado. O login gráfico pode não funcionar automaticamente."
fi

# 3. Configurações Específicas
# O Deepin usa dconf, mas suas configs padrão já são muito polidas.
# Se tiver configs específicas de dconf dump, adicione aqui.

log "SUCCESS" "Configuração do Deepin concluída. Reinicie para ver o LightDM."
