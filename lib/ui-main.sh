#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/ui-main.sh
# Versão: 8.0.0 (Production Ready & Bugfix)
# Descrição: Interface Gráfica Principal.
# Correções:
#   1. Suporte a Wayland (xhost + env vars).
#   2. Parsing robusto do retorno do YAD (tr \n |).
#   3. Logs detalhados e tratamento de janelas.
# ==============================================================================

# --- PREPARAÇÃO DO AMBIENTE GRÁFICO ---
# Correção crítica para distros rodando Wayland (Fedora, Debian 12, Ubuntu 22+)
# Permite que o usuário root desenhe janelas na sessão do usuário local.
if [ -n "$WAYLAND_DISPLAY" ]; then
    log "INFO" "Ambiente Wayland detectado. Ajustando permissões de display..."
    xhost +si:localuser:root &>/dev/null
    export GDK_BACKEND=x11
    export NO_AT_BRIDGE=1
fi

log "STEP" "Inicializando Interface de Seleção..."

# Array local para armazenar os dados visuais
declare -a UI_LIST=()

# ------------------------------------------------------------------------------
# 1. CARREGAMENTO DOS DADOS (Modo Visual)
# ------------------------------------------------------------------------------

# Redefine a função add_app para popular APENAS o array visual
# Ignoramos pkg_deb, flatpak_id, etc. neste momento.
add_app() {
    local active="$1"
    local category="$2"
    local name="$3"
    local desc="$4"
    # Adiciona ao array linear: Checkbox | Categoria | Nome | Descrição
    UI_LIST+=("$active" "$category" "$name" "$desc")
}

# Localiza o arquivo de dados (apps-data.sh)
DB_FILE="${DATA_DIR:-data}/apps-data.sh"
if [ ! -f "$DB_FILE" ]; then DB_FILE="lib/apps-data.sh"; fi # Fallback

if [ -f "$DB_FILE" ]; then
    log "INFO" "Lendo catálogo de aplicativos: $DB_FILE"
    source "$DB_FILE"
else
    die "ERRO FATAL: O arquivo de dados $DB_FILE não foi encontrado."
fi

# Validação de segurança
QTD_APPS=$((${#UI_LIST[@]} / 4))
if [ "$QTD_APPS" -eq 0 ]; then
    die "A lista de aplicativos está vazia. O script não pode continuar."
fi

log "INFO" "Interface carregada com $QTD_APPS aplicativos disponíveis."

# ------------------------------------------------------------------------------
# 2. CONFIGURAÇÃO E EXIBIÇÃO DA JANELA (YAD)
# ------------------------------------------------------------------------------

WINDOW_TITLE="V3RTECH - Pós-Instalação (${DISTRO_NAME:-Linux})"
WINDOW_ICON="system-software-install"
WINDOW_TEXT="Selecione os aplicativos que deseja instalar.\n\nSistema: <b>${DISTRO_NAME}</b>\nAmbiente: <b>${XDG_SESSION_TYPE:-X11}</b>\nApps Disponíveis: <b>$QTD_APPS</b>"

# Exibe o YAD. Usamos printf + pipe para evitar limites de argumentos do bash.
SELECTED_APPS_STRING=$(printf "%s\n" "${UI_LIST[@]}" | yad --list --checklist \
    --title="$WINDOW_TITLE" \
    --window-icon="$WINDOW_ICON" \
    --width=950 --height=650 --center \
    --text="$WINDOW_TEXT" \
    --column="Instalar":BOOL \
    --column="Categoria" \
    --column="Aplicação" \
    --column="Descrição" \
    --search-column=3 \
    --print-column=3 \
    --separator="|" \
    --no-markup \
    --button="Sair do Script!application-exit:1" \
    --button="Iniciar Instalação!system-run:0")

EXIT_CODE=$?

# Tratamento de saída
if [ $EXIT_CODE -ne 0 ]; then
    log "WARN" "O usuário cancelou a seleção ou fechou a janela."
    exit 0
fi

if [ -z "$SELECTED_APPS_STRING" ]; then
    yad --info --title="Aviso" --text="Nenhum aplicativo foi selecionado." --width=300 --button="OK:0"
    exit 0
fi

# ------------------------------------------------------------------------------
# 3. PREPARAÇÃO PARA INSTALAÇÃO (Parsing Seguro)
# ------------------------------------------------------------------------------

# IMPORTANTE: Carregamos agora a lógica real de instalação
# (Onde estão os mapas de pacotes nativos/flatpak)
if [ -f "lib/logic-apps-reader.sh" ]; then
    source "lib/logic-apps-reader.sh"
    load_apps_database # Recarrega os dados, agora populando os mapas técnicos
else
    die "Erro Crítico: Script de lógica de instalação não encontrado."
fi

# --- A CORREÇÃO DO BUG "APENAS 1 APP" ESTÁ AQUI ---
# 1. 'tr \n |': Converte quebras de linha do YAD em pipes.
# 2. 'sed': Remove pipes duplicados ou pipe no final da string.
CLEAN_SELECTED_STRING=$(echo "$SELECTED_APPS_STRING" | tr '\n' '|' | sed 's/||/|/g;s/|$//')

log "INFO" "Lista bruta processada: $CLEAN_SELECTED_STRING"

# Converte string em array usando pipe como separador
IFS='|' read -ra APPS_TO_INSTALL <<< "$CLEAN_SELECTED_STRING"
TOTAL_APPS=${#APPS_TO_INSTALL[@]}

log "INFO" "Fila de instalação preparada: $TOTAL_APPS itens."

# ------------------------------------------------------------------------------
# 4. LOOP DE EXECUÇÃO
# ------------------------------------------------------------------------------

export YAD_LOG_TITLE="V3RTECH - Instalando..."

# Inicia visualizador de log em background
tail -f "$LOG_FILE" | yad --text-info \
    --title="$YAD_LOG_TITLE" \
    --window-icon="system-run" \
    --width=850 --height=550 --center \
    --tail \
    --fore="#00FF00" --back="#000000" \
    --button="Ocultar Detalhes!view-restore:0" \
    --text="Inicializando gerenciador de pacotes...\n" &

YAD_PID=$!

count=1
failed_count=0

for app_name in "${APPS_TO_INSTALL[@]}"; do
    # Remove espaços em branco residuais (Trim)
    app_name=$(echo "$app_name" | xargs)

    if [ -n "$app_name" ]; then
        log "STEP" "[$count/$TOTAL_APPS] Processando aplicativo: $app_name..."

        # Chama a função de instalação.
        # Usamos '||' para garantir que um erro não pare o loop inteiro.
        if ! install_app_by_name "$app_name"; then
            log "ERROR" "Houve um problema ao tentar instalar $app_name."
            ((failed_count++))
        fi

        ((count++))
    fi
done

# ------------------------------------------------------------------------------
# 5. FINALIZAÇÃO
# ------------------------------------------------------------------------------

# Fecha a janela de log
kill $YAD_PID 2>/dev/null

log "SUCCESS" "Processo de instalação em lote finalizado."

FINAL_MSG="<b>Processo Concluído!</b>\n\nTotal processado: $TOTAL_APPS\nErros: $failed_count\n\nVerifique o log para detalhes:\n$LOG_FILE"

yad --info \
    --title="Relatório Final" \
    --window-icon="emblem-ok-symbolic" \
    --text="$FINAL_MSG" \
    --width=450 --center \
    --button="Finalizar!application-exit:0"
