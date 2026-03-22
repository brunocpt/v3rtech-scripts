#!/usr/bin/env bash
# ==============================================================================
# Script: cpd.sh
# Versão: 6.0.0
# Data: 2026-03-22
# Descrição: Move downloads completos do TrueNAS para o trabalho local.
#            Tenta montar via NFS (preferencial); usa CIFS como fallback.
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
# MONTAGEM COM FALLBACK NFS → CIFS
# ------------------------------------------------------------------------------

mount_dir(){
    if mountpoint -q "$mount_point"; then
        local proto
        proto=$(findmnt -n -o FSTYPE "$mount_point" 2>/dev/null || echo "desconhecido")
        log "Já montado via $proto: $mount_point"
        return 0
    fi

    log "Tentando montar via NFS: $mount_point"
    if mount -t nfs4 "$mount_point" >> "$log_file" 2>&1; then
        log "Montado via NFS"
        return 0
    fi

    log "NFS falhou — tentando CIFS como fallback"
    if mount -t cifs "$mount_point" >> "$log_file" 2>&1; then
        log "Montado via CIFS (fallback)"
        return 0
    fi

    log "Erro: não foi possível montar $mount_point (NFS e CIFS falharam)"
    exit 1
}

umount_dir(){
    sleep 2
    if mountpoint -q "$mount_point"; then
        umount -l "$mount_point" || log "Aviso: Falha ao desmontar $mount_point"
    fi
}

# ------------------------------------------------------------------------------
# LÓGICA DE EXECUÇÃO
# ------------------------------------------------------------------------------

if [ -f "$LOCKFILE" ]; then
    echo "cpd já está em execução."
    exit 1
fi

trap 'rm -f "$LOCKFILE"' EXIT
touch "$LOCKFILE"

parallel_rsync(){
    log "Construindo lista de arquivos"
    mapfile -d '' files < <(find "$src_dir" -type f -print0)
    total=${#files[@]}
    log "Arquivos encontrados: $total"

    if [ "$total" -eq 0 ]; then
        return
    fi

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
) | yad --progress --title="CPD v6.0" --text="Iniciando..." \
    --width=600 --auto-close --no-buttons --pulsate 2>/dev/null

log "Operação concluída"
log "=================================================="