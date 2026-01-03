#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: core/logging.sh
# Versão: 1.0.0
#
# Descrição: Funções de logging padronizado (Terminal e Arquivo).
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Inicializa o arquivo de log
setup_log() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    echo "------------------------------------------------------" >> "$LOG_FILE"
    echo " V3RTECH SCRIPTS - Início da execução: $(date)" >> "$LOG_FILE"
    echo "------------------------------------------------------" >> "$LOG_FILE"
}

# Função de Log Genérica
# Uso: log "TIPO" "Mensagem"
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local color="$NC"

    case "$type" in
        INFO)    color="$BLUE" ;;
        WARN)    color="$YELLOW" ;;
        ERROR)   color="$RED" ;;
        SUCCESS) color="$GREEN" ;;
        STEP)    color="$CYAN" ;;
    esac

    # Imprime no Terminal (com cor)
    echo -e "${color}[$type]${NC} $message"

    # Salva no arquivo (sem cor)
    echo "[$timestamp] [$type] $message" >> "$LOG_FILE"
}

# Função para reportar erro crítico e abortar
die() {
    log "ERROR" "$1"
    echo -e "${RED}Execução abortada pelo sistema de segurança.${NC}"
    exit 1
}
