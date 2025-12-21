#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: v3rtech-install.sh (Script Mestre Consolidado)
# Versão: 1.6.1
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
log "INFO" "Inicializando V3RTECH Scripts v1.6.0..."

# --- LÓGICA DE AUTO-INSTALAÇÃO ---
# Se o script não estiver rodando do local definitivo, ele se instala.
TARGET_DIR="/usr/local/share/scripts/v3rtech-scripts"

if [[ "$SCRIPT_DIR" != "$TARGET_DIR" ]]; then
    log "INFO" "Detectado execução fora do diretório padrão. Instalando no sistema..."

    # Valida sudo antes de copiar
    if ! sudo -v; then die "Falha no sudo. Impossível instalar."; fi

    # Cria diretório e copia
    log "INFO" "Copiando arquivos para $TARGET_DIR..."
    sudo mkdir -p "$TARGET_DIR"
    sudo cp -r "$SCRIPT_DIR/"* "$TARGET_DIR/"

    # Ajusta permissões
    sudo chown -R root:root "$TARGET_DIR"
    sudo chmod -R 755 "$TARGET_DIR"

    # Adiciona ao PATH do usuário se não existir
    if ! grep -q "$TARGET_DIR" "$HOME/.bashrc"; then
        echo "export PATH=\"\$PATH:$TARGET_DIR\"" >> "$HOME/.bashrc"
    fi

    log "SUCCESS" "Instalação concluída em $TARGET_DIR."
    log "INFO" "Continuando execução a partir da mídia atual..."
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
load_lib "$LIB_DIR/05-setup-sudoers.sh"
load_lib "$LIB_DIR/06-setup-shell-env.sh"
load_lib "$LIB_DIR/07-setup-user-dirs.sh"
load_lib "$LIB_DIR/08-setup-maintenance.sh"
load_lib "$LIB_DIR/09-setup-fstab-mounts.sh"
load_lib "$LIB_DIR/10-setup-keyboard-shortcuts.sh"

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

# --- DADOS E REPOSITÓRIOS ---
log "STEP" "3. Carregando dados..."
load_lib "$LIB_DIR/logic-apps-reader.sh"
load_apps_csv

log "STEP" "4. Configurando repositórios..."
load_lib "$LIB_DIR/02-setup-repos.sh"

# --- UI: SELEÇÃO E INSTALAÇÃO ---
log "STEP" "5. Interface de Seleção..."
load_lib "$LIB_DIR/ui-main.sh"

# --- AMBIENTE DESKTOP ---
if [ -f "$LIB_DIR/04-pack-${DESKTOP_ENV}.sh" ]; then
    log "STEP" "6. Configurando Desktop: ${DESKTOP_ENV^}..."
    load_lib "$LIB_DIR/04-pack-${DESKTOP_ENV}.sh"
fi

# --- 03: CONFIGS GERAIS (INCLUI PLYMOUTH AGORA) ---
log "STEP" "7. Otimizações de sistema e visuais..."
load_lib "$LIB_DIR/03-prepara-configs.sh"

# --- 04: BOOT ---
log "STEP" "8. Otimizando Boot..."
load_lib "$LIB_DIR/04-setup-boot.sh"

# --- HOOKS ESPECÍFICOS ---

# Docker
if grep -q "^TRUE|.*|Docker|" "$DATA_DIR/apps.csv"; then
    log "STEP" "9. Configurando Docker..."
    load_lib "$LIB_DIR/setup-docker.sh"
fi

# VirtualBox (Novo Hook)
# Verifica se VirtualBox foi instalado OU se está no CSV
if command -v VBoxManage &>/dev/null || grep -q "^TRUE|.*|VirtualBox|" "$DATA_DIR/apps.csv"; then
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
