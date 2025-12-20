#!/bin/bash

# Diretório de log
log_file="$HOME/cpbackupcloud.log"

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
      zenity --error --text="Erro ao montar $dir"
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
      zenity --error --text="Erro ao desmontar $dir"
      log_message "Erro ao desmontar $dir"
      exit 1
    }
  else
    log_message "Diretório $dir já está desmontado"
  fi
}

# Definindo os diretórios
src_dir="/mnt/trabalho/Cloud/"
dest_dir="/mnt/LAN/BackupCloud/"
mount_point="/mnt/LAN/BackupCloud/"

# Início do log da operação
log_message "Iniciando operação CP-BACKUPCLOUD - Copiando arquivos de $src_dir para $dest_dir"

# Monta o diretório de destino
mount_dir "$mount_point"




# Executa a transferência usando rsync com Zenity para exibir o progresso
# Inicia o rsync em segundo plano e captura o PID
(
  rsync -a --update --verbose --no-perms --no-owner --no-group --exclude=".*" --info=progress2,name "$src_dir" "$dest_dir" | \
  while read -r line; do
    echo "# $line"  # Exibe cada arquivo sendo copiado no Zenity
    echo "50"       # Mantém a barra de progresso em 50% para indicar atividade
  done
) | zenity --progress --title="Copiando arquivos para $dest_dir" \
           --text="Iniciando cópia...\nLog: $log_file" \
           --width=500 --height=100 --auto-close --pulsate

# Monitora o progresso com Zenity e captura o cancelamento
(
  while kill -0 "$rsync_pid" 2>/dev/null; do
    # Atualiza Zenity com status parcial
    echo "# Copiando arquivos de $src_dir para $dest_dir\nLog: $log_file"
    sleep 1
  done
) | zenity --progress --title="Copiando Arquivos" --text="Iniciando..." \
           --width=500 --height=100 --pulsate --auto-close

# Verifica se o usuário cancelou a operação
if [[ $? -eq 1 ]]; then
  kill "$rsync_pid" 2>/dev/null  # Termina o rsync
  zenity --warning --text="Operação cancelada pelo usuário. Verifique o log em $log_file para detalhes." --timeout=10
  log_message "Operação cancelada pelo usuário"
  umount_dir "$mount_point"
  exit 1
fi

# Verifica se houve erro no rsync
wait "$rsync_pid"
if [[ $? -ne 0 ]]; then
  zenity --error --text="Erro ao copiar arquivos de $src_dir para $dest_dir. Verifique o log em $log_file." --timeout=10
  log_message "Erro ao copiar arquivos de $src_dir para $dest_dir"
else
  zenity --info --text="Arquivos copiados com sucesso! Log: $log_file" --timeout=10
  log_message "Arquivos copiados com sucesso de $src_dir para $dest_dir"
fi

# Desmonta o diretório de destino
umount_dir "$mount_point"

# Finalização do log da operação
log_message "Operação CP-BACKUPCLOUD concluída"

exit 0

