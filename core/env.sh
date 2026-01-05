#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: core/env.sh
# Versão: 1.1.0
#
# Descrição: Arquivo central de definições de ambiente.
# Responsável por definir caminhos, variáveis globais, cores e flags de controle.
# Deve ser o primeiro arquivo carregado ("source") pelo script mestre.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# --- 1. Identificação de Caminhos (Paths) ---

# Detecta o diretório raiz do projeto (onde quer que ele esteja: USB, Git clone, etc)
# BASH_SOURCE[0] garante que o caminho seja relativo ao arquivo env.sh, subindo um nível (..)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Caminho onde os scripts serão instalados permanentemente no sistema alvo
INSTALL_DEST="/usr/local/share/scripts/v3rtech-scripts"

# Estrutura de Diretórios Interna
CORE_DIR="$BASE_DIR/core"
LIB_DIR="$BASE_DIR/lib"
CONFIGS_DIR="$BASE_DIR/configs"
DATA_DIR="$BASE_DIR/data"
RESOURCES_DIR="$BASE_DIR/resources"
BACKUP_DIR="$BASE_DIR/backups"
UTILS_DIR="$BASE_DIR/utils"

# --- 2. Informações do Usuário e Sistema ---

# Captura o usuário real que invocou o script (não o root, caso sudo tenha sido usado incorretamente)
# Como garantimos no script mestre que não rodamos como root direto, $USER é seguro.
REAL_USER="$USER"
REAL_HOME="$HOME"

# Arquivo de Log (Salvo na home do usuário para fácil acesso)
LOG_FILE="$REAL_HOME/v3rtech-install.log"

# --- 3. Flags de Controle e Comportamento ---

# DRY_RUN: Se 1, simula ações destrutivas (instalação/remoção) sem executar.
# Útil para debug e validação da lógica.
DRY_RUN=0

# AUTO_CONFIRM: Se 1, responde "Sim" automaticamente para prompts (Modo Headless/Silencioso).
AUTO_CONFIRM=0

# VERBOSE: Se 1, exibe mais detalhes no output do terminal.
VERBOSE=0

# --- 4. Abstração de Privilégios (Sudo Wrapper) ---

# Definimos a variável $SUDO.
# Todos os comandos que exigem root devem usar: $SUDO comando argumentos
if [ "$DRY_RUN" -eq 1 ]; then
    # Em modo de teste, apenas imprime o comando que seria executado
    SUDO="echo [DRY-RUN: SUDO]"
else
    # Em modo real, usa o sudo do sistema
    SUDO="sudo"
fi

# --- 5. Definições de Cores e Formatação (ANSI) ---

# Usadas para tornar a saída do terminal legível e profissional
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color (Reset)

# --- 6. Variáveis Globais de Detecção (Placeholders) ---
# Estas variáveis serão preenchidas pelo script 'lib/00-detecta-distro.sh'
# Declaramos aqui para clareza e escopo global.

DISTRO_FAMILY=""   # ex: debian, arch, fedora
DISTRO_NAME=""     # ex: ubuntu, linuxmint, manjaro
PKG_MANAGER=""     # ex: apt, pacman, dnf, zypper
DESKTOP_ENV=""     # ex: gnome, kde, xfce
SESSION_TYPE=""    # ex: x11, wayland
GPU_VENDOR=""      # ex: nvidia, amd, intel

# Exporta variáveis críticas para garantir que subshells as enxerguem
export BASE_DIR LIB_DIR DATA_DIR RESOURCES_DIR LOG_FILE
export REAL_USER REAL_HOME SUDO
export DRY_RUN AUTO_CONFIRM
