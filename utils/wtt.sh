#!/bin/bash

LOGFILE="$HOME/whisper_$(date +'%Y%m%d_%H%M%S').log"
MODEL_DOWNLOAD_ROOT="$HOME/.local/share/whisper_models" # Local permanente para os modelos

# Adiciona um trap para garantir que os processos do whisper sejam finalizados em caso de interrupção
trap 'log "Script interrompido. Finalizando processos pendentes do whisper..."; pkill -f whisper; exit 1' SIGINT SIGTERM

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

check_whisper_installed() {
  if ! command -v whisper &> /dev/null; then
    yad --error --title="Erro" --text="O Whisper não está instalado nesta máquina. Por favor, instale antes de executar este script."
    log "Erro: Whisper não encontrado no PATH."
    exit 1
  fi
}

check_gpu() {
  if lspci | grep -i 'NVIDIA' &> /dev/null; then
    log "GPU Nvidia detectada."
    echo "nvidia"
  elif lspci | grep -i 'AMD' | grep -i 'VGA' &> /dev/null; then
    log "GPU AMD detectada."
    echo "amd"
  else
    log "Nenhuma GPU compatível detectada."
    echo "none"
  fi
}

# Função de processamento simplificada, agora executa de forma síncrona
run_whisper() {
  local input_file="$1"
  local lang_param="$2"
  local output_type="$3"
  local output_dir
  output_dir="$(dirname "$input_file")"

  local base_name
  base_name="$(basename "$input_file")"
  local file_name="${base_name%.*}"

  log "Iniciando processamento de: $file_name"

  # Validação do arquivo
  if [ ! -f "$input_file" ]; then
    log "ERRO: Arquivo não encontrado: $input_file"
    return 1
  fi

  if [ "$GPU_TYPE" = "nvidia" ]; then
    log "Limpando cache CUDA antes da execução..."
    python3 -c "import torch; torch.cuda.empty_cache()" 2>/dev/null
  fi

  # Construir o comando do whisper de forma segura
  local whisper_command

  if [[ "$output_type" == "Legendas" ]]; then
    whisper_command="whisper \"$input_file\" $lang_param --model $MODEL --output_dir \"$output_dir\" --model_dir \"$MODEL_DOWNLOAD_ROOT\" --task transcribe --output_format srt"
  elif [[ "$output_type" == "Transcrição" ]]; then
    whisper_command="whisper \"$input_file\" $lang_param --model $MODEL --output_dir \"$output_dir\" --model_dir \"$MODEL_DOWNLOAD_ROOT\" --task transcribe --output_format txt"
  else
    # Ambos: gera tanto TXT quanto SRT
    whisper_command="whisper \"$input_file\" $lang_param --model $MODEL --output_dir \"$output_dir\" --model_dir \"$MODEL_DOWNLOAD_ROOT\" --task transcribe --output_format txt && whisper \"$input_file\" $lang_param --model $MODEL --output_dir \"$output_dir\" --model_dir \"$MODEL_DOWNLOAD_ROOT\" --task transcribe --output_format srt"
  fi

  log "Executando comando para: $file_name"

  # Executa o comando e aguarda sua conclusão
  bash -c "$whisper_command"

  local exit_status=$?
  if [ $exit_status -eq 0 ]; then
      log "✓ Finalizado com sucesso: $file_name"
  else
      log "✗ Erro ou cancelamento durante o processamento de: $file_name (código: $exit_status)"
  fi
}

# Função que contém o loop de processamento para ser "pipada" para o YAD
process_all_files() {
    # Redireciona a saída para o log e para o stdout (que será o YAD)
    exec > >(tee -a "$LOGFILE") 2>&1

    log "============================================================"
    log " INÍCIO DO PROCESSAMENTO - $(date)"
    log "============================================================"

    # CORREÇÃO FINAL: Usar printf para converter ! em quebras de linha reais
    # O YAD retorna múltiplos arquivos separados por ! (exclamação)
    # Usamos printf com %b para interpretar \n corretamente
    local files_with_newlines
    files_with_newlines=$(printf '%s' "$input_files" | sed 's/!/\n/g')
    
    local file_count=0
    while IFS= read -r file; do
        # Ignora linhas vazias
        [ -z "$file" ] && continue
        
        ((file_count++))
        echo ""
        log "------------------------------------------------------------"
        log "Processando arquivo $file_count"
        run_whisper "$file" "$lang_param" "$output_type"
    done <<< "$files_with_newlines"

    echo ""
    log "============================================================"
    log " TODOS OS ARQUIVOS FORAM PROCESSADOS - $(date)"
    log " Total de arquivos: $file_count"
    log "============================================================"
}


