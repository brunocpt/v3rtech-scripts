#!/bin/bash

# ============================================================
# Script de Tradução de Legendas (SRT) para Português Brasileiro
# ============================================================
# Versão: 2.0
# Data: 2026-01-20
# Descrição: Traduz arquivos .srt para português usando Google Translate
# Autor: V3RTECH
# ============================================================

LOGFILE="$HOME/translate_subtitles_$(date +'%Y%m%d_%H%M%S').log"
CACHE_FILE="$HOME/.translate_cache_$(date +'%Y%m%d').txt"

# Adiciona um trap para garantir que os processos sejam finalizados em caso de interrupção
trap 'log "Script interrompido..."; exit 1' SIGINT SIGTERM

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Função para obter tradução do cache ou da API
get_translation() {
  local text="$1"
  local source_lang="$2"
  local target_lang="$3"
  
  # Criar chave de cache: hash do texto + idiomas
  local cache_key=$(echo -n "${source_lang}:${target_lang}:${text}" | md5sum | cut -d' ' -f1)
  
  # Verificar se está no cache
  if [ -f "$CACHE_FILE" ]; then
    local cached=$(grep "^${cache_key}:" "$CACHE_FILE" | cut -d':' -f2-)
    if [ -n "$cached" ]; then
      echo "$cached"
      return 0
    fi
  fi
  
  # Não está no cache, traduzir
  local translated=$(translate_text "$text" "$source_lang" "$target_lang")
  
  # Salvar no cache
  echo "${cache_key}:${translated}" >> "$CACHE_FILE"
  
  echo "$translated"
}

