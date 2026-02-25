#!/bin/bash

# ==============================================================================
# Script: v3rtech-install.sh
# Versão: 4.0.4
# Data: 2026-02-24
# Objetivo: Script-mestre orquestrador da suite V3RTECH Scripts v4.0.4
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Script principal que oferece menu interativo para:
# - Executar setup completo (sequência recomendada)
# - Executar scripts específicos
# - Configurar preferências
#
# Uso: ./v3rtech-install.sh
#
# ==============================================================================

# ==============================================================================
# SETUP AUTOMÁTICO NA PRIMEIRA EXECUÇÃO
# ==============================================================================

TARGET_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$SOURCE_DIR" != "$TARGET_DIR" ]; then
    echo -e "\033[1;33m[SETUP] Primeira execução detectada. Configurando o ambiente...\033[0m"

    # Verifica e instala o rsync se necessário
    if ! command -v rsync &> /dev/null; then
        echo -e "\033[0;32m[INFO] rsync não encontrado. Instalando...\033[0m"
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm rsync
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y rsync
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y rsync
        else
            echo -e "\033[1;31m[ERRO] Gerenciador de pacotes não suportado. Instale 'rsync' manualmente.\033[0m"
            exit 1
        fi
    fi

    # Copia os scripts para o diretório de destino
    echo -e "\033[0;32m[INFO] Copiando scripts para $TARGET_DIR...\033[0m"
    sudo mkdir -p "$TARGET_DIR"
    sudo rsync -a --delete --progress "$SOURCE_DIR/" "$TARGET_DIR/"
    
    # Ajusta permissões
    echo -e "\033[0;32m[INFO] Ajustando permissões...\033[0m"
    find "$TARGET_DIR" -type f -name "*.sh" -exec sudo chmod +x {} \;
    
    # Adiciona ao PATH
    PROFILE_FILE="/etc/profile.d/v3rtech-scripts.sh"
    if ! grep -q "$TARGET_DIR/utils" "$PROFILE_FILE" 2>/dev/null; then
        echo -e "\033[0;32m[INFO] Adicionando ao PATH do sistema...\033[0m"
        echo -e "#!/bin/sh\nexport PATH=\"$TARGET_DIR/core:\$TARGET_DIR/utils:\$PATH\"" | sudo tee "$PROFILE_FILE" > /dev/null
        sudo chmod +x "$PROFILE_FILE"
    fi
    
    echo -e "\033[1;32m[SUCCESS] Setup concluído! Executando o script a partir de $TARGET_DIR...\033[0m"
    # Executa o script a partir do novo local e sai
    exec "$TARGET_DIR/v3rtech-install.sh" "$@"
fi

# ==============================================================================

# Carrega dependências
source "$(dirname "$0")/core/env.sh"
source "$(dirname "$0")/core/logging.sh"
source "$(dirname "$0")/core/package-mgr.sh"

# ==============================================================================
# VALIDAÇÃO INICIAL
# ==============================================================================

# Verifica se está rodando como root
if [ "$EUID" -eq 0 ]; then
    die "Este script NÃO deve ser executado como root!"
fi

# Verifica se está em uma distribuição suportada
if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$(dirname "$0")/lib/detect-system.sh" || die "Falha ao detectar sistema"
fi

# ==============================================================================
# CONFIGURAÇÃO INICIAL (PRIMEIRA EXECUÇÃO)
# ==============================================================================

# Se PREFER_NATIVE não estiver definido, faz a pergunta inicial
if [ -z "$PREFER_NATIVE" ]; then
    section "Configuração Inicial"
    
    echo ""
    echo "=========================================="
    echo "  PREFERÊNCIA DE INSTALAÇÃO"
    echo "=========================================="
    echo ""
    echo "Escolha como deseja instalar os aplicativos:"
    echo ""
    echo "1) NATIVO (mais integrado ao sistema)"
    echo "   - Acesso direto ao AUR (Arch)"
    echo "   - Melhor integração com o desktop"
    echo "   - Usa mais espaço em disco"
    echo ""
    echo "2) FLATPAK (mais isolado e portável)"
    echo "   - Funciona em qualquer distribuição"
    echo "   - Sandbox para segurança"
    echo "   - Melhor para distribuições imutáveis"
    echo ""
    
    read -p "Escolha [1-2]: " install_method
    
    if [ "$install_method" = "1" ]; then
        PREFER_NATIVE="true"
        log "INFO" "Preferência: Instalar aplicativos NATIVOS"
    else
        PREFER_NATIVE="false"
        log "INFO" "Preferência: Instalar aplicativos FLATPAK"
    fi
    
    save_config "PREFER_NATIVE" "$PREFER_NATIVE"
fi

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================

