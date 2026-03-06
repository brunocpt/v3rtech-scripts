#!/usr/bin/env bash
# ==============================================================================
# Script: cpv.sh
# Versão: 6.0.0
# Data: 2026-03-06
# Objetivo: Orquestrar renomeação (fbr) e transferência paralela para SMB.
# ==============================================================================

set -u

src_dir="/mnt/trabalho/Videos"
dest_dir="/mnt/LAN/Videos"
mount_point="/mnt/LAN/Videos"

THREADS=4

log_dir="$HOME/logs"
mkdir -p "$log_dir"
log_file="$log_dir/cpv-$(date '+%Y-%m-%d_%H-%M-%S').log"

LOCKFILE="/tmp/cpv.lock"

MAIN_DIRS=(
Animacoes
Comedia
Criancas
Cursos
Documentarios
Filmes
Musicais
Musicas
SeriesCriancas
Shows
TVSeries
XXX
)

start_time=$(date +%s)

log(){ echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"; }

# ------------------------------------------------------------------------------
# LOCK
# ------------------------------------------------------------------------------

if [ -f "$LOCKFILE" ]; then
  echo "cpv já está em execução."
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
    mount "$mount_point" || { log "Erro ao montar"; exit 1; }
  fi
}

umount_dir(){
  mountpoint -q "$mount_point" && umount "$mount_point"
}

# ------------------------------------------------------------------------------
# LIMPEZA
# ------------------------------------------------------------------------------

remove_empty_subdirs(){

  log "Removendo diretórios vazios..."

  for d in "${MAIN_DIRS[@]}"; do
    base="$src_dir/$d"

    [ -d "$base" ] || continue

    find "$base" \
      -mindepth 1 \
      -type d \
      -empty \
      -delete >> "$log_file" 2>&1
  done

}

# ------------------------------------------------------------------------------
# TRANSFERÊNCIA PARALELA
# ------------------------------------------------------------------------------

parallel_rsync(){

log "Construindo lista de arquivos"

file_list=$(mktemp)

find "$src_dir" -type f \
\( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.srt" \) \
-print0 > "$file_list"

total=$(tr -cd '\0' < "$file_list" | wc -c)

log "Arquivos para transferir: $total"

parallel -0 -j "$THREADS" --line-buffer < "$file_list" '
echo "#Transferindo ({#}/'"$total"'): {/.}"
rsync \
--partial \
--inplace \
--whole-file \
--size-only \
--human-readable \
--update \
--no-times \
--omit-dir-times \
--remove-source-files \
{} "'"$dest_dir"'" >> "'"$log_file"'" 2>&1
'

rm "$file_list"

}

# ------------------------------------------------------------------------------
# EXECUÇÃO
# ------------------------------------------------------------------------------

log "======================================"
log "INICIANDO OPERAÇÃO CPV"

mount_dir

(
echo "#Executando fbr..."
log "Executando fbr"

if ! /mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/utils/fbr >> "$log_file" 2>&1; then
  log "Erro no fbr"
  exit 1
fi

echo "#Transferindo arquivos..."
parallel_rsync

) | yad --progress \
--title="CPV - Transferência de Vídeos" \
--text="Processando..." \
--width=600 \
--pulsate \
--auto-close \
--no-buttons \
2>/dev/null || {

yad --error --text="Erro durante execução.\n\nVeja o log:\n$log_file"

umount_dir
exit 1

}

remove_empty_subdirs

umount_dir

end_time=$(date +%s)
duration=$((end_time - start_time))

log "Concluído em ${duration}s"