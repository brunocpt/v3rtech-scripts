#!/usr/bin/env bash
# ==============================================================================
# Script: cpd.sh
# Versão: 5.1.0 (Corrigida)
# Data: 2026-03-07
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
export -f log
export log_file src_dir dest_dir

# ------------------------------------------------------------------------------
# FUNÇÃO DE TRANSFERÊNCIA (EXPORTADA PARA O PARALLEL)
# ------------------------------------------------------------------------------

do_transfer() {
    local file="$1"
    local total="$2"
    local count="$3"

    # Calcula o caminho relativo
    local rel="${file#$src_dir/}"
    local dest="$dest_dir/$rel"

    mkdir -p "$(dirname "$dest")"

    echo "#Transferindo ($count/$total): ${file##*/}"

    rsync --partial --inplace --whole-file --size-only \
          --human-readable --update --no-times --omit-dir-times \
          --remove-source-files "$file" "$dest" >> "$log_file" 2>&1
}
export -f do_transfer

# ------------------------------------------------------------------------------
# LÓGICA DE EXECUÇÃO
# ------------------------------------------------------------------------------

if [ -f "$LOCKFILE" ]; then
  echo "cpd já está em execução."
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
    sleep 2 # Aguarda liberação de descritores de arquivo
    if mountpoint -q "$mount_point"; then
        umount -l "$mount_point" || log "Aviso: Falha ao desmontar $mount_point"
    fi
}

parallel_rsync(){
    log "Construindo lista de arquivos"
    # Usa array para contar arquivos com segurança (lida com espaços)
    mapfile -d '' files < <(find "$src_dir" -type f -print0)
    total=${#files[@]}
    log "Arquivos encontrados: $total"

    if [ "$total" -eq 0 ]; then
        return
    fi

    # Passa a lista para o GNU Parallel
    printf "%s\0" "${files[@]}" | parallel -0 -j "$THREADS" --line-buffer \
        do_transfer {} "$total" "{#}"
}

remove_empty_subdirs(){
    log "Removendo diretórios vazios"
    find "$src_dir" -mindepth 1 -type d -empty -delete
    mkdir -p "$src_dir"
}

# ------------------------------------------------------------------------------
# MAIN LOOP COM YAD
# ------------------------------------------------------------------------------

log "=================================================="
log "INICIANDO OPERAÇÃO CPD"

(
    echo "#Limpando Transmission"
    # Caminho do seu script de utilidades v3rtech
    /mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/utils/truenas_transmission_clear.sh >> "$log_file" 2>&1

    echo "#Montando origem"
    mount_dir

    echo "#Movendo downloads"
    parallel_rsync

    echo "#Limpando diretórios"
    remove_empty_subdirs

    echo "#Desmontando"
    umount_dir

    echo "100"
    echo "#Concluído"
) | yad --progress --title="CPD v5.1" --text="Iniciando..." \
    --width=600 --auto-close --no-buttons --pulsate 2>/dev/null

log "Operação concluída"
log "=================================================="
