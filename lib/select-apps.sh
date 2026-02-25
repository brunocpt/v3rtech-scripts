#!/bin/bash
# ==============================================================================
# Script: lib/select-apps.sh
# Versão: 4.1.1
# Data: 2026-02-24
# Objetivo: Seleção gráfica de aplicativos a instalar
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }

# Detecta sistema ANTES de carregar apps-data.sh
if [ -z "$DISTRO_FAMILY" ]; then
    source "$BASE_DIR/lib/detect-system.sh" || { echo "[ERRO] Não foi possível carregar lib/detect-system.sh"; exit 1; }
fi

source "$BASE_DIR/lib/apps-data.sh" || { echo "[ERRO] Não foi possível carregar lib/apps-data.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
mkdir -p "$CONFIG_HOME" 2>/dev/null || true

# ==============================================================================
# VERIFICAÇÃO DE FERRAMENTAS GRÁFICAS
# ==============================================================================
DIALOG_TOOL=""
if command -v yad &>/dev/null; then
    DIALOG_TOOL="yad"
elif command -v zenity &>/dev/null; then
    DIALOG_TOOL="zenity"
else
    log "ERROR" "Nenhuma ferramenta gráfica disponível (YAD ou Zenity)"
    die "Instale YAD ou Zenity para usar este script"
fi
log "DEBUG" "Ferramenta de diálogo: $DIALOG_TOOL"

# ==============================================================================
# FUNÇÃO: Criar lista para YAD
# ==============================================================================
create_yad_list() {
    for app_name in "${APP_NAMES_ORDERED[@]}"; do
        status="${APP_MAP_ACTIVE[$app_name]:-FALSE}"
        desc="${APP_MAP_DESC[$app_name]:-Aplicativo}"
        category="${APP_MAP_CATEGORY[$app_name]:-Outros}"
        echo "$status|$app_name|$desc|$category"
    done
}

# ==============================================================================
# FUNÇÃO: Mostrar diálogo YAD
# ==============================================================================
show_dialog_yad() {
    log "STEP" "Abrindo diálogo YAD..."
    
    local yad_args=()
    while IFS='|' read -r checked app_name desc category; do
        yad_args+=("$checked" "$app_name" "$desc" "$category")
    done < <(create_yad_list)
    
    yad \
        --title="Seleção de Aplicativos" \
        --text="Selecione os aplicativos que deseja instalar" \
        --list \
        --checklist \
        --column="Instalar:CHK" \
        --column="Aplicativo:TEXT" \
        --column="Descrição:TEXT" \
        --column="Categoria:TEXT" \
        --separator="|" \
        --width=1000 \
        --height=600 \
        "${yad_args[@]}"
    
    return $?
}

# ==============================================================================
# FUNÇÃO: Processar seleção
# ==============================================================================
process_selection() {
    local yad_output="$1"
    
    > "$CONFIG_HOME/selected-apps.conf"
    
    if [ -z "$yad_output" ]; then
        log "INFO" "Nenhum app foi selecionado"
        return 1
    fi
    
    local count=0
    while IFS='|' read -r _ app_name desc category; do
        app_name=$(echo "$app_name" | xargs)
        
        if [ -n "$app_name" ]; then
            local found=0
            for idx in "${!APP_NAMES_ORDERED[@]}"; do
                if [ "${APP_NAMES_ORDERED[$idx]}" = "$app_name" ]; then
                    log "DEBUG" "App selecionado: $app_name (index: $idx)"
                    echo "SELECTED_APP_$idx=true" >> "$CONFIG_HOME/selected-apps.conf"
                    ((count++))
                    found=1
                    break
                fi
            done
            
            if [ $found -eq 0 ]; then
                log "WARN" "App não encontrado no banco de dados: $app_name"
            fi
        fi
    done <<< "$yad_output"
    
    if [ $count -gt 0 ]; then
        log "SUCCESS" "Seleção de $count app(s) salva em $CONFIG_HOME/selected-apps.conf"
        return 0
    else
        log "INFO" "Nenhum app válido foi selecionado"
        return 1
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================
section "Seleção de Aplicativos"

# Verifica e instala o YAD / Zenity se necessário
if ! command -v yad &> /dev/null; then
	echo -e "\033[0;32m[INFO] yad não encontrado. Instalando...\033[0m"
	if command -v pacman &> /dev/null; then
		sudo pacman -S --noconfirm yad
		elif command -v apt-get &> /dev/null; then
		sudo apt-get update && sudo apt-get install -y yad
		elif command -v dnf &> /dev/null; then
		sudo dnf install -y yad
		else
		echo -e "\033[1;31m[ERRO] YAD não instalado. Instale 'yad' manualmente.\033[0m"
		exit 1
	fi
fi

selection_output=""
exit_code=1

if [ "$DIALOG_TOOL" = "yad" ]; then
    selection_output=$(show_dialog_yad)
    exit_code=$?
fi

if [ $exit_code -eq 0 ]; then
    log "SUCCESS" "Diálogo fechado com sucesso"
    process_selection "$selection_output"
else
    log "WARN" "Diálogo foi cancelado pelo usuário"
    exit 1
fi
