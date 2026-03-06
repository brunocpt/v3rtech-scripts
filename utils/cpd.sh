#!/usr/bin/env bash
# ==============================================================================
# Script: cpd.sh
# Versão: 5.0.0
# Data: 2026-03-06
# Objetivo: Movimentação de downloads concluídos do NAS para diretório local
# ==============================================================================

set -u

THREADS=4

src_dir="/mnt/LAN/Downloads/complete"
dest_dir="/mnt/trabalho/Downloads"
mount_point="/mnt/LAN/Downloads"

LOCKFILE="/tmp/cpd.lock"

log_dir="$HOME/logs"
mkdir -p "$log_dir"

log_file="$log_dir/cpd-$(date '+%Y-%m-%d_%H-%M-%S').log"

log(){ echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"; }

# ------------------------------------------------------------------------------
# LOCK
# ------------------------------------------------------------------------------

if [ -f "$LOCKFILE" ]; then
  echo "cpd já está em execução."
  exit 1
fi

trap 'rm -f "$LOCKFILE"' EXIT
touch "$LOCKFILE"

# ------------------------------------------------------------------------------
# MOUNT
# ------------------------------------------------------------------------------

mount_dir(){

if ! mountpoint -q "$mount_point"; then
  log "Montando $mount_point"
  mount "$mount_point" || {
      log "Erro ao montar $mount_point"
      yad --error --text="Erro ao montar $mount_point"
      exit 1
  }
fi

}

umount_dir(){

mountpoint -q "$mount_point" && umount "$mount_point"

}

# ------------------------------------------------------------------------------
# LIMPEZA
# ------------------------------------------------------------------------------

remove_empty_subdirs(){

log "Removendo diretórios vazios"

find "$src_dir" \
-mindepth 1 \
-type d \
-empty \
-delete

mkdir -p "$src_dir"

}

# ------------------------------------------------------------------------------
# TRANSFERÊNCIA PARALELA
# ------------------------------------------------------------------------------

parallel_rsync(){

log "Construindo lista de arquivos"

file_list=$(mktemp)

find "$src_dir" -type f -print0 > "$file_list"

total=$(tr -cd '\0' < "$file_list" | wc -c)

log "Arquivos encontrados: $total"

parallel -0 -j "$THREADS" --line-buffer < "$file_list" '
echo "#Transferindo ({#}/'"$total"'): {/.}"
rsync \
--partial \
--inplace \
--size-only \
--human-readable \
--update \
--remove-source-files \
{} "'"$dest_dir"'" >> "'"$log_file"'" 2>&1
'

rm "$file_list"

}

# ------------------------------------------------------------------------------
# EXECUÇÃO
# ------------------------------------------------------------------------------

log "=================================================="
log "INICIANDO OPERAÇÃO CPD"

(
echo "#Limpando queue do Transmission"
log "Executando limpeza do Transmission"

if ! /mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/utils/truenas_transmission_clear.sh >> "$log_file" 2>&1; then
   log "Erro ao limpar Transmission"
   exit 1
fi

echo "#Montando origem"
mount_dir

echo "#Movendo downloads"
parallel_rsync

echo "#Removendo diretórios vazios"
remove_empty_subdirs

echo "#Desmontando origem"
umount_dir

echo "#Concluído"

) | yad --progress \
--title="Movendo Downloads Concluídos" \
--text="Transferindo downloads..." \
--width=650 \
--pulsate \
--auto-close \
--no-buttons \
2>/dev/null || {

yad --error \
--title="Falha na operação" \
--text="Erro durante execução.\n\nVeja o log:\n$log_file"

umount_dir
exit 1

}

log "Operação CPD concluída com sucesso"
log "=================================================="

exit 0