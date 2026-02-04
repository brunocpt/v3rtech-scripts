#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: v3rtech-install.sh (Script Mestre Consolidado)
# Versão: 3.9.7
#
# Descrição: Orquestrador principal da automação de pós-instalação.
# Novidades: Auto-instalação no disco, Confirmação de Distro e VM Hook.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. BOOTSTRAP E CARREGAMENTO DO CORE
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Função de carregamento
load_lib() {
    local file="$1"
    if [ -f "$file" ]; then source "$file"; else
        echo -e "\033[0;31m[CRITICAL]\033[0m Lib ausente: $file"; exit 1
    fi
}

load_lib "$SCRIPT_DIR/core/env.sh"
load_lib "$SCRIPT_DIR/core/logging.sh"
load_lib "$SCRIPT_DIR/core/package-mgr.sh"

# ------------------------------------------------------------------------------
# 2. SEGURANÇA E AUTO-INSTALAÇÃO (PERSISTÊNCIA)
# ------------------------------------------------------------------------------

# Validação de Usuário
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}ERRO:${NC} Execute como usuário comum (sem sudo)."
   exit 1
fi

setup_log
log "INFO" "Inicializando V3RTECH Scripts v1.6.3..."

# --- LÓGICA DE AUTO-INSTALAÇÃO ---
# Se o script não estiver rodando do local definitivo, ele se instala.
TARGET_DIR="/usr/local/share/scripts/v3rtech-scripts"

