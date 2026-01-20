#!/bin/bash

# --- VARIÁVEIS E FUNÇÕES ESSENCIAIS ---
start_time=$(date +%s)
log_file="$HOME/cpv_completo.log"
src_dir="/mnt/trabalho/Videos/"
dest_dir="/mnt/LAN/Videos/"
mount_point="/mnt/LAN/Videos/"

log_message() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"; }
mount_dir() { if ! mountpoint -q "$1"; then sudo mount "$1" && log_message "Montado $1" || { yad --error --text="Erro ao montar $1" 2>/dev/null; log_message "ERRO ao montar $1"; exit 1; }; else log_message "$1 já montado"; fi; }
umount_dir() { if mountpoint -q "$1"; then sudo umount "$1" && log_message "Desmontado $1" || { yad --error --text="Erro ao desmontar $1" 2>/dev/null; log_message "ERRO ao desmontar $1"; exit 1; }; else log_message "$1 já desmontado"; fi; }
rename_subtitles_after_filebot() {
  echo "#Renomeando legendas para o padrão .pt-BR.srt..."
  find "$1" -type f -iname "*.srt" | while read -r f; do
    [[ "$f" != *.pt-BR.srt ]] && mv -f "$f" "${f%.srt}.pt-BR.srt" && echo "#Legenda: $(basename "$f") -> $(basename "${f%.srt}.pt-BR.srt")"
  done
  echo "#Renomeação de legendas concluída."
}

# ==============================================================================
# NOVA FUNÇÃO DE LIMPEZA - A SOLUÇÃO
# ==============================================================================
remove_empty_subdirs() {
  log_message "Iniciando limpeza recursiva de diretórios vazios em '$1'..."
  # -depth: processa o conteúdo de um diretório ANTES do próprio diretório (de dentro para fora).
  # -mindepth 2: começa a procurar a partir dos subdiretórios das categorias (ex: dentro de /Filmes/),
  # protegendo as pastas de categoria principais de serem apagadas.
  # -exec rmdir: remove os diretórios vazios encontrados.
  find "$1" -mindepth 2 -type d -empty -depth -exec rmdir {} \; >> "$log_file" 2>&1
  log_message "Limpeza de diretórios vazios concluída."
}
# ==============================================================================


# --- EXECUÇÃO PRINCIPAL ---
log_message "=================================================="
log_message "INICIANDO OPERAÇÃO CPV"
mount_dir "$mount_point"

(
  echo "#Iniciando Etapa 1: Renomeação com FileBot..."
  log_message "Iniciando Etapa 1: Renomeação com FileBot."

  for dir in "$src_dir"/*/; do
    [ -d "${dir}" ] || continue
    category=$(basename "$dir")
    echo "#Processando categoria: $category..."
    log_message "Processando categoria: $category"

    filebot_cmd="flatpak run net.filebot.FileBot -rename \"$dir\" -non-strict"
    case "$category" in
      "Criancas"|"SeriesCriancas") eval $filebot_cmd --format "\"{n} ({y})/{n} ({y}) [{vf}]\"" --db TheMovieDB --lang pt >> "$log_file" 2>&1 ;;
      "TVSeries") eval $filebot_cmd --format "\"{n}/Season {s.pad(2)}/{n}.s{s.pad(2)}e{e.pad(2)}.{t}.[{airdate.format('yyyy.MM.dd')}]\"" --db TheTVDB >> "$log_file" 2>&1 ;;
      "Cursos") log_message "Diretório $category ignorado." && echo "#Categoria '$category' ignorada." ;;
      "XXX") log_message "Diretório $category ignorado." && echo "#Categoria '$category' ignorada." ;;
      *) eval $filebot_cmd --format "\"{n} ({y})/{n} ({y}) [{vf}]\"" --db TheMovieDB --lang en >> "$log_file" 2>&1 ;;
    esac
    if [ $? -ne 0 ]; then log_message "AVISO: FileBot falhou no diretório $category."; echo "#AVISO: FileBot falhou em '$category'."; fi
  done

  rename_subtitles_after_filebot "$src_dir"
  log_message "Etapa 1 (Renomeação) concluída."

  echo "#Etapa 1 concluída. Iniciando transferência de arquivos..."
  log_message "Iniciando Etapa 2: Transferência com rsync."

  rsync -rltD --info=name1 --update --remove-source-files --exclude-from=/usr/local/share/scripts/v3rtech-scripts/configs/exclude-list.txt "$src_dir" "$dest_dir" | while IFS= read -r line; do
      [ -n "$line" ] && echo "#$line"
  done

  rsync_status=${PIPESTATUS[0]}
  if [ $rsync_status -ne 0 ]; then
    log_message "ERRO: rsync falhou com código $rsync_status."
    exit 1
  fi
  log_message "Etapa 2 (Transferência) concluída."

) | yad --progress \
      --title="Executando Operação de Vídeos" \
      --text="<big>Operação em andamento...</big>\n<i>Aguarde, o processo pode levar vários minutos.</i>" \
      --width=700 \
      --height=180 \
      --text-align=left \
      --pulsate \
      --auto-close \
      --no-buttons  2>/dev/null || {
        yad --error --title="FALHA NA OPERAÇÃO" --width=450 --text="<b>A operação falhou!</b>\n\nOcorreu um erro durante a execução.\n\nConsulte o log para mais detalhes:\n<b>$log_file</b>"  2>/dev/null
        umount_dir "$mount_point"
        exit 1
      }

# --- TAREFAS FINAIS SILENCIOSAS ---
log_message "Iniciando Etapa Final: Limpeza."
remove_empty_subdirs "$src_dir"
umount_dir "$mount_point"

end_time=$(date +%s)
duration=$((end_time - start_time))
duration_formatted=$(printf "%02d min %02d seg" $((duration / 60)) $((duration % 60)))
log_message "=================================================="
log_message "OPERAÇÃO CONCLUÍDA com sucesso em $duration_formatted"
log_message "=================================================="

exit 0

