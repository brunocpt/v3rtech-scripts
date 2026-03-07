#!/usr/bin/env bash
# ==============================================================================
# Script: cpv.sh
# Versão: 6.1.0 (Corrigida)
# Data: 2026-03-07
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
Animacoes Comedia Criancas Cursos Documentarios
Filmes Musicais Musicas SeriesCriancas Shows TVSeries XXX
)

start_time=$(date +%s)

log(){ echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"; }
export -f log
export log_file src_dir dest_dir

# ------------------------------------------------------------------------------
# FUNÇÃO DE TRANSFERÊNCIA (PRESERVA ESTRUTURA)
# ------------------------------------------------------------------------------

do_transfer_video() {
    local file="$1"
    local total="$2"
    local count="$3"

    # Calcula o caminho relativo (ex: TVSeries/Sheriff Country/Season 01/arquivo.mkv)
    local rel="${file#$src_dir/}"
    local dest_path="$dest_dir/$rel"

    # Cria a estrutura de pastas no destino antes de mover
    mkdir -p "$(dirname "$dest_path")"

    echo "#Transferindo ($count/$total): ${file##*/}"

    rsync --partial --inplace --whole-file --size-only \
          --human-readable --update --no-times --omit-dir-times \
          --remove-source-files "$file" "$dest_path" >> "$log_file" 2>&1
}
export -f do_transfer_video

# ------------------------------------------------------------------------------
# LÓGICA DE EXECUÇÃO
# ------------------------------------------------------------------------------

if [ -f "$LOCKFILE" ]; then
  echo "cpv já está em execução."
  exit 1
fi

trap 'rm -f "$LOCKFILE"' EXIT
touch "$LOCKFILE"

mount_dir(){
  if ! mountpoint -q "$mount_point"; then
    log "Montando $mount_point"
    mount "$mount_point" || { log "Erro ao montar"; exit 1; }
  fi
}

umount_dir(){
  sleep 2
  if mountpoint -q "$mount_point"; then
    umount -l "$mount_point" || log "Aviso: Falha ao desmontar $mount_point"
  fi
}

remove_empty_subdirs(){
  log "Removendo diretórios vazios..."
  for d in "${MAIN_DIRS[@]}"; do
    base="$src_dir/$d"
    [ -d "$base" ] || continue
    find "$base" -mindepth 1 -type d -empty -delete >> "$log_file" 2>&1
  done
}

parallel_rsync(){
    log "Construindo lista de arquivos"

    mapfile -d '' files < <(find "$src_dir" -type f \
        \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.srt" \) \
        -print0)

    total=${#files[@]}
    log "Arquivos para transferir: $total"

    if [ "$total" -eq 0 ]; then
        return
    fi

    printf "%s\0" "${files[@]}" | parallel -0 -j "$THREADS" --line-buffer \
        do_transfer_video {} "$total" "{#}"
}

# ------------------------------------------------------------------------------
# EXECUÇÃO COM YAD
# ------------------------------------------------------------------------------

log "======================================"
log "INICIANDO OPERAÇÃO CPV"

mount_dir

(
    echo "#Executando fbr..."
    log "Executando fbr"
    # Chamada do seu script de renomeação
    /mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/utils/fbr >> "$log_file" 2>&1

    echo "#Transferindo arquivos..."
    parallel_rsync

    echo "100"
    echo "#Concluído"
) | yad --progress --title="CPV - Transferência de Vídeos" \
    --text="Processando..." --width=600 --pulsate \
    --auto-close --no-buttons 2>/dev/null || {

    yad --error --text="Erro durante execução.\n\nVeja o log:\n$log_file"
    umount_dir
    exit 1
}

remove_empty_subdirs
umount_dir

end_time=$(date +%s)
duration=$((end_time - start_time))
log "Concluído em ${duration}s"
log "======================================"
