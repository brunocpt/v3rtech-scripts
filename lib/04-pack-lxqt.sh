#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-pack-lxqt.sh
# Versão: 1.0.0 (Novo)
# Descrição: Otimizações e Pacotes para LXQt
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Iniciando configuração do LXQt..."

# ==============================================================================
# 1. INSTALAÇÃO DE PACOTES ESSENCIAIS
# ==============================================================================

log "INFO" "Instalando pacotes essenciais do LXQt..."

PKGS_LXQT_BASE=(
    "lxqt-core"                # Meta-pacote base do LXQt
    "pcmanfm-qt"               # Gerenciador de arquivos
    "lxqt-terminal"            # Terminal do LXQt
    "lxqt-panel"               # Painel do LXQt
    "lxqt-session"             # Sessão do LXQt
    "lxqt-config"              # Configurações do LXQt
    "lxqt-powermanagement"     # Gerenciador de energia
    "lximage-qt"               # Visualizador de imagens
    "qterminal"                # Terminal alternativo
)

# Tenta instalar pacotes base
i "${PKGS_LXQT_BASE[@]}"

# ==============================================================================
# 2. INSTALAÇÃO DE PACOTES OPCIONAIS (Melhorias)
# ==============================================================================

log "INFO" "Instalando pacotes opcionais do LXQt..."

PKGS_LXQT_OPTIONAL=(
    "lxqt-admin"               # Ferramentas administrativas
    "lxqt-sudo"                # Diálogo sudo do LXQt
    "lxqt-runner"              # Executor de comandos
    "qpdfview"                 # Visualizador de PDF
    "qalculate-gtk"            # Calculadora avançada
)

# Tenta instalar pacotes opcionais (não críticos se falharem)
for pkg in "${PKGS_LXQT_OPTIONAL[@]}"; do
    if ! i "$pkg" 2>/dev/null; then
        log "WARN" "Não foi possível instalar $pkg (opcional)"
    fi
done

# ==============================================================================
# 3. REMOÇÃO DE BLOATWARE (Se existirem)
# ==============================================================================

log "INFO" "Removendo aplicações indesejadas (se existirem)..."

APPS_TO_REMOVE=(
    "lxmusic"                  # Player de música (às vezes indesejado)
    "lxgames"                  # Jogos (às vezes indesejado)
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

# PCManFM-Qt (Gerenciador de arquivos)
if command -v pcmanfm-qt &>/dev/null; then
    log "INFO" "PCManFM-Qt detectado. Verificando backup de config..."
    restore_zip_config "$CONFIGS_DIR/pcmanfm-qt-$REAL_USER.zip" "$REAL_HOME/.config"
fi

log "SUCCESS" "Configuração do LXQt concluída."
