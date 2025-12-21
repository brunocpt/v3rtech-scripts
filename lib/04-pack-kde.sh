#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-kde.sh
# Versão: 2.0.0 (Multi-Distro Completo)
# Descrição: Otimizações e Pacotes para KDE Plasma
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Iniciando configuração do KDE Plasma..."

# ==============================================================================
# 1. INSTALAÇÃO DE PACOTES BASE E ESSENCIAIS
# ==============================================================================

# Pacotes base do KDE (variam por distro)
# Nota: Usamos a abstração 'i' que detecta automaticamente a distro
log "INFO" "Instalando pacotes base do KDE Plasma..."

PKGS_KDE_BASE=(
    "dolphin"                  # Gerenciador de arquivos
    "dolphin-plugins"          # Plugins para Dolphin
    "kio-extras"               # Protocolos adicionais para KIO
    "ark"                      # Gerenciador de arquivos compactados
    "kate"                     # Editor de texto avançado
    "konsole"                  # Emulador de terminal
    "gwenview"                 # Visualizador de imagens
    "spectacle"                # Ferramenta de screenshot moderna
    "okular"                   # Visualizador de documentos (PDF, etc)
    "kcalc"                    # Calculadora
    "kdeconnect"               # Integração com smartphones
    "kaccounts-providers"      # Provedores de contas online
)

# Tenta instalar pacotes base
i "${PKGS_KDE_BASE[@]}"

# ==============================================================================
# 2. INSTALAÇÃO DE PACOTES OPCIONAIS (Melhorias)
# ==============================================================================

log "INFO" "Instalando pacotes opcionais do KDE..."

PKGS_KDE_OPTIONAL=(
    "yakuake"                  # Terminal Dropdown estilo Quake
    "kfind"                    # Ferramenta de busca de arquivos
    "krename"                  # Renomeador em lote
    "skanpage"                 # Scanner de documentos
    "falkon"                   # Navegador web do KDE (leve)
)

# Tenta instalar pacotes opcionais (não críticos se falharem)
for pkg in "${PKGS_KDE_OPTIONAL[@]}"; do
    if ! i "$pkg" 2>/dev/null; then
        log "WARN" "Não foi possível instalar $pkg (opcional)"
    fi
done

# ==============================================================================
# 3. REMOÇÃO DE BLOATWARE (Se existirem)
# ==============================================================================

log "INFO" "Removendo aplicações indesejadas (se existirem)..."

APPS_TO_REMOVE=(
    "kmix"                     # Mixer de áudio antigo (substituído por plasma-pa)
    "ktorrent"                 # Cliente BitTorrent
    "elisa"                    # Player de música padrão (às vezes indesejado)
    "calligra"                 # Calligra Suite (pesado)
)

for pkg in "${APPS_TO_REMOVE[@]}"; do
    # Verifica se o pacote está instalado antes de tentar remover
    if command -v "$pkg" &>/dev/null || pacman -Qi "$pkg" 2>/dev/null || dpkg -l | grep -q "$pkg" 2>/dev/null || rpm -q "$pkg" 2>/dev/null; then
        log "INFO" "Removendo: $pkg"
        r "$pkg" 2>/dev/null || log "WARN" "Não foi possível remover $pkg (pode ser dependência)"
    fi
done

# ==============================================================================
# 4. RESTAURAÇÃO DE CONFIGURAÇÕES PERSONALIZADAS
# ==============================================================================

log "INFO" "Verificando configurações personalizadas..."

# Falkon (Navegador do KDE)
if command -v falkon &>/dev/null; then
    log "INFO" "Falkon detectado. Verificando backup de config..."
    restore_zip_config "$CONFIGS_DIR/falkon-$REAL_USER.zip" "$REAL_HOME/.config"
fi

# Konsole (Terminal)
if command -v konsole &>/dev/null; then
    log "INFO" "Konsole detectado. Verificando backup de config..."
    restore_zip_config "$CONFIGS_DIR/konsole-$REAL_USER.zip" "$REAL_HOME/.config"
fi

# ==============================================================================
# 5. AJUSTES DE SISTEMA (Opcional)
# ==============================================================================

log "INFO" "Aplicando ajustes de sistema do KDE..."

# Desabilitar notificações automáticas indesejadas
if [ -f "/etc/xdg/autostart/org.kde.discover.notifier.desktop" ]; then
    log "INFO" "Desabilitando notificações do Discover..."
    $SUDO rm -f "/etc/xdg/autostart/org.kde.discover.notifier.desktop" 2>/dev/null || log "WARN" "Não foi possível desabilitar notificações do Discover"
fi

# Opcional: Desabilitar Baloo (indexador de arquivos) se desejar melhor performance
# Descomente a linha abaixo se quiser desabilitar
# balooctl disable 2>/dev/null && log "INFO" "Baloo desabilitado"

log "SUCCESS" "Configuração do KDE Plasma concluída."
