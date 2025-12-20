#!/bin/bash
# extrai-legendas-yad.sh - Versão com conversão para SRT e tema escuro

# =============== VERBOSIDADE OPCIONAL ===============
DEBUG=true
$DEBUG && set -x

# ================== DEPENDÊNCIAS ==================
for cmd in mkvmerge mkvextract yad jq ffmpeg; do
    if ! command -v "$cmd" &>/dev/null; then
        yad --error --title="Erro de dependência" --text="O aplicativo '$cmd' é indispensável para o funcionamento deste script. Por favor, instale-o."
        exit 1
    fi
done

# ================== LOG ==================
LOG_FILE="$HOME/extrai-legendas.log"
[ -f "$LOG_FILE" ] && rm -f "$LOG_FILE"
touch "$LOG_FILE"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"; }

log "Início do script extrai-legendas-yad.sh (com conversão para .srt)"

# ================== YAD ==================
SEPARATOR='!'
FILES=$(yad --form --title="Selecionar Arquivos para Extração" --separator="$SEPARATOR" \
    --width=700 --height=400 \
    --field="Adicione os arquivos MKV à lista:":MFL --file-filter="Arquivos MKV | *.mkv" \
    --button="Analisar Arquivos:0" --button="Cancelar:1")

exit_code=$?
[ $exit_code -ne 0 ] && { yad --info --title="Cancelado" --text="A operação foi cancelada."; log "Cancelado."; exit 0; }

[[ "$FILES" == *"$SEPARATOR" ]] && FILES=${FILES%"$SEPARATOR"}
[ -z "$FILES" ] && { yad --info --title="Nenhum arquivo" --text="Nada selecionado."; log "Nada selecionado."; exit 0; }

log "Arquivos selecionados (raw): $FILES"

mapfile -d "$SEPARATOR" -t fileArray <<< "$FILES"

# ================== ANÁLISE ==================
log "Iniciando análise dos arquivos..."

declare -a all_tracks_for_checklist
declare -A json_info_map
INTERNAL_SEPARATOR="@@@"

for raw_file in "${fileArray[@]}"; do
    file=$(echo "$raw_file" | tr -d '\r\n')
    log "Analisando: $file"

    if [ ! -f "$file" ]; then
        log "Arquivo não encontrado: '$file'. Pulando."
        continue
    fi

    json_info=$(mkvmerge -J "$file" 2>>"$LOG_FILE")
    if [[ "$json_info" == *"O arquivo"* ]]; then
        log "Erro do mkvmerge ao processar: $file"
        log "$json_info"
        continue
    fi

    json_info_map["$file"]="$json_info"
    echo "$json_info" >> "$LOG_FILE"

    tracks=$(echo "$json_info" | jq -r ".tracks[] | select(.type==\"subtitles\") | \"\(.id)${INTERNAL_SEPARATOR}\(.properties.language)${INTERNAL_SEPARATOR}\(.properties.track_name // \"Sem título\")\"")

    if [ -n "$tracks" ]; then
        mapfile -t track_lines_array <<< "$tracks"
        for track_line in "${track_lines_array[@]}"; do
            [ -z "$track_line" ] && continue
            p_track_id="${track_line%%${INTERNAL_SEPARATOR}*}"
            p_rest="${track_line#*${INTERNAL_SEPARATOR}}"
            p_lang="${p_rest%%${INTERNAL_SEPARATOR}*}"
            p_title="${p_rest#*${INTERNAL_SEPARATOR}}"
            all_tracks_for_checklist+=("TRUE" "$file${INTERNAL_SEPARATOR}TRACK${INTERNAL_SEPARATOR}$p_track_id${INTERNAL_SEPARATOR}$p_lang${INTERNAL_SEPARATOR}$p_title" "$(basename "$file")" "$p_lang" "$p_title")
        done
    fi

    attachments=$(echo "$json_info" | jq -r ".attachments[]? | select(.file_name | test(\"\\.(srt|ass|ssa|sub|txt)$\")) | \"\(.id)${INTERNAL_SEPARATOR}\(.file_name)\"")
    if [ -n "$attachments" ]; then
        mapfile -t att_lines_array <<< "$attachments"
        for att_line in "${att_lines_array[@]}"; do
            [ -z "$att_line" ] && continue
            att_id="${att_line%%${INTERNAL_SEPARATOR}*}"
            att_name="${att_line#*${INTERNAL_SEPARATOR}}"
            all_tracks_for_checklist+=("TRUE" "$file${INTERNAL_SEPARATOR}ATTACH${INTERNAL_SEPARATOR}$att_id${INTERNAL_SEPARATOR}$att_name" "$(basename "$file")" "Anexo" "$att_name")
        done
    fi
