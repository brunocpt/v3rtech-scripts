#!/bin/bash
# ==============================================================================
# Arquivo: core/logging.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Funções de logging padronizado (Terminal apenas)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Fornece funções de log coloridas para terminal.
# Deve ser carregado APÓS env.sh.
#
# ==============================================================================

# --- 1. INICIALIZAÇÃO DO ARQUIVO DE LOG ---

setup_log() {
    # Cria diretório de logs se não existir
    if [ -n "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi
    
    # Cria arquivo de log se não existir
    if [ -n "$LOG_FILE" ] && [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || true
        chmod 644 "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Adiciona cabeçalho de sessão (somente se LOG_FILE estiver definido)
    if [ -n "$LOG_FILE" ] && [ -w "$(dirname "$LOG_FILE")" ]; then
        {
            echo "======================================================================"
            echo "V3RTECH Scripts v4.7.0 - Sessão iniciada em $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Usuário: $REAL_USER | Distro: $DISTRO_FAMILY | Desktop: $DESKTOP_ENV"
            echo "======================================================================"
        } >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# --- 2. FUNÇÃO DE LOG GENÉRICA ---

# Uso: log "TIPO" "Mensagem"
# Tipos: INFO, WARN, ERROR, SUCCESS, STEP, DEBUG
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local color="$NC"
    
    # Define cor baseada no tipo
    case "$type" in
        INFO)    color="$BLUE" ;;
        WARN)    color="$YELLOW" ;;
        ERROR)   color="$RED" ;;
        SUCCESS) color="$GREEN" ;;
        STEP)    color="$CYAN" ;;
        DEBUG)   color="$MAGENTA" ;;
        *)       color="$NC" ;;
    esac
    
    # Imprime no terminal (com cor)
    echo -e "${color}[$type]${NC} $message"
    
    # Salva no arquivo de log (sem cor) - somente se LOG_FILE estiver definido
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [$type] $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# --- 3. FUNÇÃO PARA REPORTAR ERRO CRÍTICO E ABORTAR ---

die() {
    local message="$1"
    log "ERROR" "$message"
    echo -e "${RED}Execução abortada pelo sistema de segurança.${NC}"
    exit 1
}

# --- 4. FUNÇÃO PARA PERGUNTAS AO USUÁRIO ---

# Pergunta sim/não ao usuário
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"  # Padrão é "não"
    
    if [ "$AUTO_CONFIRM" -eq 1 ]; then
        # Em modo automático, sempre responde "sim"
        return 0
    fi
    
    local prompt="$question (s/n) [$default]: "
    read -p "$prompt" response
    
    case "$response" in
        [sS]|[yY]|sim|yes) return 0 ;;
        [nN]|não|no)       return 1 ;;
        "")                 [ "$default" = "s" ] && return 0 || return 1 ;;
        *)                  ask_yes_no "$question" "$default" ;;
    esac
}

# --- 5. FUNÇÃO PARA EXIBIR INFORMAÇÃO ---

# Exibe uma informação ao usuário (apenas terminal)
show_info() {
    local title="$1"
    local text="$2"
    
    echo ""
    echo -e "${BLUE}[$title]${NC}"
    echo "$text"
    echo ""
}

# --- 6. FUNÇÃO PARA EXIBIR PERGUNTA ---

# Exibe uma pergunta ao usuário (apenas terminal)
show_question() {
    local title="$1"
    local text="$2"
    
    echo ""
    echo -e "${CYAN}[$title]${NC}"
    ask_yes_no "$text"
}

# --- 7. FUNÇÃO PARA EXIBIR ERRO ---

# Exibe um erro ao usuário (apenas terminal)
show_error() {
    local title="$1"
    local text="$2"
    
    echo ""
    echo -e "${RED}[$title]${NC}"
    echo "$text"
    echo ""
}

# --- 8. FUNÇÃO PARA EXIBIR PROGRESSO ---

# Exibe barra de progresso simples
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processando}"
    
    local percent=$((current * 100 / total))
    local bar_length=50
    local filled=$((bar_length * current / total))
    local empty=$((bar_length - filled))
    
    printf "\r${CYAN}%s${NC} [" "$message"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percent"
}

# --- 9. FUNÇÃO PARA EXIBIR SEÇÃO ---

# Exibe cabeçalho de seção
section() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${CYAN}=== $title ===${NC}"
    echo ""
}

# --- 10. FUNÇÃO PARA EXIBIR LISTA ---

# Exibe item de lista
list_item() {
    local item="$1"
    echo -e "${CYAN}•${NC} $item"
}

# --- 11. FUNÇÃO PARA EXIBIR MENU DE SELEÇÃO ---

# Exibe um menu de seleção no terminal e retorna a escolha
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo ""
    echo -e "${BOLD}${CYAN}$title${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    
    echo ""
    read -p "Escolha uma opção [1-${#options[@]}]: " choice
    
    # Validação
    if [ -z "$choice" ] || ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options[@]}" ]; then
        echo -e "${RED}[ERRO]${NC} Opção inválida"
        return 1
    fi
    
    echo "$choice"
}

# --- 12. FUNÇÃO PARA EXIBIR LISTA DE SELEÇÃO (CHECKLIST) ---

# Exibe uma lista de itens para seleção múltipla
show_checklist() {
    local title="$1"
    shift
    local items=("$@")
    
    echo ""
    echo -e "${BOLD}${CYAN}$title${NC}"
    echo "Digite 's' para incluir, 'n' para pular:"
    echo ""
    
    local selected=()
    
    for item in "${items[@]}"; do
        read -p "  $item? (s/n) [n]: " response
        case "$response" in
            [sS]|sim|yes) selected+=("$item") ;;
        esac
    done
    
    # Retorna os itens selecionados (um por linha)
    printf '%s\n' "${selected[@]}"
}

# --- 13. INICIALIZAÇÃO AUTOMÁTICA ---

# Inicializa log quando o arquivo é sourced
setup_log
