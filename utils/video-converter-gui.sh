#!/bin/bash
# Script de Conversão de Vídeos com Interface Gráfica YAD
# Versão melhorada com detecção de hardware, múltiplas opções e interface amigável

# ==================== CONFIGURAÇÕES ====================
LOGFILE="$HOME/video-convert.log"
TEMP_DIR="/tmp/video-converter-$$"
PID_FILE="$TEMP_DIR/converter.pid"
CANCEL_FLAG="$TEMP_DIR/cancel.flag"
PROGRESS_PIPE="$TEMP_DIR/progress.pipe"

# ==================== FUNÇÕES AUXILIARES ====================

# Função para limpar arquivos temporários
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# Função para detectar capacidades de hardware
detect_hardware() {
    local hw_info=""
    local cpu_cores=$(nproc)

    # Detectar GPU NVIDIA
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        hw_info="${hw_info}GPU NVIDIA detectada (NVENC disponível)\n"
        HAS_NVENC=1
    else
        HAS_NVENC=0
    fi

    # Detectar GPU AMD (verifica se há dispositivo renderD128)
    if [ -e /dev/dri/renderD128 ] && lspci 2>/dev/null | grep -i "VGA.*AMD" &> /dev/null; then
        hw_info="${hw_info}GPU AMD detectada (AMF disponível)\n"
        HAS_AMF=1
    else
        HAS_AMF=0
    fi

    hw_info="${hw_info}CPU: ${cpu_cores} núcleos detectados"
    CPU_CORES=$cpu_cores

    echo -e "$hw_info"
}

# Função para obter informações do vídeo
get_video_info() {
    local file="$1"
    ffprobe -v quiet -print_format json -show_streams -show_format "$file" 2>/dev/null || echo "{}"
}

# Função para verificar se o vídeo já está no formato desejado
check_if_conversion_needed() {
    local file="$1"
    local target_codec="$2"
    local target_height="$3"

    local info=$(get_video_info "$file")
    local current_codec=$(echo "$info" | grep -oP '"codec_name":\s*"\K[^"]+' | head -1)
    local current_height=$(echo "$info" | grep -oP '"height":\s*\K[0-9]+' | head -1)

    # Normalizar nomes de codec
    case "$current_codec" in
        hevc|h265) current_codec="hevc" ;;
        h264|avc) current_codec="h264" ;;
    esac

    case "$target_codec" in
        libx265|hevc_nvenc|hevc_amf) target_codec="hevc" ;;
        libx264|h264_nvenc|h264_amf) target_codec="h264" ;;
    esac

    # Se codec e resolução são iguais, não precisa converter
    if [ "$current_codec" = "$target_codec" ] && [ "$current_height" = "$target_height" ]; then
        return 1  # Não precisa converter
    fi

    return 0  # Precisa converter
}

# Função para construir comando FFmpeg
build_ffmpeg_command() {
    local input="$1"
    local output="$2"
    local codec="$3"
    local resolution="$4"
    local preset="$5"
    local ext="${input##*.}"

    local cmd="ffmpeg -y -i \"$input\""

    # Configurar threads baseado em CPU
    local threads=$((CPU_CORES > 8 ? 8 : CPU_CORES))
    cmd="$cmd -threads $threads"

    # Configurar codec de vídeo com parâmetros de compressão otimizados
    case "$codec" in
        "x265")
            # CRF 26-28 para x265 oferece boa compressão com qualidade aceitável
            # Parâmetros adicionais para melhor compressão
            cmd="$cmd -vcodec libx265 -preset $preset -crf 28"
            cmd="$cmd -x265-params log-level=error"
            if [[ "$ext" == "mp4" ]]; then
                cmd="$cmd -tag:v hvc1"
            fi
            ;;
        "x264")
            # CRF 23-26 para x264 (escala diferente do x265)
            cmd="$cmd -vcodec libx264 -preset $preset -crf 26"
            ;;
        "nvenc_h265")
            # Para NVENC, usar CQ (Constant Quality) equivalente
            # CQ 28-32 oferece boa compressão
            cmd="$cmd -vcodec hevc_nvenc -preset p4 -cq 30 -rc vbr"
            if [[ "$ext" == "mp4" ]]; then
                cmd="$cmd -tag:v hvc1"
            fi
            ;;
        "nvenc_h264")
            cmd="$cmd -vcodec h264_nvenc -preset p4 -cq 28 -rc vbr"
            ;;
        "amf_h265")
            # AMF usa quality mode
            cmd="$cmd -vcodec hevc_amf -quality quality -qp_i 28 -qp_p 28"
            ;;
        "amf_h264")
            cmd="$cmd -vcodec h264_amf -quality quality -qp_i 26 -qp_p 26"
            ;;
    esac

    # Configurar resolução (usar scale=-1 como no script original)
    if [ "$resolution" != "original" ]; then
        cmd="$cmd -vf \"scale=-1:$resolution\""
    fi

    # Codec de áudio (copiar para economizar tempo)
    cmd="$cmd -acodec copy"

    # Limitar frequência de updates de progresso para evitar sobrecarga
    cmd="$cmd -stats_period 2"

    # Arquivo de saída
    cmd="$cmd \"$output\""

    echo "$cmd"
}

