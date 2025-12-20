#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/ui-main.sh
# Versão: 1.0.0
#
# Descrição: Interface Gráfica Principal (GUI).
# 1. Exibe lista de seleção de apps (Checklist).
# 2. Processa a escolha do usuário.
# 3. Exibe janela de progresso/log em tempo real durante a instalação.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando Interface Gráfica..."

# Verifica se o array de apps (gerado em logic-apps-reader.sh) tem dados
if [ ${#APP_LIST_YAD[@]} -eq 0 ]; then
    die "Erro Interno: A lista de aplicativos para a interface está vazia."
fi

# ------------------------------------------------------------------------------
# 1. JANELA DE SELEÇÃO (Checklist)
# ------------------------------------------------------------------------------

# Título e Ícone
WINDOW_TITLE="V3RTECH - Pós-Instalação (${DISTRO_NAME^})"
WINDOW_ICON="system-software-install"
WINDOW_TEXT="Selecione os aplicativos que deseja instalar no seu sistema.\nDistribuição detectada: <b>${DISTRO_NAME^}</b>"

# Exibe o diálogo YAD
# --list --checklist: Cria a lista com caixas de seleção
# --print-column=3: Retorna apenas o NOME do app (coluna 3) para o script processar
# --separator="|": Usa pipe como separador dos itens selecionados
SELECTED_APPS_STRING=$(yad --list --checklist \
    --title="$WINDOW_TITLE" \
    --window-icon="$WINDOW_ICON" \
    --width=900 --height=600 --center \
    --text="$WINDOW_TEXT" \
    --column="Instalar":BOOL \
    --column="Categoria" \
    --column="Aplicação" \
    --column="Descrição" \
    --search-column=3 \
    --button="Sair!application-exit:1" \
    --button="Instalar!system-run:0" \
    "${APP_LIST_YAD[@]}")

EXIT_CODE=$?

# Se o usuário clicar em Sair (1) ou fechar a janela (252)
if [ $EXIT_CODE -ne 0 ]; then
    log "WARN" "Instalação cancelada pelo usuário na interface gráfica."
    exit 0
fi

# Se a string estiver vazia (nenhum app marcado)
if [ -z "$SELECTED_APPS_STRING" ]; then
    yad --info --title="Aviso" --text="Nenhum aplicativo foi selecionado." --width=300
    exit 0
fi

# ------------------------------------------------------------------------------
# 2. PROCESSAMENTO DA SELEÇÃO
# ------------------------------------------------------------------------------

# Converte a string "App1|App2|App3|" em um Array
IFS='|' read -ra APPS_TO_INSTALL <<< "$SELECTED_APPS_STRING"

TOTAL_APPS=${#APPS_TO_INSTALL[@]}
log "INFO" "Usuário selecionou $TOTAL_APPS aplicativos para instalação."

# ------------------------------------------------------------------------------
# 3. JANELA DE PROGRESSO (LOG VIEWER)
# ------------------------------------------------------------------------------
# Vamos criar uma janela que acompanha o log em tempo real (tail -f)
# Usamos export para que o subshell do YAD veja o título

export YAD_LOG_TITLE="V3RTECH - Instalando..."

# Inicia o YAD Log Viewer em background (&) lendo o arquivo de log
tail -f "$LOG_FILE" | yad --text-info \
    --title="$YAD_LOG_TITLE" \
    --window-icon="system-run" \
    --width=800 --height=500 --center \
    --tail \
    --fore="#00FF00" --back="#000000" \
    --button="Ocultar Detalhes!view-restore:0" \
    --text="Inicializando processo de instalação...\n" &

YAD_PID=$!

# ------------------------------------------------------------------------------
# 4. LOOP DE INSTALAÇÃO
# ------------------------------------------------------------------------------

count=1
for app_name in "${APPS_TO_INSTALL[@]}"; do
    # Remove espaços vazios que podem surgir do split
    if [ -z "$app_name" ]; then continue; fi

    log "STEP" "[$count/$TOTAL_APPS] Instalando: $app_name..."

    # Chama a função de instalação inteligente (definida em logic-apps-reader.sh)
    install_app_by_name "$app_name"

    ((count++))
done

# ------------------------------------------------------------------------------
# 5. FINALIZAÇÃO
# ------------------------------------------------------------------------------

# Mata a janela de log
kill $YAD_PID 2>/dev/null

log "SUCCESS" "Instalação em lote finalizada!"

# Exibe resumo final
yad --info \
    --title="Sucesso" \
    --text="<b>Processo Concluído!</b>\n\nForam processados $TOTAL_APPS aplicativos.\nVerifique o log em: $LOG_FILE" \
    --width=400 --center \
    --button="Finalizar!application-exit:0"