# Exibe resumo do que será feito
show_summary() {
    local option="$1"
    
    echo ""
    echo "=========================================="
    echo "  RESUMO DO QUE SERÁ EXECUTADO"
    echo "=========================================="
    echo ""
    
    case "$option" in
        1)
            echo "Setup COMPLETO (sequência recomendada):"
            echo ""
            echo "1. Instalar pacotes essenciais (obrigatório)"
            echo "2. Configurar sistema (PATH, aliases, sudoers)"
            echo "3. Configurar bookmarks e atalhos"
            echo "4. Configurar desktop ($DESKTOP_ENV)"
            echo "5. Selecionar e instalar aplicativos por app"
            echo "6. Instalar Docker (se selecionado)"
            echo "7. Instalar Stack IA/ML (se selecionado)"
            echo "8. Instalar certificados ICP-Brasil (se selecionado)"
            echo "9. Instalar VirtualBox (se selecionado)"
            echo "10. Limpeza final"
            ;;
        2)
            echo "Instalar apenas apps essenciais"
            ;;
        3)
            echo "Configurar desktop ($DESKTOP_ENV)"
            ;;
        4)
            echo "Selecionar e instalar aplicativos (interface gráfica)"
            ;;
        5)
            echo "Configurar sistema (PATH, aliases, sudoers)"
            ;;
        6)
            echo "Executar script específico"
            ;;
        7)
            echo "Configurar preferências (Nativo vs Flatpak)"
            ;;
    esac
    
    echo ""
}

# Menu de seleção de opções adicionais
select_additional_options() {
    echo ""
    echo "=========================================="
    echo "  SELEÇÃO DE OPÇÕES ADICIONAIS"
    echo "=========================================="
    echo ""
    
    INSTALL_DOCKER=0
    INSTALL_IA_STACK=0
    INSTALL_CERTIFICATES=0
    INSTALL_VIRTUALBOX=0
    
    ask_yes_no "Instalar Docker?" && INSTALL_DOCKER=1
    ask_yes_no "Instalar Stack IA/ML (TensorFlow, PyTorch, Whisper)?" && INSTALL_IA_STACK=1
    ask_yes_no "Instalar certificados ICP-Brasil?" && INSTALL_CERTIFICATES=1
    ask_yes_no "Instalar VirtualBox?" && INSTALL_VIRTUALBOX=1
    
    # Salva as preferências
    save_config "INSTALL_DOCKER" "$INSTALL_DOCKER"
    save_config "INSTALL_IA_STACK" "$INSTALL_IA_STACK"
    save_config "INSTALL_CERTIFICATES" "$INSTALL_CERTIFICATES"
    save_config "INSTALL_VIRTUALBOX" "$INSTALL_VIRTUALBOX"
    
    log "SUCCESS" "Opções adicionais selecionadas e salvas"
}

# Executa setup completo
run_full_setup() {
    log "STEP" "Iniciando setup COMPLETO..."
    
    # 1. Selecionar apps (interface gráfica)
    log "STEP" "Abrindo seletor de aplicativos..."
    bash "$LIB_DIR/select-apps.sh" || log "WARN" "Seleção de apps cancelada"
    
    # 2. Instalar opções adicionais automaticamente (sem perguntar)
    INSTALL_DOCKER=1
    INSTALL_IA_STACK=1
    INSTALL_CERTIFICATES=1
    INSTALL_VIRTUALBOX=1
    
    # 3. Instalar essenciais
    log "STEP" "Instalando apps essenciais..."
    bash "$LIB_DIR/install-essentials.sh" || log "ERROR" "Falha ao instalar essenciais"
    
    # 4. Configurar sistema
    log "STEP" "Configurando sistema..."
    bash "$LIB_DIR/setup-system.sh" || log "ERROR" "Falha ao configurar sistema"
    
    # 5. Configurar desktop
    log "STEP" "Configurando desktop..."
    configure_desktop
    
    # 6. Instalar apps selecionados
    log "STEP" "Instalando aplicativos selecionados..."
    install_selected_apps
    
    # 7. Docker
    log "STEP" "Instalando Docker..."
    bash "$LIB_DIR/install-docker.sh" || log "WARN" "Falha ao instalar Docker"
    
    # 8. Stack IA
    log "STEP" "Instalando Stack IA/ML..."
    bash "$LIB_DIR/install-ia-stack.sh" || log "WARN" "Falha ao instalar Stack IA"
    
    # 9. Certificados
    log "STEP" "Instalando certificados ICP-Brasil..."
    bash "$LIB_DIR/install-certificates.sh" || log "WARN" "Falha ao instalar certificados"
    
    # 10. VirtualBox
    log "STEP" "Instalando VirtualBox..."
    # bash "$LIB_DIR/install-virtualbox.sh" || log "WARN" "Falha ao instalar VirtualBox"
    
    # 11. Gera atalhos para apps Flatpak
    log "STEP" "Gerando atalhos para apps Flatpak..."
    bash "$TARGET_DIR/utils/fpk-gera-atalhos.sh" || log "WARN" "Falha na geração dos atalhos para aplicativos Flatpak"
    
    log "SUCCESS" "Setup completo finalizado!"
}