done

if [ ${#all_tracks_for_checklist[@]} -eq 0 ]; then
    yad --info --title="Nenhuma legenda encontrada" --text="Nenhuma legenda foi detectada nos arquivos."
    log "Nenhuma legenda encontrada."
    exit 0
fi

# ================== UI DE SELEÇÃO ==================
log "Exibindo seleção..."

selection=$(yad --list --checklist --separator=$'\n' \
    --title="Selecione as legendas para extrair" \
    --text="Selecione as legendas ou anexos a extrair:" \
    --width=900 --height=500 \
    --column="Extrair" \
    --column="ID Único da Trilha" \
    --column="Arquivo" \
    --column="Tipo" \
    --column="Descrição" \
    --hide-column=2 --print-column=2 \
    "${all_tracks_for_checklist[@]}" \
    --button="Extrair Selecionadas:0" --button="Cancelar:1")

[ $? -ne 0 ] || [ -z "$selection" ] && { yad --info --title="Cancelado" --text="Nada foi selecionado."; log "Nada selecionado."; exit 0; }

# ================== EXTRAÇÃO ==================
log "Iniciando extração..."

convert_to_srt() {
    original="$1"
    target="${original%.*}.srt"
    if ffmpeg -y -i "$original" "$target" &>>"$LOG_FILE"; then
        log "✅ Conversão bem-sucedida: $original → $target"
        rm -f "$original"
    else
        log "⚠️ Falha na conversão de $original"
    fi
}

while IFS= read -r full_id; do
    [ -z "$full_id" ] && continue

    file="${full_id%%${INTERNAL_SEPARATOR}*}"
    rest="${full_id#*${INTERNAL_SEPARATOR}}"
    kind="${rest%%${INTERNAL_SEPARATOR}*}"
    rest="${rest#*${INTERNAL_SEPARATOR}}"

    if [ "$kind" == "TRACK" ]; then
        track_id="${rest%%${INTERNAL_SEPARATOR}*}"
        rest="${rest#*${INTERNAL_SEPARATOR}}"
        lang="${rest%%${INTERNAL_SEPARATOR}*}"
        title="${rest#*${INTERNAL_SEPARATOR}}"

        json_info="${json_info_map["$file"]}"
        codec_id=$(echo "$json_info" | jq -r --arg id "$track_id" '.tracks[] | select(.type=="subtitles" and (.id|tostring) == $id) | .properties.codec_id')

        case "$codec_id" in
            "S_TEXT/UTF8" | "S_TEXT/SRT") ext="srt" ;;
            "S_TEXT/ASS") ext="ass" ;;
            "S_TEXT/SSA") ext="ssa" ;;
            "S_HDMV/PGS") ext="sup" ;;
            "S_VOBSUB") ext="sub" ;;
            *) ext="txt" ;;
        esac

        base="${file%.*}"
        output="${base}.${lang}.${ext}"
        count=1
        while [ -f "$output" ]; do
            output="${base}.${lang}_$count.${ext}"
            count=$((count+1))
        done

        log "Extraindo trilha $track_id de '$file' para '$output'"
        if mkvextract tracks "$file" "$track_id:$output"; then
            log "✅ Sucesso: $output"
            [[ "$ext" != "srt" ]] && convert_to_srt "$output"
        else
            log "❌ Erro na extração da trilha $track_id"
            yad --error --title="Erro na extração" --text="Falha ao extrair trilha $track_id do arquivo:\n$file"
        fi

    elif [ "$kind" == "ATTACH" ]; then
        att_id="${rest%%${INTERNAL_SEPARATOR}*}"
        att_name="${rest#*${INTERNAL_SEPARATOR}}"

        base="${file%.*}"
        output="${base}.${att_name}"
        count=1
        while [ -f "$output" ]; do
            output="${base}_${count}.${att_name}"
            count=$((count+1))
        done

        log "Extraindo anexo $att_id ($att_name) de '$file' para '$output'"
        if mkvextract attachments "$file" "$att_id:$output"; then
            log "✅ Sucesso: $output"
            [[ "$output" != *.srt ]] && convert_to_srt "$output"
        else
            log "❌ Erro ao extrair anexo $att_id"
            yad --error --title="Erro na extração" --text="Falha ao extrair anexo $att_id do arquivo:\n$file"
        fi
    fi
done <<< "$selection"

yad --info --timeout=10 --title="Concluído" \
    --text="Extração finalizada. Esta janela se fechará em 10 segundos.\n\nLog:\n$LOG_FILE" \
    --button="Fechar:0"

log "Script finalizado com sucesso."
exit 0