if [[ "$SCRIPT_DIR" != "$TARGET_DIR" ]]; then
    log "INFO" "Detectado execução fora do diretório padrão. Instalando no sistema..."

    # Valida sudo antes de copiar
    if ! sudo -v; then die "Falha no sudo. Impossível instalar."; fi

    # ==============================================================================
    # VERIFICAÇÃO E INSTALAÇÃO DO RSYNC
    # ==============================================================================

    log "INFO" "Verificando disponibilidade do rsync..."

    if ! command -v rsync &>/dev/null; then
        log "WARN" "rsync não encontrado. Instalando..."

        # [HOTFIX] Se DISTRO_FAMILY não estiver definido (estágio inicial), detecta agora.
        if [ -z "$DISTRO_FAMILY" ] && [ -f /etc/os-release ]; then
            source /etc/os-release
            local_id="${ID,,}"
            local_id_like="${ID_LIKE,,}"
            
            if [[ "$local_id" == "arch" || "$local_id_like" =~ "arch" ]]; then
                DISTRO_FAMILY="arch"
            elif [[ "$local_id" == "debian" || "$local_id_like" =~ "debian" || "$local_id" == "ubuntu" || "$local_id_like" =~ "ubuntu" ]]; then
                DISTRO_FAMILY="debian"
            elif [[ "$local_id" == "fedora" || "$local_id_like" =~ "fedora" ]]; then
                DISTRO_FAMILY="fedora"
            fi
        fi

        case "$DISTRO_FAMILY" in
            debian)
                log "INFO" "Instalando rsync via apt..."
                sudo apt update
                sudo apt install -y rsync || die "Falha ao instalar rsync em Debian/Ubuntu"
                ;;
            arch)
                log "INFO" "Instalando rsync via pacman..."
                sudo pacman -Sy --noconfirm rsync || die "Falha ao instalar rsync em Arch Linux"
                ;;
            fedora)
                log "INFO" "Instalando rsync via dnf..."
                sudo dnf install -y rsync || die "Falha ao instalar rsync em Fedora"
                ;;
            *)
                die "Distro não suportada ou rsync não disponível"
                ;;
        esac

        # Verifica novamente
        if ! command -v rsync &>/dev/null; then
            die "rsync não pôde ser instalado. Não é possível continuar."
        fi
        log "SUCCESS" "rsync instalado com sucesso."
    else
        log "SUCCESS" "rsync encontrado e disponível."
    fi

    # ==============================================================================
    # CÓPIA COM RSYNC (MIRROR)
    # ==============================================================================

    log "INFO" "Copiando arquivos para $TARGET_DIR usando rsync..."

    # Cria diretório destino
    sudo mkdir -p "$TARGET_DIR"

    # Usa rsync com opções de mirror:
    # -a: archive mode (preserva permissões, timestamps, etc)
    # -v: verbose
    # --delete: remove arquivos no destino que não existem na origem (mirror)
    # --exclude: exclui arquivos/diretórios específicos
    # --checksum: verifica integridade por checksum (mais seguro)
    if sudo rsync -av \
        --delete \
        --exclude='.git' \
        --exclude='.gitignore' \
        --exclude='*.log' \
        --exclude='.vscode' \
        --checksum \
        "$SCRIPT_DIR/" "$TARGET_DIR/"; then

        log "SUCCESS" "Arquivos copiados com sucesso via rsync."
    else
        die "Falha ao copiar arquivos com rsync."
    fi

    # Ajusta permissões finais
    log "INFO" "Ajustando permissões..."
    sudo chown -R root:root "$TARGET_DIR"
    sudo chmod -R 755 "$TARGET_DIR"

    # Garante que scripts em utils/ são executáveis
    sudo chmod +x "$TARGET_DIR/utils"/* 2>/dev/null || true

    # Adiciona ao PATH do usuário se não existir
    if ! grep -q "$TARGET_DIR" "$HOME/.bashrc"; then
        echo "export PATH=\"\$PATH:$TARGET_DIR\"" >> "$HOME/.bashrc"
    fi

    log "SUCCESS" "Instalação concluída em $TARGET_DIR."
    log "INFO" "Continuando execução a partir da mídia atual..."

    # Atualiza BASE_DIR, LIB_DIR, etc para apontar para o novo local
    BASE_DIR="$TARGET_DIR"
    LIB_DIR="$TARGET_DIR/lib"
    CONFIGS_DIR="$TARGET_DIR/configs"
    DATA_DIR="$TARGET_DIR/data"
    RESOURCES_DIR="$TARGET_DIR/resources"
    UTILS_DIR="$TARGET_DIR/utils"
fi

# Sudo Keep-Alive
if ! sudo -v; then die "Sem permissão sudo."; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

trap 'echo ""; log "WARN" "Interrompido."; exit 1' INT

# ------------------------------------------------------------------------------
# 3. FLUXO DE EXECUÇÃO
# ------------------------------------------------------------------------------

# --- 00: DETECCAO ---
log "STEP" "1. Identificando o sistema..."
load_lib "$LIB_DIR/00-detecta-distro.sh"

# --- 01: PREPARACAO ---
log "STEP" "2. Preparando base..."
load_lib "$LIB_DIR/01-prepara-distro.sh"
load_lib "$LIB_DIR/02-setup-repos.sh"
load_lib "$LIB_DIR/03-setup-flatpak.sh"
load_lib "$LIB_DIR/05-setup-sudoers.sh"
load_lib "$LIB_DIR/06-setup-shell-env.sh"
load_lib "$LIB_DIR/07-setup-user-dirs.sh"
load_lib "$LIB_DIR/08-setup-maintenance.sh"
load_lib "$LIB_DIR/09-setup-fstab-mounts.sh"
load_lib "$LIB_DIR/10-setup-keyboard-shortcuts.sh"
load_lib "$LIB_DIR/14-pack-essential-apps.sh"

# --- UI: CONFIRMACAO DA DETECCAO ---
# Requisito: Usuario deve confirmar se a deteccao esta certa
# NOTA: YAD agora esta garantidamente instalado apos 01-prepara-distro.sh
yad --image="computer" \
    --title="Confirmacao de Sistema" \
    --text="O sistema detectou o seguinte ambiente:\n\n<b>Distro:</b> ${DISTRO_NAME^} (${DISTRO_FAMILY})\n<b>Ambiente:</b> ${DESKTOP_ENV^}\n<b>GPU:</b> ${GPU_VENDOR^}\n\nAs otimizacoes serao aplicadas com base nisso.\nEsta correto?" \
    --button="Nao (Sair):1" \
    --button="Sim (Continuar):0" \
    --center --width=400

if [ $? -ne 0 ]; then
    log "WARN" "Usuario abortou apos deteccao de sistema."
    exit 0
fi

# --- AMBIENTE DESKTOP ---
if [ -f "$LIB_DIR/04-pack-${DESKTOP_ENV}.sh" ]; then
    log "STEP" "6. Configurando Desktop: ${DESKTOP_ENV^}..."
    load_lib "$LIB_DIR/04-pack-${DESKTOP_ENV}.sh"
fi

# --- DADOS E REPOSITÓRIOS ---
log "STEP" "3. Carregando dados..."
load_lib "$LIB_DIR/logic-apps-reader.sh"
#load_apps_csv

# --- UI: SELEÇÃO E INSTALAÇÃO ---
log "STEP" "5. Interface de Seleção..."
load_lib "$LIB_DIR/ui-main.sh"

# --- CERTIFICADOS ---
load_lib "$LIB_DIR/12-pack-certificates.sh"

# --- 03: CONFIGS GERAIS (INCLUI PLYMOUTH AGORA) ---
log "STEP" "7. Otimizações de sistema e visuais..."
load_lib "$LIB_DIR/03-prepara-configs.sh"

# --- 04: BOOT ---
log "STEP" "8. Otimizando Boot..."
load_lib "$LIB_DIR/04-setup-boot.sh"

# --- HOOKS ESPECÍFICOS ---

# Docker
if grep -q "^TRUE|.*|Docker|" "$LIB_DIR/apps-data.sh"; then
    log "STEP" "9. Configurando Docker..."
    load_lib "$LIB_DIR/setup-docker.sh"
fi

# VirtualBox (Novo Hook)
# Verifica se VirtualBox foi instalado OU se está no lib/apps-data.sh
if command -v VBoxManage &>/dev/null || grep -q "^TRUE|.*|VirtualBox|" "$LIB_DIR/apps-data.sh"; then
    log "STEP" "10. Configurando VirtualBox (Extension Pack & Users)..."
    load_lib "$LIB_DIR/13-pack-vm.sh"
fi

# --- 6. LIMPEZA FINAL ---
# Remove repositórios duplicados criados pelos pacotes instalados
if [ -f "lib/99-limpeza-final.sh" ]; then
    source "lib/99-limpeza-final.sh"
fi

# ------------------------------------------------------------------------------
# 4. FINALIZAÇÃO
# ------------------------------------------------------------------------------
log "SUCCESS" "Execução finalizada com sucesso."

kill $YAD_PID 2>/dev/null
yad --info --title="Sucesso" --text="Concluído! Verifique o log." --button="OK:0"

exit 0
