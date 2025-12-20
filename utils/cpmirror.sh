#!/bin/bash

# Diretório de log
log_file="$HOME/cpmirror.log"

# Função para escrever no log
log_message() {
  local message=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Função para encontrar o ponto de montagem do disco Mirror
find_mount_point() {
  mount_point=$(lsblk -o LABEL,MOUNTPOINT | grep -w 'Mirror' | awk '{print $2}')
  if [[ -z "$mount_point" ]]; then
    yad --error \
        --title="Disco Mirror não encontrado" \
        --text="O disco <b>Mirror</b> não está montado.\n\nVerifique a conexão e tente novamente." \
        --width=400 2>/dev/null
    log_message "Erro: O disco Mirror não está montado."
    exit 1
  else
    log_message "Disco Mirror montado em $mount_point"
  fi
}

# Diretório fonte
src_dir="/mnt/trabalho/"

# Início do log da operação
log_message "Iniciando operação CPMIRROR - Espelhando arquivos de $src_dir para Mirror"

# Encontrar ponto de montagem do destino
find_mount_point
dest_dir="$mount_point"

# Tela de progresso com saída detalhada de arquivos
(
  echo "#Espelhando de $src_dir → $dest_dir"
  log_message "Iniciando rsync de $src_dir para $dest_dir"

  rsync -rt --copy-links --update --delete \
  --no-perms --no-owner --no-group \
  --info=progress2,name1 \
  --exclude-from=/usr/local/share/scripts/Geral/exclude-list.txt "$src_dir" "$dest_dir" | \
  while IFS= read -r line; do
    [ -n "$line" ] && echo "#  $line"
  done

  rsync_status=${PIPESTATUS[0]}
  if [[ $rsync_status -ne 0 ]]; then
    log_message "ERRO ao espelhar $src_dir → $dest_dir (Código: $rsync_status)"
    echo "#!!! ERRO durante sincronização (Código: $rsync_status) !!!"
  else
    log_message "Sucesso ao espelhar $src_dir → $dest_dir"
    echo "#Espelhamento concluído com sucesso."
  fi
) | yad --progress \
        --title="Espelhando Arquivos para Mirror" \
        --text="<big>Espelhando conteúdo...</big>\n<i>Arquivos sendo copiados:</i>" \
        --width=600 \
        --height=200 \
        --text-align=left \
        --pulsate \
        --auto-close \
        --no-buttons 2>/dev/null || {
  pkill -P $$ rsync
  yad --warning \
      --title="Operação cancelada" \
      --text="A operação foi cancelada pelo usuário.\n\nConsulte o log:\n<b>$log_file</b>" \
      --width=400 2>/dev/null
  log_message "Operação cancelada pelo usuário"
  exit 1
}

# Informa que a sincronização está finalizando
yad --info \
    --title="Gravando Dados" \
    --text="<b>Finalizando gravação no disco Mirror</b>\n\nAguarde enquanto os dados são sincronizados para o disco.\nIsso pode levar alguns segundos." \
    --no-buttons \
    --timeout=1 \
    --width=450 \
    --center 2>/dev/null &

log_message "Forçando sync final..."
# Informa o usuário que o sistema está finalizando a gravação
yad --info \
  --title="Gravando Dados no Pendrive" \
  --text="<big><b>Finalizando gravação nos dispositivos</b></big>\n\nAguarde enquanto os dados são sincronizados para os pendrives.\nEssa etapa pode demorar alguns segundos, dependendo da quantidade de arquivos." \
  --no-buttons \
  --width=450 \
  --timeout=1 \
  --center 2>/dev/null &
sync
log_message "Sync concluído."

# Conclusão
log_message "Operação CPMIRROR concluída com sucesso"
exit 0