# Configura desktop
configure_desktop() {
    if [ "$DESKTOP_ENV" = "unknown" ]; then
        log "WARN" "Ambiente Desktop desconhecido. Pulando configuração."
        return
    fi
    
    log "INFO" "Configurando $DESKTOP_ENV..."
    
    case "$DESKTOP_ENV" in
        kde)
            bash "$LIB_DIR/install-desktop-kde.sh" || log "ERROR" "Falha ao configurar KDE"
            ;;
        gnome)
            bash "$LIB_DIR/install-desktop-gnome.sh" || log "ERROR" "Falha ao configurar GNOME"
            ;;
        xfce)
            bash "$LIB_DIR/install-desktop-xfce.sh" || log "ERROR" "Falha ao configurar XFCE"
            ;;
        deepin)
            bash "$LIB_DIR/install-desktop-deepin.sh" || log "ERROR" "Falha ao configurar Deepin"
            ;;
        cosmic)
            bash "$LIB_DIR/install-desktop-cosmic.sh" || log "ERROR" "Falha ao configurar Cosmic"
            ;;
    esac
}

# Instala todos os apps selecionados
install_selected_apps() {
    bash "$LIB_DIR/install-apps-internet.sh" || true
    bash "$LIB_DIR/install-apps-office.sh" || true
    bash "$LIB_DIR/install-apps-dev.sh" || true
    bash "$LIB_DIR/install-apps-multimedia.sh" || true
    bash "$LIB_DIR/install-apps-design.sh" || true
    bash "$LIB_DIR/install-apps-system.sh" || true
    bash "$LIB_DIR/install-apps-games.sh" || true
}

# Executa script específico
run_specific_script() {
    local scripts=(
        "install-essentials.sh"
        "install-apps-internet.sh"
        "install-apps-office.sh"
        "install-apps-dev.sh"
        "install-apps-multimedia.sh"
        "install-apps-design.sh"
        "install-apps-system.sh"
        "install-apps-games.sh"
        "select-apps.sh"
        "install-docker.sh"
        "install-ia-stack.sh"
        "install-certificates.sh"
        "install-virtualbox.sh"
        "setup-system.sh"
        "cleanup.sh"
    )
    
    echo ""
    echo "=========================================="
    echo "  SCRIPTS DISPONÍVEIS"
    echo "=========================================="
    echo ""
    
    for i in "${!scripts[@]}"; do
        echo "$((i+1))) ${scripts[$i]}"
    done
    
    echo ""
    read -p "Escolha um script [1-${#scripts[@]}]: " script_choice
    
    if [ "$script_choice" -ge 1 ] && [ "$script_choice" -le ${#scripts[@]} ]; then
        local selected_script="${scripts[$((script_choice-1))]}"
        log "STEP" "Executando $selected_script..."
        bash "$LIB_DIR/$selected_script"
    else
        log "WARN" "Opção inválida"
    fi
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

section "V3RTECH Scripts v4.0.4"

while true; do
    echo ""
    echo "=========================================="
    echo "  Menu Principal"
    echo "=========================================="
    echo ""
    echo "1) Executar setup COMPLETO (recomendado)"
    echo "2) Instalar apenas apps essenciais"
    echo "3) Configurar desktop"
    echo "4) Selecionar e instalar aplicativos"
    echo "5) Configurar sistema"
    echo "6) Executar script específico"
    echo "7) Configurar preferências"
    echo "8) Sair"
    echo ""
    
    read -p "Escolha uma opção [1-8]: " choice
    
    case "$choice" in
        1)
            show_summary 1
            read -p "Continuar? (s/n) [s]: " confirm
            [ "$confirm" != "n" ] && run_full_setup
            ;;
        2)
            show_summary 2
            read -p "Continuar? (s/n) [s]: " confirm
            [ "$confirm" != "n" ] && bash "$LIB_DIR/install-essentials.sh"
            ;;
        3)
            show_summary 3
            read -p "Continuar? (s/n) [s]: " confirm
            [ "$confirm" != "n" ] && configure_desktop
            ;;
        4)
            show_summary 4
            read -p "Continuar? (s/n) [s]: " confirm
            if [ "$confirm" != "n" ]; then
                bash "$LIB_DIR/select-apps.sh"
                install_selected_apps
            fi
            ;;
        5)
            show_summary 5
            read -p "Continuar? (s/n) [s]: " confirm
            [ "$confirm" != "n" ] && bash "$LIB_DIR/setup-system.sh"
            ;;
        6)
            run_specific_script
            ;;
        7)
            show_summary 7
            echo "Preferência atual: PREFER_NATIVE=$PREFER_NATIVE"
            echo ""
            read -p "Mudar para NATIVO? (s/n) [n]: " change_pref
            if [ "$change_pref" = "s" ]; then
                PREFER_NATIVE="true"
                save_config "PREFER_NATIVE" "$PREFER_NATIVE"
                log "INFO" "Preferência alterada para NATIVO"
            fi
            ;;
        8)
            log "INFO" "Saindo..."
            exit 0
            ;;
        *)
            log "WARN" "Opção inválida"
            ;;
    esac
done