# Função para converter vídeo
convert_video() {
    local input="$1"
    local output="$2"
    local codec="$3"
    local resolution="$4"
    local preset="$5"
    local current="$6"
    local total="$7"

    echo "[$current/$total] Convertendo: $(basename "$input")" | tee -a "$LOGFILE"
    echo "Codec: $codec | Resolução: ${resolution}p | Preset: $preset" | tee -a "$LOGFILE"
    echo "----------------------------------------" | tee -a "$LOGFILE"

    local cmd=$(build_ffmpeg_command "$input" "$output" "$codec" "$resolution" "$preset")

    # Executar FFmpeg
    eval "$cmd" >> "$LOGFILE" 2>&1
    local ffmpeg_result=$?

    if [ $ffmpeg_result -eq 0 ]; then
        echo "✓ Conversão concluída: $(basename "$output")" | tee -a "$LOGFILE"
        echo "" | tee -a "$LOGFILE"
        return 0
    else
        echo "✗ Erro na conversão: $(basename "$input")" | tee -a "$LOGFILE"
        echo "" | tee -a "$LOGFILE"
        return 1
    fi
}

# ==================== INTERFACE GRÁFICA ====================

# Mostrar informações de hardware
show_hardware_info() {
    local hw_info=$(detect_hardware)
    yad --info --title="Informações de Hardware" \
        --text="<b>Hardware Detectado:</b>\n\n$hw_info" \
        --width=400 --height=200 \
        --button="OK:0"
}

# Seletor de arquivos
select_files() {
    yad --file --multiple --separator="|" \
        --title="Selecionar Vídeos para Conversão" \
        --file-filter="Vídeos|*.mp4 *.mkv *.avi *.mov *.flv *.wmv *.webm" \
        --file-filter="Todos os arquivos|*" \
        --width=800 --height=600
}

# Configurações de conversão
show_settings_dialog() {
    # Detectar hardware
    detect_hardware > /dev/null

    # Construir opções de codec baseado no hardware
    local codec_options="x265 (HEVC - CPU)!x264 (H.264 - CPU)"

    if [ $HAS_NVENC -eq 1 ]; then
        codec_options="${codec_options}!nvenc_h265 (HEVC - GPU NVIDIA)!nvenc_h264 (H.264 - GPU NVIDIA)"
    fi

    if [ $HAS_AMF -eq 1 ]; then
        codec_options="${codec_options}!amf_h265 (HEVC - GPU AMD)!amf_h264 (H.264 - GPU AMD)"
    fi

    yad --form --title="Configurações de Conversão" \
        --width=500 --height=350 \
        --text="<b>Configure os parâmetros de conversão:</b>" \
        --field="Codec:CB" "$codec_options" \
        --field="Resolução:CB" "480!^720!1080!1440!2160!original" \
        --field="Qualidade/Velocidade:CB" "Rápido (faster)!Balanceado (medium)!Compacto (slower)" \
        --button="Info Hardware:2" \
        --button="Cancelar:1" \
        --button="Iniciar Conversão:0"
}

# Janela de progresso com cancelamento
show_progress_window() {
    local total_files="$1"

    # Janela YAD lendo do log via pipe
    # Usamos --pid=$$ no tail para garantir que ele morra quando o script encerrar
    tail -f "$LOGFILE" --pid=$$ | yad --text-info --title="Conversão de Vídeos em Andamento" \
        --width=800 --height=500 \
        --text="<b>Processando $total_files arquivo(s)...</b>" \
        --tail \
        --button="Cancelar Conversão:1" &

    local yad_pid=$!
    echo $yad_pid > "$PID_FILE"

    # Monitorar se o usuário clicou em cancelar
    (
        wait $yad_pid
        local exit_code=$?
        if [ $exit_code -eq 1 ]; then
            touch "$CANCEL_FLAG"
        fi
    ) &
}

# ==================== PROCESSAMENTO PRINCIPAL ====================

