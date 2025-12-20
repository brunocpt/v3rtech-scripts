#!/bin/bash

# --- CONFIGURAÇÕES ---
log_file="$HOME/restore_mirror.log"
excludes_rel_path="Cloud/Compartilhado/Linux/scripts/Geral/exclude-list.txt"
default_source_paths=(/run/media/"$USER"/Mirror /media/"$USER"/Mirror)
dest_dir="/mnt/trabalho"

# --- FUNÇÕES ---
log_message() {
  local message=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

find_mirror_mount() {
  for path in "${default_source_paths[@]}"; do
    if mountpoint -q "$path"; then
      echo "$path"
      return
    fi
  done
  return 1
}

# --- EXECUÇÃO ---
log_message "=================================================="
log_message "Iniciando restauração de backup do Mirror para $dest_dir"

mirror_mount_point=$(find_mirror_mount)

if [[ -z "$mirror_mount_point" ]]; then
  yad --error \
      --title="Dispositivo não encontrado" \
      --text="<b>O HD externo Mirror não está montado.</b>\n\nMonte-o e tente novamente." \
      --width=400 \
      --center 2>/dev/null
  log_message "Erro: Mirror não está montado."
  exit 1
fi

log_message "Mirror encontrado em $mirror_mount_point"
src_dir="$mirror_mount_point/"
excludes="$mirror_mount_point/$excludes_rel_path"

if [[ ! -f "$excludes" ]]; then
  yad --error \
      --title="Lista de Exclusão Ausente" \
      --text="Arquivo de exclusão não encontrado:\n<b>$excludes</b>" \
      --width=500 2>/dev/null
  log_message "Erro: Lista de exclusão não encontrada em $excludes"
  exit 1
fi

# --- EXECUÇÃO DO RSYNC COM BARRA DE PROGRESSO (ESTILO CPMIRROR) ---
(
  echo "#Restaurando backup de $src_dir para $dest_dir"
  log_message "Iniciando rsync com exclusões"

  rsync -rt --copy-links --update \
    --delete \
    --no-perms --no-owner --no-group \
    --info=progress2,name1 \
    --exclude-from="$excludes" \
    "$src_dir" "$dest_dir" | \
  while IFS= read -r line; do
    [ -n "$line" ] && echo "# $line"
  done

  rsync_status=${PIPESTATUS[0]}
  if [[ $rsync_status -ne 0 ]]; then
    echo "#!!! ERRO durante sincronização (Código: $rsync_status) !!!"
    log_message "ERRO ao restaurar de $src_dir para $dest_dir (Código $rsync_status)"
    exit $rsync_status
  else
    echo "#Restauração concluída com sucesso."
    log_message "Restauração finalizada com sucesso"
  fi
) | yad --progress \
        --title="Restauração do Mirror" \
        --text="<big><b>Restaurando backup do HD externo</b></big>\n\nAguarde enquanto os arquivos são copiados..." \
        --width=600 \
        --height=200 \
        --text-align=left \
        --pulsate \
        --no-buttons \
        --auto-close \
        --center \
        2>/dev/null

# --- TRATAMENTO DE RESULTADO ---
if [[ $? -ne 0 ]]; then
  yad --warning \
      --title="Restauração incompleta" \
      --text="Ocorreu uma falha ou o usuário cancelou a operação.\n\nConsulte o log:\n<b>$log_file</b>" \
      --timeout=10 \
      --width=400 \
      --center 2>/dev/null
  log_message "Restauração cancelada ou falhou"
  exit 1
else
  yad --info \
      --title="Restauração concluída" \
      --text="<b>Backup restaurado com sucesso!</b>\n\nDestino: <b>$dest_dir</b>\nLog: <b>$log_file</b>" \
      --timeout=10 \
      --width=400 \
      --center 2>/dev/null
  log_message "Restauração concluída com sucesso"
fi

exit 0

