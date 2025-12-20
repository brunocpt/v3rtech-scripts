#!/bin/bash

# Arquivo de log
log_file="$HOME/cpventoy.log"

# --- FUNÇÕES (Mantidas do seu script original) ---
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

mount_sos_if_needed() {
    local dir="/mnt/trabalho/SOs"
    # Se o diretório não existir, tenta montar (provável ponto de montagem remoto)
    if [[ ! -e "$dir" ]]; then
        log_message "Diretório $dir não existe localmente. Tentando montar..."
        sudo mount "$dir" && log_message "Montado o diretório de rede: $dir" || {
            log_message "Erro: Não foi possível montar o diretório $dir"
            yad --error --title="Erro Crítico de Montagem" --text="Não foi possível montar o diretório de rede:\n$dir\n\nVerifique a conexão e as permissões." 2>/dev/null
            exit 1
        }
    else
        # Se existir, verifica se é um ponto de montagem; se for, ok. Se não, assume que é uma pasta local e não tenta montar.
        if mountpoint -q "$dir"; then
            log_message "Diretório $dir já está montado."
        else
            log_message "Diretório $dir existe localmente e não é um ponto de montagem. Pulando tentativa de mount (é local)."
        fi
    fi
}

unmount_sos() {
    local dir="/mnt/trabalho/SOs"
    if mountpoint -q "$dir"; then
        sudo umount "$dir" && log_message "Desmontado o diretório de rede: $dir" || {
            log_message "Erro: Não foi possível desmontar o diretório $dir"
        }
    fi
}

