#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: utils/optimize-fstab.sh
# Descrição: Otimiza opções de montagem no /etc/fstab para btrfs e ext4
# ==============================================================================

set -e

FSTAB_FILE="/etc/fstab"
BACKUP_FILE="${FSTAB_FILE}.bak"

# Verifica se é root, se não, tenta elevar com sudo
if [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null; then
        exec sudo "$0" "$@"
    else
        echo "ERRO: Este script requer privilégios de root e o sudo não foi encontrado."
        exit 1
    fi
fi

# Função para resolver dispositivo (UUID/LABEL -> /dev/sdX)
resolve_device() {
    local dev="$1"
    if [[ "$dev" == UUID=* ]]; then
        local uuid="${dev#UUID=}"
        blkid -U "$uuid" 2>/dev/null || echo ""
    elif [[ "$dev" == LABEL=* ]]; then
        local label="${dev#LABEL=}"
        blkid -L "$label" 2>/dev/null || echo ""
    elif [ -e "$dev" ]; then
        readlink -f "$dev"
    else
        echo ""
    fi
}

# Função para checar se é SSD (rotação=0)
is_ssd() {
    local dev="$1"
    [ -z "$dev" ] && return 1
    
    # lsblk -d -n -o ROTA retorna 0 para SSD, 1 para HDD
    # Precisamos lidar com partições (sda1 -> sda)
    
    # Tenta direto
    local rota=$(lsblk -d -n -o ROTA "$dev" 2>/dev/null || true)
    
    if [ -z "$rota" ]; then
        # Tenta pegar o parent device (ex: /dev/sda1 -> /dev/sda)
        # lsblk -no pkname /dev/sda1 -> sda
        local parent=$(lsblk -no pkname "$dev" 2>/dev/null | head -n1 || true)
        if [ -n "$parent" ]; then
             rota=$(lsblk -d -n -o ROTA "/dev/$parent" 2>/dev/null || true)
        fi
    fi

    if [[ "$rota" == "0" ]]; then
        return 0 # É SSD
    else
        return 1 # Não é SSD
    fi
}

# Função para checar se item existe na lista separada por vírgula
has_option() {
    local options="$1"
    local item="$2"
    [[ ",$options," == *",$item,"* ]]
}

# Principal
main() {
    if [ ! -f "$FSTAB_FILE" ]; then
        echo "ERRO: $FSTAB_FILE não encontrado."
        exit 1
    fi

    # Backup
    if [ ! -f "$BACKUP_FILE" ]; then
        cp "$FSTAB_FILE" "$BACKUP_FILE"
        echo "Backup criado em $BACKUP_FILE"
    fi

    local temp_file=$(mktemp)
    local changes_made=0

    # Lê linha a linha
    while IFS= read -r line || [ -n "$line" ]; do
        # Ignora comentários e linhas vazias na lógica, mas escreve no arquivo
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi

        # Parseia colunas (respeitando espaços/tabs)
        # read -r device mountpoint fstype options dump pass remainder
        # "remainder" captura o resto caso tenha mais colunas/comentários inline
        read -r device mountpoint fstype options dump pass remainder <<< "$line"

        if [[ "$fstype" == "btrfs" || "$fstype" == "ext4" ]]; then
            real_dev=$(resolve_device "$device")
            new_opts_list=()
            
            # Converte opções atuais para array
            IFS=',' read -ra current_opts <<< "$options"
            
            # Opções a aplicar
            unset desired_opts
            unset conflicts
            declare -A desired_opts
            declare -a conflicts=()
            
            if [[ "$fstype" == "btrfs" ]]; then
                desired_opts["compress"]="zstd:3"
                desired_opts["space_cache"]="v2"
                desired_opts["noatime"]="" # flag
                conflicts+=("relatime" "atime" "strictatime")
                
                if is_ssd "$real_dev"; then
                    desired_opts["ssd"]="" # flag
                fi
                
            elif [[ "$fstype" == "ext4" ]]; then
                desired_opts["noatime"]=""
                desired_opts["lazytime"]=""
                desired_opts["commit"]="60"
                conflicts+=("relatime" "atime" "strictatime")
            fi

            # Constrói nova lista de opções
            # 1. Preserva opções existentes que não conflitam e não são as que queremos setar (serão setadas depois)
            for opt in "${current_opts[@]}"; do
                opt_key="${opt%%=*}"
                
                # Checa conflito
                is_conflict=0
                for c in "${conflicts[@]}"; do
                    if [[ "$opt_key" == "$c" ]]; then
                        is_conflict=1
                        break
                    fi
                done
                [ $is_conflict -eq 1 ] && continue
                
                # Checa se é uma das desired (vamos adicionar no final para garantir valor correto)
                if [[ -v desired_opts["$opt_key"] ]]; then
                     continue 
                fi
                
                new_opts_list+=("$opt")
            done

            # 2. Adiciona desired options
            for key in "${!desired_opts[@]}"; do
                val="${desired_opts[$key]}"
                if [ -n "$val" ]; then
                    new_opts_list+=("$key=$val")
                else
                    new_opts_list+=("$key")
                fi
            done
            
            # Reconstrói string de opções
            new_options_str=$(IFS=,; echo "${new_opts_list[*]}")

            if [ "$options" != "$new_options_str" ]; then
                echo "Otimizando $fstype em $mountpoint ($device):"
                echo "  Antes: $options"
                echo "  Depois: $new_options_str"
                changes_made=1
                
                # Reconstrói a linha preservando formatação básica (tabulado)
                # printf "%-15s %-15s %-7s %-15s %-d %-d\n" ... é arriscado se colunas forem grandes
                # Vamos usar tabs simples
                echo -e "$device\t$mountpoint\t$fstype\t$new_options_str\t$dump\t$pass" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi

    done < "$FSTAB_FILE"

    if [ $changes_made -eq 1 ]; then
        mv "$temp_file" "$FSTAB_FILE"
        echo "Fstab otimizado com sucesso."
        # systemctl daemon-reload deve ser chamado por quem executa este script ou avisar usuario
    else
        rm "$temp_file"
        echo "Nenhuma otimização necessária."
    fi
}

main
