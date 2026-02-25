#!/bin/bash
# ==============================================================================
# Arquivo: core/env.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Variáveis globais, caminhos, cores e detecção de ambiente
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Este arquivo deve ser o PRIMEIRO a ser carregado por qualquer script.
# Define caminhos, variáveis globais, cores ANSI e carrega a configuração
# compartilhada (config.conf).
#
# ==============================================================================

# --- 1. DETECÇÃO DE CAMINHOS ---

# Detecta o diretório raiz do projeto (onde quer que ele esteja)
# Usa BASH_SOURCE[0] para funcionar mesmo se o script for chamado via symlink
# Depois sobe um nível (..) para sair da pasta core/
if [ -n "${BASH_SOURCE[0]}" ]; then
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
    # Fallback para shells que não suportam BASH_SOURCE
    BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Verifica se o BASE_DIR foi detectado corretamente
if [ -z "$BASE_DIR" ] || [ "$BASE_DIR" = "/" ]; then
    echo "[ERRO CRÍTICO] Falha ao detectar o diretório raiz do projeto."
    echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]}"
    echo "dirname: $(dirname "${BASH_SOURCE[0]}")"
    exit 1
fi

# Estrutura de diretórios internos
CORE_DIR="$BASE_DIR/core"
LIB_DIR="$BASE_DIR/lib"
CONFIGS_DIR="$BASE_DIR/configs"
DATA_DIR="$BASE_DIR/data"
RESOURCES_DIR="$BASE_DIR/resources"
BACKUP_DIR="$BASE_DIR/backups"
UTILS_DIR="$BASE_DIR/utils"

# --- 2. INFORMAÇÕES DO USUÁRIO ---

# Captura o usuário real (não root)
# Se estiver sendo executado com sudo, usa SUDO_USER
# Senão, usa USER (usuário atual)
REAL_USER="${SUDO_USER:-${USER:-$(whoami)}}"

# Valida se REAL_USER não está vazio
if [ -z "$REAL_USER" ]; then
    echo "[ERRO CRÍTICO] Não foi possível detectar o usuário."
    echo "SUDO_USER: ${SUDO_USER}"
    echo "USER: ${USER}"
    echo "whoami: $(whoami)"
    exit 1
fi

REAL_HOME="$(eval echo ~$REAL_USER)"

# Diretório de configuração do usuário (XDG)
if [ -z "$REAL_HOME" ] || [ "$REAL_HOME" = "/root" ]; then
    # Se REAL_HOME está vazio ou é /root, tenta obter do /etc/passwd
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
fi

CONFIG_HOME="$REAL_HOME/.config/v3rtech-scripts"
LOG_DIR="$CONFIG_HOME/logs"

# Arquivo de log principal
LOG_FILE="$LOG_DIR/v3rtech-install.log"

# --- 3. ARQUIVO DE CONFIGURAÇÃO COMPARTILHADO ---

# Carrega configuração compartilhada se existir
CONFIG_FILE="$CONFIG_HOME/config.conf"

# Se não existir, cria com valores padrão
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_HOME" "$LOG_DIR" 2>/dev/null || {
        echo "[ERRO] Não foi possível criar o diretório de configuração: $CONFIG_HOME"
        exit 1
    }
    
    # Inicializa com valores padrão
    # IMPORTANTE: Variáveis críticas (BASE_DIR, LIB_DIR, etc) são deixadas vazias
    # pois são detectadas dinamicamente no env.sh e não devem ser sobrescritas
    cat > "$CONFIG_FILE" << 'EOF'
#!/bin/bash
# Configuração V3RTECH Scripts v4.7.0
# Gerada automaticamente

DISTRO_FAMILY=""
DISTRO_NAME=""
PKG_MANAGER=""
DESKTOP_ENV=""
SESSION_TYPE=""
GPU_VENDOR=""
IS_IMMUTABLE=""
PREFER_NATIVE=""
INSTALL_CATEGORIES=""
FILEBOT_METHOD="flatpak"
SUBLIMINAL_METHOD="pipx"
DRY_RUN=0
AUTO_CONFIRM=0
VERBOSE=0
LAST_UPDATE=""
EOF
fi

# Carrega a configuração, mas protege variáveis críticas
# Salva os valores detectados antes de carregar o config.conf
_DETECTED_BASE_DIR="$BASE_DIR"
_DETECTED_CORE_DIR="$CORE_DIR"
_DETECTED_LIB_DIR="$LIB_DIR"
_DETECTED_CONFIGS_DIR="$CONFIGS_DIR"
_DETECTED_DATA_DIR="$DATA_DIR"
_DETECTED_RESOURCES_DIR="$RESOURCES_DIR"
_DETECTED_BACKUP_DIR="$BACKUP_DIR"
_DETECTED_UTILS_DIR="$UTILS_DIR"
_DETECTED_REAL_USER="$REAL_USER"
_DETECTED_REAL_HOME="$REAL_HOME"
_DETECTED_CONFIG_HOME="$CONFIG_HOME"
_DETECTED_LOG_DIR="$LOG_DIR"
_DETECTED_LOG_FILE="$LOG_FILE"

# Carrega a configuração
source "$CONFIG_FILE" 2>/dev/null || true

