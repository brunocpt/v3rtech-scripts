#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-gnome.sh
# Versão: 2.0.0 (Multi-Distro Completo)
# Descrição: Otimizações e Pacotes para GNOME
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Iniciando configuração do GNOME..."

# ==============================================================================
# 1. INSTALAÇÃO DE PACOTES ESSENCIAIS
# ==============================================================================

log "INFO" "Instalando pacotes essenciais do GNOME..."

PKGS_GNOME_BASE=(
    "gnome-tweaks"             # Ferramenta de ajustes do GNOME
    "gnome-shell-extensions"   # Suporte a extensões
    "dconf-editor"             # Editor de configurações
    "nautilus"                 # Gerenciador de arquivos (Arquivos)
    "gnome-terminal"           # Terminal padrão
    "gnome-calculator"         # Calculadora
    "gnome-calendar"           # Calendário
    "gnome-clocks"             # Relógios e alarmes
    "eog"                      # Visualizador de imagens (Eye of GNOME)
    "evince"                   # Visualizador de documentos (PDF)
    "gedit"                    # Editor de texto simples
)

# Tenta instalar pacotes base
i "${PKGS_GNOME_BASE[@]}"

# ==============================================================================
# 2. INSTALAÇÃO DE PACOTES OPCIONAIS (Melhorias)
# ==============================================================================

log "INFO" "Instalando pacotes opcionais do GNOME..."

PKGS_GNOME_OPTIONAL=(
    "guake"                    # Terminal dropdown
    "ulauncher"                # Lançador de aplicativos
    "seahorse"                 # Gerenciador de senhas/chaves
    "gnome-maps"               # Aplicativo de mapas
    "gnome-music"              # Player de música
    "gnome-weather"            # Aplicativo de clima
    "variety"                  # Alternador de pano de fundo
)

# Tenta instalar pacotes opcionais (não críticos se falharem)
for pkg in "${PKGS_GNOME_OPTIONAL[@]}"; do
    if ! i "$pkg" 2>/dev/null; then
        log "WARN" "Não foi possível instalar $pkg (opcional)"
    fi
done

# Variety
  if [ -f "/usr/local/share/scripts/v3rtech-scripts/configs/variety.conf" ]; then
    mkdir -p $HOME/.config/variety/
    rm $HOME/.config/variety/variety.conf
    cp /usr/local/share/scripts/v3rtech-scripts/configs/variety.conf $HOME/.config/variety/
  fi

# ==============================================================================
# 3. INSTALAÇÃO DE EXTENSÕES PARA O GNOME SHELL (Melhorias)
# ==============================================================================

log "INFO" "Instalando extensões do GNOME SHELL..."

PKGS_GNOME_EXTENSIONS=(
    "gnome-shell-extension-dash-to-panel"
    "gnome-shell-extension-desktop-icons-ng"
    "gnome-shell-extension-dash-to-dock"
    "gnome-shell-extension-tray-icons-reloaded"
    "gnome-shell-extension-appindicator"
)

# Tenta instalar pacotes opcionais (não críticos se falharem)
for pkg in "${PKGS_GNOME_EXTENSIONS[@]}"; do
    if ! i "$pkg" 2>/dev/null; then
        log "WARN" "Não foi possível instalar $pkg (opcional)"
    fi
done


# ==============================================================================
# 4. REMOÇÃO DE BLOATWARE (Se existirem)
# ==============================================================================

log "INFO" "Removendo aplicações indesejadas (se existirem)..."

APPS_TO_REMOVE=(
    "gnome-games"              # Jogos do GNOME
    "gnome-chess"              # Xadrez
    "gnome-mines"              # Minas
    "gnome-sudoku"             # Sudoku
    "yelp"                     # Sistema de ajuda (às vezes indesejado)
)

for pkg in "${APPS_TO_REMOVE[@]}"; do
    # Verifica se o pacote está instalado antes de tentar remover
    if command -v "$pkg" &>/dev/null || pacman -Qi "$pkg" 2>/dev/null || dpkg -l | grep -q "$pkg" 2>/dev/null || rpm -q "$pkg" 2>/dev/null; then
        log "INFO" "Removendo: $pkg"
        r "$pkg" 2>/dev/null || log "WARN" "Não foi possível remover $pkg (pode ser dependência)"
    fi
done

# ==============================================================================
# 4. APLICAÇÃO DE CONFIGURAÇÕES DO GSETTINGS
# ==============================================================================

log "INFO" "Aplicando preferências do GNOME (GSettings)..."

# Layout de botões (Min, Max, Fechar)
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || log "WARN" "Não foi possível definir layout de botões"

# Alt+Tab (Janelas e não Apps)
gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]" 2>/dev/null || true
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab', '<Super>Tab']" 2>/dev/null || true

# Energia (Não suspender na tomada)
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || log "WARN" "Não foi possível configurar energia"
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true

# Interface
gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true 2>/dev/null || true

# Screenshot (Salvar em Downloads)
if [ -d "$REAL_HOME/Downloads" ]; then
    gsettings set org.gnome.gnome-screenshot auto-save-directory "file://$REAL_HOME/Downloads" 2>/dev/null || true
fi

log "SUCCESS" "Configuração do GNOME concluída."
