#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-xfce.sh
# Versão: 2.0.0 (Multi-Distro Completo)
# Descrição: Otimizações e Pacotes para XFCE
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Iniciando configuração do XFCE..."

# ==============================================================================
# 1. INSTALAÇÃO DE PACOTES ESSENCIAIS
# ==============================================================================

log "INFO" "Instalando pacotes essenciais do XFCE..."

PKGS_XFCE_BASE=(
    "thunar"                   # Gerenciador de arquivos
    "thunar-archive-plugin"    # Plugin de arquivos compactados
    "thunar-media-tags-plugin" # Plugin de tags de mídia
    "xfce4-terminal"           # Terminal do XFCE
    "xfce4-appfinder"          # Localizador de aplicativos
    "xfce4-panel"              # Painel do XFCE
    "xfce4-settings"           # Configurações do XFCE
    "xfce4-power-manager"      # Gerenciador de energia
    "xfce4-notifyd"            # Daemon de notificações
    "ristretto"                # Visualizador de imagens leve
    "mousepad"                 # Editor de texto simples
)

# Tenta instalar pacotes base
i "${PKGS_XFCE_BASE[@]}"

# ==============================================================================
# 2. INSTALAÇÃO DE PACOTES OPCIONAIS (Melhorias)
# ==============================================================================

log "INFO" "Instalando pacotes opcionais do XFCE..."

PKGS_XFCE_OPTIONAL=(
    "xfce4-whiskermenu-plugin" # Menu de aplicativos melhorado
    "xfce4-pulseaudio-plugin"  # Plugin de áudio
    "xfce4-systemload-plugin"  # Plugin de carga do sistema
    "xfce4-weather-plugin"     # Plugin de clima
    "xfce4-screenshooter"      # Ferramenta de screenshot
    "xfce4-taskmanager"        # Gerenciador de tarefas
)

# Tenta instalar pacotes opcionais (não críticos se falharem)
for pkg in "${PKGS_XFCE_OPTIONAL[@]}"; do
    if ! i "$pkg" 2>/dev/null; then
        log "WARN" "Não foi possível instalar $pkg (opcional)"
    fi
done

# ==============================================================================
# 3. REMOÇÃO DE BLOATWARE (Se existirem)
# ==============================================================================

log "INFO" "Removendo aplicações indesejadas (se existirem)..."

APPS_TO_REMOVE=(
    "xfce4-dict"               # Dicionário (às vezes indesejado)
    "xfce4-notes-plugin"       # Plugin de notas
)

for pkg in "${APPS_TO_REMOVE[@]}"; do
    # Verifica se o pacote está instalado antes de tentar remover
    if command -v "$pkg" &>/dev/null || pacman -Qi "$pkg" 2>/dev/null || dpkg -l | grep -q "$pkg" 2>/dev/null || rpm -q "$pkg" 2>/dev/null; then
        log "INFO" "Removendo: $pkg"
        r "$pkg" 2>/dev/null || log "WARN" "Não foi possível remover $pkg (pode ser dependência)"
    fi
done

# ==============================================================================
# 4. APLICAÇÃO DE CONFIGURAÇÕES DO XFCE
# ==============================================================================

log "INFO" "Aplicando preferências do XFCE (xfconf-query)..."

# Configurações de tema e aparência (se xfconf-query estiver disponível)
if command -v xfconf-query &>/dev/null; then
    # Desabilitar efeitos visuais para melhor performance (opcional)
    # xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

    # Configurar comportamento do mouse
    xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-file-icons -s true 2>/dev/null || true

    log "INFO" "Configurações do XFCE aplicadas"
else
    log "WARN" "xfconf-query não encontrado. Pulando configurações avançadas do XFCE"
fi

# ==============================================================================
# 5. RESTAURAÇÃO DE CONFIGURAÇÕES PERSONALIZADAS
# ==============================================================================

log "INFO" "Verificando configurações personalizadas..."

# Thunar (Gerenciador de arquivos)
if command -v thunar &>/dev/null; then
    log "INFO" "Thunar detectado. Verificando backup de config..."
    restore_zip_config "$CONFIGS_DIR/thunar-$REAL_USER.zip" "$REAL_HOME/.config"
fi

log "SUCCESS" "Configuração do XFCE concluída."