# -------- Início ---------

check_whisper_installed
mkdir -p "$MODEL_DOWNLOAD_ROOT" # Garante que o diretório de modelos exista
GPU_TYPE=$(check_gpu)

if [ "$GPU_TYPE" = "none" ]; then
  yad --question --title="Aviso de Desempenho" --text="Nenhuma GPU compatível foi encontrada nesta máquina.\n\nA transcrição poderá ser extremamente demorada e consumir bastante CPU.\n\nDeseja continuar mesmo assim?" --button="Continuar:0" --button="Cancelar:1"
  if [ $? -ne 0 ]; then
    log "Execução cancelada pelo usuário por falta de GPU."
    exit 0
  fi
  log "Usuário optou por continuar mesmo sem GPU."
fi

# Formulário único para todas as configurações
FORM_DATA=$(yad --form --title="Configurações de Transcrição Whisper" --separator='|' \
    --width=600 \
    --field="Arquivos de Áudio/Vídeo":MFL "" \
    --field="Tipo de Saída:CB" "Ambos!Transcrição!Legendas" \
    --field="Idioma (código ou auto):" "pt" \
    --field="Modelo:CB" "large-v2!medium!small!base!tiny" \
    --button="Iniciar Transcrição:0" --button="Cancelar:1")

exit_code=$?
if [ $exit_code -ne 0 ]; then
    log "Operação cancelada pelo usuário na tela de configuração."
    exit 0
fi

# Extrai os dados do formulário
input_files=$(echo "$FORM_DATA" | cut -d'|' -f1)
output_type=$(echo "$FORM_DATA" | cut -d'|' -f2)
language=$(echo "$FORM_DATA" | cut -d'|' -f3)
MODEL=$(echo "$FORM_DATA" | cut -d'|' -f4)

# Validação dos dados
if [ -z "$input_files" ]; then
  yad --error --text="Nenhum arquivo foi selecionado. A operação foi cancelada."
  log "Nenhum arquivo selecionado. Abortando."
  exit 1
fi

if [ -n "$language" ]; then
  lang_param="--language $language"
else
  lang_param=""
fi

log "Configurações selecionadas:"
log " - Tipo de Saída: $output_type"
log " - Idioma: ${language:-Detecção Automática}"
log " - Modelo: $MODEL"
log " - Local dos Modelos: $MODEL_DOWNLOAD_ROOT"

# Melhor logging dos arquivos selecionados
log " - Arquivos selecionados:"
local files_with_newlines
files_with_newlines=$(printf '%s' "$input_files" | sed 's/!/\n/g')

local file_index=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ((file_index++))
    log "   $file_index. $(basename "$file")"
done <<< "$files_with_newlines"

# Executa a função de processamento e envia a saída para a janela de log do YAD
process_all_files | yad --text-info --tail --title="Processamento em Andamento" \
    --width=800 --height=600 --button="Fechar:1"

# Exibe a tela final com o resumo
FINAL_MESSAGE="Processamento finalizado!

Arquivos processados:"

local files_with_newlines_final
files_with_newlines_final=$(printf '%s' "$input_files" | sed 's/!/\n/g')

local final_count=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ((final_count++))
    FINAL_MESSAGE="$FINAL_MESSAGE
$final_count. $(basename "$file")"
done <<< "$files_with_newlines_final"

FINAL_MESSAGE="$FINAL_MESSAGE

Total: $final_count arquivo(s)

Log salvo em:
$LOGFILE"

yad --info --title="Conclusão" --text="$FINAL_MESSAGE" --width=600

log "Script finalizado."
exit 0