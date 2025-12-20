#!/bin/bash

# Diretório de log
log_file="$HOME/cpdns320l.log"

# Função para escrever no log
log_message() {
  local message=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Função para montar diretório
mount_dir() {
  local dir=$1
  if ! mountpoint -q "$dir"; then
    sudo mount "$dir" && log_message "Montado o diretório $dir" || {
      yad --error \
          --title="Erro ao Montar" \
          --text="Erro ao montar o diretório:\n<b>$dir</b>" \
          --width=400 2>/dev/null
      log_message "Erro ao montar $dir"
      exit 1
    }
  else
    log_message "Diretório $dir já está montado"
  fi
}

# Função para desmontar diretório
umount_dir() {
  local dir=$1
  if mountpoint -q "$dir"; then
    sudo umount "$dir" && log_message "Desmontado o diretório $dir" || {
      yad --error \
          --title="Erro ao Desmontar" \
          --text="Erro ao desmontar o diretório:\n<b>$dir</b>" \
          --width=400 2>/dev/null
      log_message "Erro ao desmontar $dir"
      exit 1
    }
  else
    log_message "Diretório $dir já está desmontado"
  fi
}

# Definindo os diretórios
src_dir="/mnt/trabalho/Cloud/"
dest_dir="/mnt/LAN/DNS320L/BackupCloud/"
mount_point="/mnt/LAN/DNS320L/"

# Início do log da operação
log_message "Iniciando operação CPDNS320L - Copiando arquivos de $src_dir para $dest_dir"

# Monta o diretório de rede, se necessário
mount_dir "$mount_point"

# Executa a transferência com barra de progresso
(
  echo "#Iniciando cópia de $src_dir para $dest_dir"
  log_message "Rsync iniciado"

  rsync -rt --copy-links --update --delete \
    --no-perms --no-owner --no-group \
    --info=progress2,name1 "$src_dir" "$dest_dir" | \
  while IFS= read -r line; do
    [ -n "$line" ] && echo "# $line"
  done

  rsync_status=${PIPESTATUS[0]}
  if [[ $rsync_status -ne 0 ]]; then
    echo "#!!! ERRO durante sincronização (Código: $rsync_status) !!!"
    log_message "ERRO ao copiar de $src_dir para $dest_dir (Código $rsync_status)"
    exit $rsync_status
  else
    echo "#Cópia concluída com sucesso"
    log_message "Cópia finalizada com sucesso"
  fi

) | yad --progress \
        --title="Cópia para DNS320L" \
        --text="<big><b>Copiando arquivos para o NAS</b></big>\n\nAguarde enquanto os arquivos são transferidos..." \
        --width=600 \
        --height=200 \
        --text-align=left \
        --pulsate \
        --no-buttons \
        --auto-close \
        2>/dev/null

# Verifica status da execução anterior
status=$?
if [[ $status -ne 0 ]]; then
  pkill -P $$ rsync
  yad --warning \
      --title="Operação cancelada" \
      --text="A operação foi <b>cancelada ou falhou</b>.\n\nConsulte o log:\n<b>$log_file</b>" \
      --width=400 \
      --timeout=10 2>/dev/null
  log_message "Operação cancelada ou erro detectado (status: $status)"
  umount_dir "$mount_point"
  exit 1
else
  yad --info \
      --title="Cópia Concluída" \
      --text="<b>Arquivos copiados com sucesso!</b>\n\nLog salvo em:\n<b>$log_file</b>" \
      --width=400 \
      --timeout=10 2>/dev/null
fi

# Desmonta o diretório
umount_dir "$mount_point"

# Finaliza o log
log_message "Operação CPDNS320L concluída com sucesso"
exit 0