find_mount_points() {
    # Usando uma variável local para retornar os valores
    local -n _mount_points_ref=$1
    mapfile -t _mount_points_ref < <(lsblk -o LABEL,MOUNTPOINT | grep -w 'Ventoy' | awk '{print $2}')
    if [[ ${#_mount_points_ref[@]} -eq 0 ]]; then
        log_message "Erro: Nenhuma unidade Ventoy montada."
        yad --error --title="Nenhuma Unidade Encontrada" --text="Nenhuma unidade com o rótulo 'Ventoy' foi encontrada montada.\n\nConecte a unidade Ventoy e tente novamente." 2>/dev/null
        exit 1
    else
        log_message "Unidades Ventoy montadas encontradas: ${_mount_points_ref[*]}"
    fi
}

# Trap para garantir que a pasta seja desmontada em caso de erro ou interrupção
#trap 'log_message "Script interrompido."; unmount_sos; exit 1' INT TERM ERR
trap 'log_message "Script interrompido."; exit 1' INT TERM ERR

# --- EXECUÇÃO PRINCIPAL ---

log_message "=================================================="
log_message "INICIANDO OPERAÇÃO CP-VENTOY"

# Prepara o ambiente silenciosamente
mount_sos_if_needed
declare -a mount_points
find_mount_points mount_points

# Definindo as pastas de origem e os destinos relativos
declare -A src_dirs=(
    ["/mnt/trabalho/SOs/"]="SOs"
    ["/mnt/trabalho/Cloud/Compartilhado/Linux/"]="Linux"
)

# A ÚNICA TELA DO SCRIPT.
# O bloco (...) agrupa todos os comandos que produzem saída para o YAD.
(
    # Itera sobre cada unidade Ventoy encontrada
    for dest_dir in "${mount_points[@]}"; do
        # Verifica permissão de escrita no destino
        if [[ ! -w "$dest_dir" ]]; then
            log_message "Erro: Sem permissão de escrita em $dest_dir. Pulando."
            echo "#AVISO: Sem permissão de escrita em $dest_dir. Pulando unidade."
            continue # Pula para a próxima unidade
        fi

        # Itera sobre cada pasta de origem a ser sincronizada
        for src_dir in "${!src_dirs[@]}"; do

            relative_dir=${src_dirs[$src_dir]}
            specific_dest_dir="$dest_dir/$relative_dir"

            # Mostra uma etapa limpa para o usuário
            echo "#Sincronizando '$relative_dir' para -> $(basename "$dest_dir")"
            log_message "Preparando para espelhar de $src_dir para $specific_dest_dir"

            # Se for necessário um subdiretório, cria-o
            if [[ -n "$relative_dir" && ! -d "$specific_dest_dir" ]]; then
                mkdir -p "$specific_dest_dir"
                log_message "Diretório criado no destino: $specific_dest_dir"
            fi

            # Executa a transferência usando rsync, com saída limpa para o YAD
            # --info=name1 para uma saída arquivo por arquivo.
            rsync -a --delete --info=name1 \
                --exclude='.git*/' \
                --exclude='.svn/' \
                --exclude='.hg/' \
                --exclude='.bzr/' \
                --exclude='__pycache__/' \
                --exclude='node_modules/' \
                --exclude='.cache/' \
                --exclude='cache/' \
                --exclude='.idea/' \
                --exclude='.vscode/' \
                --exclude='.Trash*/' \
                --exclude='.recycle*/' \
                --exclude='.thumbnails/' \
                --exclude='*.bak' \
                --exclude='*.old' \
                --exclude='*.tmp' \
                --exclude='*.temp' \
                --exclude='~*' \
                --exclude='*.swp' \
                --exclude='*.swo' \
                --exclude='*.log' \
                --exclude='Thumbs.db' \
                --exclude='desktop.ini' \
                --exclude='*.part' \
                --exclude='*.crdownload' \
                --exclude='*.torrent' \
                --exclude='*.lock' \
                --exclude='*.zip' \
                "$src_dir" "$specific_dest_dir" | while IFS= read -r line; do
                    echo "#  $line"

              # Verifica se o arquivo copiado é uma ISO
              if [[ "$line" == *.iso ]]; then
                src_file="$src_dir/$(basename "$line")"
                dest_file="$specific_dest_dir/$(basename "$line")"

                # Compara o conteúdo apenas se ambos existirem
                if [[ -f "$src_file" && -f "$dest_file" ]]; then
                  if ! cmp -s "$src_file" "$dest_file"; then
                    log_message "ISO corrompida detectada: $line – recopiando forçadamente."
                    echo "#  ⚠️ Corrigindo possível corrupção: $line"
                    cp -f "$src_file" "$dest_file"
                  fi
                fi
              fi
            done

            # Verifica o status da última execução do rsync
            rsync_status=${PIPESTATUS[0]}
            if [[ $rsync_status -ne 0 ]]; then
                log_message "ERRO ao espelhar de $src_dir para $specific_dest_dir (Código: $rsync_status)"
                echo "#!!! ERRO ao sincronizar '$relative_dir' (Código: $rsync_status) !!!"
                # Não para o script inteiro, apenas registra o erro e continua
            else
                log_message "Sucesso ao espelhar de $src_dir para $specific_dest_dir"
            fi
            # Adiciona uma linha em branco para separar as tarefas
            echo "#"
        done
    done
    echo "#Operação concluída."

) | yad --progress \
      --title="Sincronizando Arquivos para Unidades Ventoy" \
      --text="<big>Operação em andamento...</big>\n<i>Sincronizando pastas de origem para os dispositivos.</i>" \
      --width=750 \
      --height=180 \
      --text-align=left \
      --pulsate \
      --auto-close \
      --no-buttons  2>/dev/null  || {
        # Este bloco SÓ é executado se houver uma falha grave (exit 1).
        yad --error --title="FALHA NA OPERAÇÃO" --width=450 --text="<b>A operação falhou!</b>\n\nOcorreu um erro inesperado durante a execução.\n\nConsulte o log para mais detalhes:\n<b>$log_file</b>" 2>/dev/null
        # unmount_sos
        exit 1
      }

# --- TAREFAS FINAIS SILENCIOSAS ---
log_message "Operação CP-VENTOY concluída."

# Informa o usuário que o sistema está finalizando a gravação
yad --info \
  --title="Gravando Dados no Pendrive" \
  --text="<big><b>Finalizando gravação nos dispositivos</b></big>\n\nAguarde enquanto os dados são sincronizados para os pendrives.\nEssa etapa pode demorar alguns segundos, dependendo da quantidade de arquivos." \
  --no-buttons \
  --width=450 \
  --timeout=1 \
  --center 2>/dev/null &
log_message "Forçando sincronização final com sync..."
sync
log_message "Sincronização forçada concluída."

# Desmonta a pasta de rede
# unmount_sos

exit 0