# Função para traduzir texto usando curl com a API do Google Translate
translate_text() {
  local text="$1"
  local source_lang="$2"
  local target_lang="$3"
  
  # URL encoding usando sed
  local encoded_text=$(echo -n "$text" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/\*/%2A/g;s/+/%2B/g;s/,/%2C/g;s/\//%2F/g;s/:/%3A/g;s/;/%3B/g;s/=/%3D/g;s/?/%3F/g;s/@/%40/g;s/\[/%5B/g;s/\]/%5D/g;s/{/%7B/g;s/}/%7D/g')
  
  # Chamar API do Google Translate com timeout de 10 segundos
  local translated=$(curl -s --max-time 10 "https://translate.googleapis.com/translate_a/single?client=gtx&sl=${source_lang}&tl=${target_lang}&dt=t&q=${encoded_text}" 2>/dev/null | grep -oP '(?<=\[\[")[^"]*' | head -1)
  
  # Se a tradução estiver vazia, retornar o texto original
  if [ -z "$translated" ]; then
    echo "$text"
  else
    echo "$translated"
  fi
}

check_dependencies() {
  # Verificar se curl está disponível
  if ! command -v curl &> /dev/null; then
    yad --error --title="Erro" --text="curl não está instalado.\n\nPor favor, instale-o:\nsudo pacman -S curl"
    log "Erro: curl não encontrado"
    exit 1
  fi
  
  log "Dependências verificadas com sucesso"
}

# Função para traduzir um arquivo SRT mantendo a estrutura
translate_srt_file() {
  local input_file="$1"
  local output_file="$2"
  local source_lang="$3"
  local target_lang="$4"
  
  local base_name=$(basename "$input_file")
  local file_name="${base_name%.*}"
  
  log "Iniciando tradução de: $file_name"
  
  # Validação do arquivo
  if [ ! -f "$input_file" ]; then
    log "ERRO: Arquivo não encontrado: $input_file"
    return 1
  fi
  
  # Verificar se é um arquivo SRT válido
  if ! grep -q '^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]' "$input_file"; then
    log "ERRO: Arquivo não parece ser um SRT válido: $input_file"
    return 1
  fi
  
  # Criar arquivo temporário para a tradução
  local temp_file=$(mktemp)
  
  # Processar o arquivo linha por linha
  local line_num=0
  local total_lines=$(wc -l < "$input_file")
  local last_progress=0
  local translated_count=0
  local failed_count=0
  
  while IFS= read -r line; do
    ((line_num++))
    
    # Atualizar progresso a cada 10%
    local progress=$((line_num * 100 / total_lines))
    if [ $((progress % 10)) -eq 0 ] && [ $progress -ne $last_progress ]; then
      echo "$progress"
      last_progress=$progress
    fi
    
    # Se a linha é um número de sequência ou timestamp, copiar como está
    if [[ "$line" =~ ^[0-9]+$ ]] || [[ "$line" =~ ^[0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]] || [ -z "$line" ]; then
      echo "$line" >> "$temp_file"
    else
      # Traduzir a linha de diálogo usando cache
      local translated=$(get_translation "$line" "$source_lang" "$target_lang")
      
      if [ -n "$translated" ] && [ "$translated" != "$line" ]; then
        echo "$translated" >> "$temp_file"
        ((translated_count++))
      else
        # Se falhar, manter o texto original
        echo "$line" >> "$temp_file"
        ((failed_count++))
      fi
    fi
  done < "$input_file"
  
  # Mover arquivo temporário para o destino
  mv "$temp_file" "$output_file"
  
  if [ $? -eq 0 ]; then
    log "✓ Tradução concluída com sucesso: $file_name ($translated_count linhas traduzidas)"
    return 0
  else
    log "✗ Erro ao salvar arquivo traduzido: $output_file"
    return 1
  fi
}

# Função que contém o loop de processamento para ser "pipada" para o YAD
process_all_files() {
    # Redireciona a saída para o log e para o stdout (que será o YAD)
    exec > >(tee -a "$LOGFILE") 2>&1

    log "============================================================"
    log " INÍCIO DA TRADUÇÃO - $(date)"
    log " Cache de traduções: $CACHE_FILE"
    log "============================================================"

    # Converter ! em quebras de linha reais
    local files_with_newlines
    files_with_newlines=$(printf '%s' "$input_files" | sed 's/!/\n/g')
    
    local file_count=0
    local success_count=0
    local error_count=0
    
    while IFS= read -r file; do
        # Ignora linhas vazias
        [ -z "$file" ] && continue
        
        ((file_count++))
        echo ""
        log "------------------------------------------------------------"
        log "Processando arquivo $file_count"
        
        # Determinar o nome do arquivo de saída
        # Formato correto para players de vídeo: arquivo.pt-BR.srt
        local base_name=$(basename "$file")
        local file_name="${base_name%.*}"
        local output_file="$(dirname "$file")/${file_name}.pt-BR.srt"
        
        # Traduzir o arquivo
        if translate_srt_file "$file" "$output_file" "$source_lang" "$target_lang" 2>/dev/null; then
          ((success_count++))
        else
          ((error_count++))
        fi
    done <<< "$files_with_newlines"

    echo ""
    log "============================================================"
    log " TRADUÇÃO CONCLUÍDA - $(date)"
    log " Total de arquivos: $file_count"
    log " Sucesso: $success_count"
    log " Erros: $error_count"
    log " Cache salvo em: $CACHE_FILE"
    log "============================================================"
}


# -------- Início ---------

log "Script iniciado"

check_dependencies

# Mapa de idiomas para código ISO
declare -A lang_map=(
  ["Inglês"]=en
  ["Espanhol"]=es
  ["Francês"]=fr
  ["Alemão"]=de
  ["Italiano"]=it
  ["Japonês"]=ja
  ["Chinês"]=zh
  ["Português"]=pt
  ["Detecção Automática"]=auto
)

# Formulário único para todas as configurações
FORM_DATA=$(yad --form --title="Tradução de Legendas para Português Brasileiro" --separator='|' \
    --width=700 \
    --field="Arquivos SRT para Traduzir":MFL "" \
    --field="Idioma de Origem:CB" "Inglês!Espanhol!Francês!Alemão!Italiano!Japonês!Chinês!Português!Detecção Automática" \
    --field="Diretório de Saída (opcional):DIR" "" \
    --button="Iniciar Tradução:0" --button="Cancelar:1")

exit_code=$?
if [ $exit_code -ne 0 ]; then
    log "Operação cancelada pelo usuário na tela de configuração."
    exit 0
fi

# Extrai os dados do formulário
input_files=$(echo "$FORM_DATA" | cut -d'|' -f1)
source_lang_name=$(echo "$FORM_DATA" | cut -d'|' -f2)
output_dir=$(echo "$FORM_DATA" | cut -d'|' -f3)

# Converter nome do idioma para código ISO
source_lang=${lang_map[$source_lang_name]:-en}
target_lang="pt"

# Validação dos dados
if [ -z "$input_files" ]; then
  yad --error --text="Nenhum arquivo foi selecionado. A operação foi cancelada."
  log "Nenhum arquivo selecionado. Abortando."
  exit 1
fi

log "Configurações selecionadas:"
log " - Idioma de Origem: $source_lang_name ($source_lang)"
log " - Idioma de Destino: Português (pt)"
log " - Diretório de Saída: ${output_dir:-Mesmo diretório dos arquivos}"

# Melhor logging dos arquivos selecionados
log " - Arquivos selecionados:"
files_with_newlines=$(printf '%s' "$input_files" | sed 's/!/\n/g')

file_index=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ((file_index++))
    log "   $file_index. $(basename "$file")"
done <<< "$files_with_newlines"

# Executa a função de processamento e envia a saída para a janela de log do YAD
process_all_files | yad --text-info --tail --title="Tradução em Andamento" \
    --width=800 --height=600 --button="Fechar:1"

# Exibe a tela final com o resumo
printf -v FINAL_MESSAGE 'Tradução finalizada!\n\nArquivos processados:\n'

files_with_newlines_final=$(printf '%s' "$input_files" | sed 's/!/\n/g')

final_count=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ((final_count++))
    printf -v FINAL_MESSAGE '%s%d. %s\n' "$FINAL_MESSAGE" "$final_count" "$(basename "$file")"
done <<< "$files_with_newlines_final"

printf -v FINAL_MESSAGE '%s\nTotal: %d arquivo(s)\n\nArquivos traduzidos salvos com sufixo '"'"'.pt-BR.srt'"'"'\n\nDica: O cache de traduções acelera futuras traduções.\nCache salvo em: %s\n\nLog salvo em:\n%s' "$FINAL_MESSAGE" "$final_count" "$CACHE_FILE" "$LOGFILE"

yad --info --title="Conclusão" --text="$FINAL_MESSAGE" --width=600 --timeout=5 --timeout-indicator=bottom

log "Script finalizado."
exit 0