process_conversions() {
    local files="$1"
    local codec="$2"
    local resolution="$3"
    local preset="$4"

    # Criar diretório temporário
    mkdir -p "$TEMP_DIR"

    # Limpar log anterior
    echo "=== Conversão de Vídeos - $(date) ===" > "$LOGFILE"
    echo "" >> "$LOGFILE"

    # Converter string de arquivos em array
    IFS='|' read -ra FILE_ARRAY <<< "$files"
    local total_files=${#FILE_ARRAY[@]}

    # Criar pasta Compressed
    local base_dir=$(dirname "${FILE_ARRAY[0]}")
    local output_dir="$base_dir/Compressed"
    mkdir -p "$output_dir"

    # Mostrar janela de progresso
    show_progress_window "$total_files"

    # Aguardar janela estar pronta
    sleep 1

    # Processar cada arquivo
    local current=0
    local converted=0
    local skipped=0
    local failed=0

    for file in "${FILE_ARRAY[@]}"; do
        # Verificar flag de cancelamento
        if [ -f "$CANCEL_FLAG" ]; then
            echo "⚠ Conversão cancelada pelo usuário!" >> "$LOGFILE"
            echo "" >> "$LOGFILE"

            # Limpar arquivos temporários parciais
            rm -f "$output_dir"/*.tmp.* 2>/dev/null || true

            sleep 2
            break
        fi

        current=$((current + 1))
        local filename=$(basename "$file")
        local output="$output_dir/$filename"

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE"
        echo "Arquivo $current de $total_files" >> "$LOGFILE"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE"

        # Verificar se precisa converter
        if [ -f "$output" ]; then
            local codec_name=$(echo "$codec" | cut -d'_' -f1)
            if ! check_if_conversion_needed "$output" "$codec_name" "$resolution"; then
                echo "⊘ Pulando (já convertido com mesmos parâmetros): $filename" >> "$LOGFILE"
                echo "" >> "$LOGFILE"
                skipped=$((skipped + 1))
                continue
            fi
        fi

        # Converter vídeo
        if convert_video "$file" "$output" "$codec" "$resolution" "$preset" "$current" "$total_files"; then
            converted=$((converted + 1))
        else
            failed=$((failed + 1))
        fi
    done

    # Resumo final
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE"
    echo "✓ CONVERSÃO FINALIZADA" >> "$LOGFILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    echo "Total de arquivos: $total_files" >> "$LOGFILE"
    echo "Convertidos: $converted" >> "$LOGFILE"
    echo "Pulados: $skipped" >> "$LOGFILE"
    echo "Falhas: $failed" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    echo "Log completo salvo em: $LOGFILE" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    echo "Esta janela fechará automaticamente em 5 segundos..." >> "$LOGFILE"

    # Notificação do sistema
    if command -v notify-send &> /dev/null; then
        notify-send -t 5000 "Conversão de Vídeos" "✓ Concluído: $converted convertidos, $skipped pulados, $failed falhas" 2>/dev/null || true
    fi

    # Aguardar 5 segundos e fechar
    sleep 5

    # Fechar janela YAD
    if [ -f "$PID_FILE" ]; then
        local yad_pid=$(cat "$PID_FILE")
        kill $yad_pid 2>/dev/null || true
    fi

    # Mostrar diálogo de conclusão
    yad --info --title="Conversão Concluída" \
        --text="<b>Processo Finalizado!</b>\n\nTotal de arquivos: $total_files\nConvertidos: $converted\nPulados: $skipped\nFalhas: $failed\n\nLog salvo em: $LOGFILE" \
        --width=400 --button="OK:0"

    # Limpar
    cleanup
}

# ==================== MAIN ====================

main() {
    # Verificar dependências
    local missing_deps=""

    if ! command -v yad &> /dev/null; then
        missing_deps="${missing_deps}• YAD (instale com: sudo apt install yad)\n"
    fi

    if ! command -v ffmpeg &> /dev/null; then
        missing_deps="${missing_deps}• FFmpeg (instale com: sudo apt install ffmpeg)\n"
    fi

    if ! command -v ffprobe &> /dev/null; then
        missing_deps="${missing_deps}• FFprobe (geralmente incluído com FFmpeg)\n"
    fi

    if [ -n "$missing_deps" ]; then
        if command -v yad &> /dev/null; then
            yad --error --title="Dependências Faltando" \
                --text="<b>Os seguintes aplicativos não estão instalados:</b>\n\n${missing_deps}\nPor favor, instale-os antes de usar este script." \
                --width=450 --button="OK:0"
        else
            echo -e "ERRO: Dependências faltando:\n${missing_deps}"
        fi
        exit 1
    fi

    # Selecionar arquivos
    local files=$(select_files)

    if [ -z "$files" ] || [ "$files" = "" ]; then
        yad --info --title="Cancelado" --text="Nenhum arquivo selecionado." --button="OK:0"
        exit 0
    fi

    # Mostrar configurações
    local settings=$(show_settings_dialog)
    local ret=$?

    # Se clicou em "Info Hardware"
    if [ $ret -eq 2 ]; then
        show_hardware_info
        # Mostrar configurações novamente
        settings=$(show_settings_dialog)
        ret=$?
    fi

    # Se cancelou
    if [ $ret -ne 0 ] || [ -z "$settings" ]; then
        yad --info --title="Cancelado" --text="Conversão cancelada." --button="OK:0"
        exit 0
    fi

    # Parsear configurações
    IFS='|' read -r codec_choice resolution_choice preset_choice <<< "$settings"

    # Extrair codec (remover descrição)
    local codec=$(echo "$codec_choice" | cut -d' ' -f1)

    # Mapear preset
    local preset="medium"
    case "$preset_choice" in
        "Rápido"*) preset="faster" ;;
        "Balanceado"*) preset="medium" ;;
        "Compacto"*) preset="slower" ;;
    esac

    # Processar conversões
    process_conversions "$files" "$codec" "$resolution_choice" "$preset"
}

# Executar
main "$@"
