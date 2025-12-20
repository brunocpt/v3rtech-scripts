#!/bin/bash

# Diretório de log
log_file="$HOME/cpplaylist.log"

# Função para escrever no log
log_message() {
  local message=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Função para encontrar os pontos de montagem de todas as unidades "PLAYLIST"
find_mount_points() {
  mapfile -t mount_points < <(lsblk -o LABEL,MOUNTPOINT | grep -w 'PLAYLIST' | awk '{print $2}')
  if [[ ${#mount_points[@]} -eq 0 ]]; then
    zenity --error --text="Nenhuma unidade PLAYLIST montada. Verifique as conexões."
    log_message "Erro: Nenhuma unidade PLAYLIST montada."
    exit 1
  else
    log_message "Unidades PLAYLIST montadas encontradas: ${mount_points[*]}"
  fi
}

# Definindo o diretório fonte
src_dir="/mnt/trabalho/Cloud/Compartilhado/Multimidia/Musicas/Playlists/"

# Início do log da operação
log_message "Iniciando operação CPPLAYLIST - Espelhando arquivos de $src_dir para as unidades PLAYLIST"

# Encontra os pontos de montagem das unidades PLAYLIST
find_mount_points

# Executa o espelhamento para cada unidade PLAYLIST
for dest_dir in "${mount_points[@]}"; do
  log_message "Preparando para espelhar arquivos para $dest_dir"

  # Executa a transferência usando rsync e exibe a lista de arquivos sendo copiados
  (
    rsync -a -t -u --delete --no-perms --no-owner --no-group --info=progress2,name "$src_dir" "$dest_dir" 2>&1 | tee -a "$log_file" | \
    while read -r line; do
      echo "# $line"  # Exibe cada arquivo sendo copiado no Zenity
      echo "50"       # Mantém a barra de progresso em 50% para indicar atividade
    done
  ) | zenity --progress --title="Espelhando para $dest_dir" \
             --text="Iniciando cópia...\nLog: $log_file" \
             --width=500 --height=100 --auto-close --pulsate

  # Captura o código de saída do rsync
  rsync_exit_code=${PIPESTATUS[0]}

  # Verifica se o usuário cancelou a operação
  if [[ $? -eq 1 ]]; then
    pkill -P $$ rsync  # Termina o rsync ao cancelar no Zenity
    zenity --warning --text="Operação cancelada pelo usuário para $dest_dir. Verifique o log em $log_file para detalhes."
    log_message "Operação cancelada pelo usuário para $dest_dir"
    continue
  fi

  # Verifica o código de saída do rsync
  if [[ $rsync_exit_code -ne 0 ]]; then
    zenity --error --text="Erro ao espelhar arquivos para $dest_dir. Verifique o log em $log_file."
    log_message "Erro ao espelhar arquivos para $dest_dir"
  else
    log_message "Arquivos espelhados com sucesso de $src_dir para $dest_dir"
  fi
done

# Finalização do log da operação
log_message "Operação CPPLAYLIST concluída"

exit 0

