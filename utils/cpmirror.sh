#!/bin/bash

# Diretório de log
log_file="$HOME/cpmirror.log"

# Função para escrever no log
log_message() {
  local message=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Diretório fonte
src_dir="/mnt/trabalho/"

# --- MUDANÇA 1: Detecção de múltiplos pontos de montagem ---
find_mount_points() {
  # Cria um array (lista) com todos os pontos de montagem que possuem o Label 'Mirror'
  mapfile -t mount_points < <(lsblk -o LABEL,MOUNTPOINT | grep -w 'Mirror' | awk '{print $2}')
  
  if [[ ${#mount_points[@]} -eq 0 ]]; then
    yad --error \
        --title="Disco Mirror não encontrado" \
        --text="Nenhum disco com rótulo <b>Mirror</b> foi encontrado montado.\n\nVerifique as conexões." \
        --width=400 2>/dev/null
    log_message "Erro: Nenhum disco Mirror encontrado."
    exit 1
  else
    # Lista no log quantos foram encontrados
    log_message "Discos Mirror encontrados: ${#mount_points[@]} dispositivos em: ${mount_points[*]}"
  fi
}

# Início do log da operação global
log_message "Iniciando operação MULTI-CPMIRROR - Fonte: $src_dir"

# Busca os HDs
find_mount_points

# --- Início do bloco visual (YAD) ---
(
  # --- MUDANÇA 2: Loop para processar cada HD encontrado ---
  count=1
  total=${#mount_points[@]}

  for dest_dir in "${mount_points[@]}"; do
    
    echo "#Verificando disco $count de $total: $dest_dir"
    log_message ">>> Iniciando sincronização para o destino ($count/$total): $dest_dir"

    # Pequena pausa para o usuário ler a mudança de status na tela
    sleep 1

    echo "#Sincronizando: $dest_dir"
    
    # Executa o rsync
    rsync -razv --update --delete \
    --info=progress2,name1 \
    --exclude-from=/usr/local/share/scripts/v3rtech-scripts/configs/exclude-list.txt "$src_dir" "$dest_dir" | \
    while IFS= read -r line; do
       # Filtra linhas vazias e envia para o YAD atualizar o texto
       [ -n "$line" ] && echo "# [$count/$total] $dest_dir: $line"
    done

    rsync_status=${PIPESTATUS[0]}
    
    if [[ $rsync_status -ne 0 ]]; then
      log_message "ERRO ao espelhar para $dest_dir (Código: $rsync_status)"
      echo "#!!! ERRO em $dest_dir (Código: $rsync_status) !!!"
      # Não sai do script (exit), tenta fazer o próximo HD se houver erro neste
    else
      log_message "Sucesso ao espelhar para $dest_dir"
      echo "#Concluído: $dest_dir"
    fi
    
    ((count++))
    echo "---------------------------------------------------" >> "$log_file"
  done
  
  echo "#Todas as sincronizações foram finalizadas."

) | yad --progress \
        --title="Espelhando Arquivos para Múltiplos Mirrors" \
        --text="<big>Iniciando espelhamento...</big>" \
        --width=600 \
        --height=250 \
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

# --- Finalização ---

# Informa que a sincronização de cache (sync) está ocorrendo
yad --info \
    --title="Gravando Dados" \
    --text="<b>Finalizando gravação nos discos</b>\n\nAguarde enquanto o cache é esvaziado para os HDs.\nIsso garante que os dados não sejam corrompidos." \
    --no-buttons \
    --timeout=2 \
    --width=450 \
    --center 2>/dev/null &

log_message "Executando sync do sistema..."
sync
log_message "Sync do sistema concluído."

# Conclusão
log_message "Operação MULTI-CPMIRROR finalizada"
exit 0