# Restaura variáveis críticas que não devem ser sobrescritas
BASE_DIR="$_DETECTED_BASE_DIR"
CORE_DIR="$_DETECTED_CORE_DIR"
LIB_DIR="$_DETECTED_LIB_DIR"
CONFIGS_DIR="$_DETECTED_CONFIGS_DIR"
DATA_DIR="$_DETECTED_DATA_DIR"
RESOURCES_DIR="$_DETECTED_RESOURCES_DIR"
BACKUP_DIR="$_DETECTED_BACKUP_DIR"
UTILS_DIR="$_DETECTED_UTILS_DIR"
REAL_USER="$_DETECTED_REAL_USER"
REAL_HOME="$_DETECTED_REAL_HOME"
CONFIG_HOME="$_DETECTED_CONFIG_HOME"
LOG_DIR="$_DETECTED_LOG_DIR"
LOG_FILE="$_DETECTED_LOG_FILE"

# Limpa variáveis temporárias
unset _DETECTED_BASE_DIR _DETECTED_CORE_DIR _DETECTED_LIB_DIR _DETECTED_CONFIGS_DIR
unset _DETECTED_DATA_DIR _DETECTED_RESOURCES_DIR _DETECTED_BACKUP_DIR _DETECTED_UTILS_DIR
unset _DETECTED_REAL_USER _DETECTED_REAL_HOME _DETECTED_CONFIG_HOME _DETECTED_LOG_DIR _DETECTED_LOG_FILE

# --- 4. DEFINIÇÕES DE CORES E FORMATAÇÃO (ANSI) ---

# Cores para saída do terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color (Reset)

# --- 5. FLAGS DE CONTROLE ---

# DRY_RUN: Se 1, simula ações destrutivas sem executar
DRY_RUN=${DRY_RUN:-0}

# AUTO_CONFIRM: Se 1, responde "Sim" automaticamente para prompts
AUTO_CONFIRM=${AUTO_CONFIRM:-0}

# VERBOSE: Se 1, exibe mais detalhes no output
VERBOSE=${VERBOSE:-0}

# --- 6. ABSTRAÇÃO DE PRIVILÉGIOS (Sudo Wrapper) ---

# Todos os comandos que exigem root devem usar: $SUDO comando argumentos
if [ "$DRY_RUN" -eq 1 ]; then
    # Em modo de teste, apenas imprime o comando que seria executado
    SUDO="echo [DRY-RUN: SUDO]"
else
    # Em modo real, usa o sudo do sistema
    SUDO="sudo"
fi

# --- 7. EXPORTAÇÃO DE VARIÁVEIS CRÍTICAS ---

# Garante que subshells enxerguem estas variáveis
export BASE_DIR CORE_DIR LIB_DIR DATA_DIR RESOURCES_DIR UTILS_DIR BACKUP_DIR CONFIGS_DIR
export LOG_FILE CONFIG_FILE CONFIG_HOME LOG_DIR
export REAL_USER REAL_HOME
export SUDO DRY_RUN AUTO_CONFIRM VERBOSE
export RED GREEN YELLOW BLUE CYAN MAGENTA BOLD NC

# --- 8. FUNÇÃO AUXILIAR: ATUALIZAR CONFIG.CONF ---

# Função para salvar variáveis no arquivo de configuração
save_config() {
    local key="$1"
    local value="$2"
    
    # Protege variáveis críticas contra sobrescrita
    case "$key" in
        BASE_DIR|CORE_DIR|LIB_DIR|CONFIGS_DIR|DATA_DIR|RESOURCES_DIR|BACKUP_DIR|UTILS_DIR|\
        REAL_USER|REAL_HOME|CONFIG_HOME|LOG_DIR|LOG_FILE|CONFIG_FILE)
            # Não salva variáveis críticas no config.conf
            return 0
            ;;
    esac
    
    # Cria backup antes de modificar
    [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$CONFIG_FILE.bak" 2>/dev/null || true
    
    # Atualiza ou adiciona a variável
    if grep -q "^$key=" "$CONFIG_FILE" 2>/dev/null; then
        # Usa sed para substituir valor existente (escapa caracteres especiais)
        sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_FILE"
    else
        # Adiciona nova variável
        echo "$key=\"$value\"" >> "$CONFIG_FILE"
    fi
    
    # Atualiza timestamp
    sed -i "s|^LAST_UPDATE=.*|LAST_UPDATE=\"$(date '+%Y-%m-%d %H:%M:%S')\"|" "$CONFIG_FILE"
}

# --- 9. VALIDAÇÃO BÁSICA ---

# Verifica se os diretórios críticos existem
if [ ! -d "$LIB_DIR" ] || [ ! -d "$UTILS_DIR" ]; then
    echo -e "${RED}[ERRO CRÍTICO]${NC} Diretórios críticos não encontrados!"
    echo -e "${RED}BASE_DIR:${NC} $BASE_DIR"
    echo -e "${RED}LIB_DIR:${NC} $LIB_DIR"
    echo -e "${RED}UTILS_DIR:${NC} $UTILS_DIR"
    echo ""
    echo "Verifique se você está executando o script de dentro do diretório do projeto."
    echo "Exemplo correto: cd /caminho/para/v3rtech-scripts-v4 && ./v3rtech-install.sh"
    exit 1
fi

# --- 10. INICIALIZAÇÃO DE LOG ---

# Cria o arquivo de log se não existir
if [ ! -f "$LOG_FILE" ]; then
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    touch "$LOG_FILE" 2>/dev/null || true
fi
