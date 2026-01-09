#!/bin/bash

# ==============================================================================
# SCRIPT: convert-images.sh (v9 - Lógica de argumentos aprimorada)
# DESCRIÇÃO: Converte imagens para JPG, WebP ou ambos. O argumento da linha de
#            comando agora apenas preenche a pasta inicial na UI.
# AUTOR: Gemini
# DATA: 23/08/2025
# ==============================================================================

# --- CONFIGURAÇÕES INICIAIS ---
LOG_FILE=~/convert-images.log
MAX_WIDTH=2160

# --- FUNÇÕES ---
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_dependencies() {
    local missing_deps=()
    command -v yad >/dev/null 2>&1 || missing_deps+=("yad")
    if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
        missing_deps+=("ImageMagick")
    fi
    if [ ${#missing_deps[@]} -ne 0 ]; then
        yad --error --width=400 --height=100 --text="Erro: Dependências não encontradas! Por favor, instale: ${missing_deps[*]}. O script será encerrado." --title="Erro de Dependência"
        exit 1
    fi
}

# --- EXECUÇÃO PRINCIPAL ---
>"$LOG_FILE"
log_message "--- Início da execução do script ---"
check_dependencies

if command -v magick >/dev/null 2>&1; then
    CONVERT_CMD="magick"
    log_message "ImageMagick v7+ detectado. Usando o comando 'magick'."
else
    CONVERT_CMD="convert"
    log_message "ImageMagick v6 detectado. Usando o comando 'convert'."
fi

# ==============================================================================
# CORREÇÃO: A interface gráfica agora é sempre exibida.
# O argumento da linha de comando ($1) é usado para preencher o valor inicial
# do campo de diretório, mas o usuário ainda deve confirmar e escolher o formato.
# ==============================================================================
INITIAL_DIR=""
if [ -n "$1" ]; then
    log_message "Pasta '$1' fornecida como argumento. Preenchendo o formulário."
    INITIAL_DIR="$1"
fi

FORM_DATA=$(yad --form --title="Converter Imagens" --width=500 --height=350 \
                --text="Escolha a pasta e o formato de conversão desejado:" \
                --field="Pasta de Imagens:":DIR "$INITIAL_DIR" \
                --field="Converter para:":CB "JPG!WebP!JPG e WebP")
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    log_message "Operação cancelada pelo usuário (código: $exit_code)."
    exit 0
fi

TARGET_DIR=$(echo "$FORM_DATA" | cut -d'|' -f1)
FORMAT_CHOICE=$(echo "$FORM_DATA" | cut -d'|' -f2)

# Validação da pasta e da escolha
if [ ! -d "$TARGET_DIR" ]; then
    log_message "ERRO: O caminho '$TARGET_DIR' não é uma pasta válida."
    yad --error --text="O caminho selecionado não é uma pasta válida!" --title="Erro"
    exit 1
fi
if [ -z "$FORMAT_CHOICE" ]; then
    log_message "ERRO: Nenhum formato de saída foi selecionado."
    yad --error --text="Nenhum formato de saída foi selecionado!" --title="Erro"
    exit 1
fi

log_message "Pasta de destino: $TARGET_DIR"
log_message "Formato de saída selecionado: $FORMAT_CHOICE"

cd "$TARGET_DIR"
log_message "Trabalhando no diretório: $(pwd)"

# Criação da pasta de backup
BACKUP_DIR="originais"
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir "$BACKUP_DIR"
    log_message "Pasta de backup '$BACKUP_DIR' criada com sucesso."
fi

# Contagem de arquivos
IMAGE_PATTERNS=(-iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp")
TOTAL_FILES=$(find . -maxdepth 1 -type f \( "${IMAGE_PATTERNS[@]}" \) | wc -l)
log_message "Total de $TOTAL_FILES imagens encontradas para processamento."

if [ "$TOTAL_FILES" -eq 0 ]; then
    log_message "Nenhuma imagem encontrada. Encerrando."
    yad --info --text="Nenhuma imagem encontrada na pasta selecionada." --title="Concluído" --timeout=5
    exit 0
fi

# Arquitetura com Named Pipe
PIPE=$(mktemp -u)
mkfifo "$PIPE"
trap 'rm -f "$PIPE"' EXIT

yad --progress --title="Convertendo Imagens" --width=500 --height=150 \
    --text="Iniciando conversão..." --percentage=0 --auto-close --auto-kill < "$PIPE" &
YAD_PID=$!
exec 3>"$PIPE"

COUNT=0
find . -maxdepth 1 -type f \( "${IMAGE_PATTERNS[@]}" \) -print0 | \
while IFS= read -r -d $'\0' file; do
    if ! ps -p $YAD_PID > /dev/null; then
        log_message "YAD foi fechado. Cancelando operação."
        break
    fi

    file="${file#./}"
    ((COUNT++))
    PERCENT=$((COUNT * 100 / TOTAL_FILES))

    echo "$PERCENT" >&3
    echo "# Processando ($COUNT/$TOTAL_FILES): $file" >&3

    log_message "---------------------------------------------"
    log_message "Processando arquivo: $file"

    IMG_INFO=$(identify -format "%w %m" "$file")
    IMG_WIDTH=$(echo "$IMG_INFO" | cut -d' ' -f1)
    IMG_FORMAT=$(echo "$IMG_INFO" | cut -d' ' -f2 | tr '[:upper:]' '[:lower:]')
    log_message "Info: Largura=$IMG_WIDTH, Formato=$IMG_FORMAT"

    FILENAME=$(basename -- "$file")
    BASENAME="${FILENAME%.*}"

    ORIGINAL_MOVED=false

    # --- LÓGICA DE CONVERSÃO PARA JPG ---
    if [[ "$FORMAT_CHOICE" == "JPG" || "$FORMAT_CHOICE" == "JPG e WebP" ]]; then
        if [[ "$IMG_FORMAT" != "jpeg" && "$IMG_FORMAT" != "jpg" ]] || [[ "$IMG_WIDTH" -gt "$MAX_WIDTH" ]]; then
            log_message "Ação: Criar/Atualizar versão JPG."
            if [ "$ORIGINAL_MOVED" = false ]; then
                mv "$file" "$BACKUP_DIR/"; ORIGINAL_MOVED=true
            fi
            "$CONVERT_CMD" "$BACKUP_DIR/$FILENAME" -resize "${MAX_WIDTH}x>" -quality 85 "${BASENAME}.jpg"
            log_message "Sucesso: Versão JPG criada/atualizada para '${BASENAME}.jpg'."
        fi
    fi

    # --- LÓGICA DE CONVERSÃO PARA WEBP ---
    if [[ "$FORMAT_CHOICE" == "WebP" || "$FORMAT_CHOICE" == "JPG e WebP" ]]; then
        if [[ "$IMG_FORMAT" != "webp" ]] || [[ "$IMG_WIDTH" -gt "$MAX_WIDTH" ]]; then
            log_message "Ação: Criar/Atualizar versão WebP."
            if [ "$ORIGINAL_MOVED" = false ]; then
                mv "$file" "$BACKUP_DIR/"; ORIGINAL_MOVED=true
            fi
            "$CONVERT_CMD" "$BACKUP_DIR/$FILENAME" -resize "${MAX_WIDTH}x>" -quality 80 "${BASENAME}.webp"
            log_message "Sucesso: Versão WebP criada/atualizada para '${BASENAME}.webp'."
        fi
    fi

    if [ "$ORIGINAL_MOVED" = false ]; then
        log_message "Ação: Nenhuma. A imagem já atende aos critérios para o(s) formato(s) selecionado(s)."
    fi
done

exec 3>&-
wait $YAD_PID
YAD_EXIT_CODE=$?

log_message "--- Fim da execução do script (YAD exit code: $YAD_EXIT_CODE) ---"

yad --info --width=350 --text="Processo concluído com sucesso!\n\nA janela fechará em 5 segundos.\n\nVerifique o log para detalhes:\n$LOG_FILE" --title="Conversão Concluída" --timeout=5

exit 0

