#!/bin/bash

# Diretório de log
log_file="$HOME/cpd.log"

# --- FUNÇÕES (com export para máxima compatibilidade) ---
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

mount_dir() {
    local dir=$1
    if ! mountpoint -q "$dir"; then
        sudo mount "$dir" && log_message "Montado o diretório $dir" || {
            log_message "Erro ao montar $dir"
            yad --error --title="Erro Crítico de Montagem" --text="Erro ao montar $dir.\nA operação não pode continuar." 2>/dev/null
            exit 1
        }
    else
        log_message "Diretório $dir já está montado"
    fi
}
export -f mount_dir

umount_dir() {
    local dir=$1
    if mountpoint -q "$dir"; then
        sudo umount "$dir" && log_message "Desmontado o diretório $dir" || {
            yad --warning --title="Aviso ao Desmontar" --text="Não foi possível desmontar $dir.\nPode ser necessário desmontá-lo manualmente." 2>/dev/null
            log_message "Erro ao desmontar $dir"
        }
    else
        log_message "Diretório $dir já está desmontado"
    fi
}
export -f umount_dir

remove_empty_subdirs() {
    local dir_to_clean=$1
    echo "#Limpando diretórios vazios na origem..."
    log_message "Removendo subpastas vazias em $dir_to_clean"
    find "$dir_to_clean" -depth -type d -empty -delete
    mkdir -p "$dir_to_clean" # Garante que o diretório principal exista
    log_message "Subpastas vazias removidas."
}
export -f remove_empty_subdirs
# --- FIM DAS FUNÇÕES ---


# --- EXECUÇÃO PRINCIPAL ---

log_message "=================================================="
log_message "Iniciando operação CPD - Movendo downloads"

# Definindo os diretórios
src_dir="/mnt/LAN/Downloads/complete/"
dest_dir="/mnt/trabalho/Downloads/"
mount_point="/mnt/LAN/Downloads/"

# A única janela do script.
# A limpeza final foi movida para DENTRO deste bloco.
(
    log_message "Executando o script de limpeza do Transmission..."
    echo "#Executando limpeza do Transmission..."

    /usr/local/share/scripts/Geral/truenas_transmission_clear.sh
    if [[ $? -ne 0 ]]; then
        log_message "ERRO ao executar o script de limpeza do Transmission."
        echo "#!!! ERRO ao limpar o query do Transmission. Abortando. !!!"
        exit 1
    fi
    log_message "Script de limpeza do Transmission executado com sucesso."

    echo "#Montando diretório de origem..."
    mount_dir "$mount_point"

    echo "#Movendo arquivos de '$src_dir'..."
    log_message "Iniciando rsync de $src_dir para $dest_dir"

    rsync -rltD --update --remove-source-files --exclude-from=/usr/local/share/scripts/Geral/exclude-list.txt --info=name1 "$src_dir" "$dest_dir" | while IFS= read -r line; do
        [ -n "$line" ] && echo "#$line"
    done

    rsync_status=${PIPESTATUS[0]}
    if [ $rsync_status -ne 0 ]; then
        log_message "ERRO ao mover arquivos (rsync código: $rsync_status)"
        echo "#!!! ERRO durante a transferência dos arquivos. !!!"
        exit 1 # Aciona o bloco de falha do YAD
    fi
    log_message "Arquivos movidos com sucesso."

    # --- LIMPEZA E DESMONTAGEM MOVIDAS PARA O FINAL DO PROCESSO BEM-SUCEDIDO ---
    remove_empty_subdirs "$src_dir"

    echo "#Desmontando diretório..."
    umount_dir "$mount_point"
    # --- FIM DA SEÇÃO MOVIDA ---

    echo "#Operação concluída com sucesso."

) | yad --progress \
      --title="Movendo Downloads Concluídos" \
      --text="<big>Operação em andamento...</big>\n<i>Movendo arquivos de Downloads...</i>" \
      --width=700 \
      --height=180 \
      --text-align=left \
      --pulsate \
      --auto-close \
      --no-buttons  2>/dev/null || {
        # Este bloco só é executado se houver uma falha (exit 1).
        # A desmontagem também é chamada aqui para garantir a limpeza em caso de erro.
        yad --error --title="FALHA NA OPERAÇÃO" --width=450 --text="<b>A operação falhou!</b>\n\nOcorreu um erro durante a execução.\n\nConsulte o log para mais detalhes:\n<b>$log_file</b>" 2>/dev/null
        umount_dir "$mount_point"
        exit 1
      }

# O script principal agora só precisa registrar o sucesso final.
log_message "Operação CPD concluída com sucesso."
log_message "=================================================="

exit 0

