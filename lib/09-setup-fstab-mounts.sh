#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/09-setup-fstab-mounts.sh
# Versão: 1.0.0 (Novo)
# Descrição: Configura mounts de rede no fstab
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Configurando mounts de rede no fstab..."

# Valida se o usuário está definido
if [ -z "$REAL_USER" ] || [ -z "$REAL_HOME" ]; then
    log "WARN" "Variáveis REAL_USER ou REAL_HOME não definidas"
    return 1
fi

# ==============================================================================
# CONFIGURAÇÃO DE MOUNTS DE REDE
# ==============================================================================

# Função para adicionar mount ao fstab (idempotente)
add_fstab_mount() {
    local device="$1"
    local mountpoint="$2"
    local fstype="$3"
    local options="$4"
    local dump="${5:-0}"
    local pass="${6:-0}"
    
    # Verifica se o mount já existe no fstab
    if grep -q "^$device" /etc/fstab 2>/dev/null; then
        log "INFO" "Mount já existe no fstab: $device → $mountpoint"
        return 0
    fi
    
    # Cria o diretório de mount se não existir
    $SUDO mkdir -p "$mountpoint"
    
    # Adiciona ao fstab
    local fstab_entry="$device $mountpoint $fstype $options $dump $pass"
    echo "$fstab_entry" | $SUDO tee -a /etc/fstab > /dev/null
    
    log "SUCCESS" "Mount adicionado ao fstab: $device → $mountpoint"
}

# ==============================================================================
# 1. MOUNTS NFS (Network File System)
# ==============================================================================

log "INFO" "Verificando mounts NFS..."

# Exemplo: NFS do DNS320L
# Descomente e ajuste conforme necessário
# add_fstab_mount "192.168.1.100:/volume1/trabalho" "/mnt/trabalho" "nfs" "defaults,vers=3,soft,timeo=10,retrans=3" "0" "0"

log "INFO" "NFS: Nenhum mount NFS configurado por padrão. Edite o script para adicionar."

# ==============================================================================
# 2. MOUNTS SAMBA/CIFS (Windows Shares)
# ==============================================================================

log "INFO" "Verificando mounts CIFS..."

# Exemplo: Compartilhamento SAMBA
# Descomente e ajuste conforme necessário
# add_fstab_mount "//192.168.1.100/compartilhado" "/mnt/samba" "cifs" "username=user,password=pass,uid=1000,gid=1000,file_mode=0755,dir_mode=0755" "0" "0"

log "INFO" "CIFS: Nenhum mount CIFS configurado por padrão. Edite o script para adicionar."

# ==============================================================================
# 3. VERIFICAÇÃO E MONTAGEM
# ==============================================================================

log "INFO" "Verificando se há mounts para montar..."

# Tenta montar todos os mounts do fstab que não estão montados
if command -v mount &>/dev/null; then
    # Lista mounts que falharam
    local failed_mounts=0
    
    # Tenta montar -a (todos os mounts do fstab)
    if $SUDO mount -a 2>/dev/null; then
        log "SUCCESS" "Mounts do fstab montados com sucesso"
    else
        log "WARN" "Alguns mounts falharam. Verifique as credenciais e conectividade de rede."
        failed_mounts=$?
    fi
else
    log "WARN" "Comando 'mount' não encontrado"
fi

# ==============================================================================
# 4. INSTALAÇÃO DE FERRAMENTAS DE REDE
# ==============================================================================

log "INFO" "Verificando ferramentas de rede..."

case "$DISTRO_FAMILY" in
    arch)
        # NFS
        if ! command -v mount.nfs &>/dev/null; then
            log "INFO" "Instalando suporte NFS..."
            $SUDO pacman -S --noconfirm nfs-utils 2>/dev/null || true
        fi
        
        # CIFS
        if ! command -v mount.cifs &>/dev/null; then
            log "INFO" "Instalando suporte CIFS..."
            $SUDO pacman -S --noconfirm cifs-utils 2>/dev/null || true
        fi
        ;;
    debian)
        # NFS
        if ! command -v mount.nfs &>/dev/null; then
            log "INFO" "Instalando suporte NFS..."
            $SUDO apt install -y nfs-common 2>/dev/null || true
        fi
        
        # CIFS
        if ! command -v mount.cifs &>/dev/null; then
            log "INFO" "Instalando suporte CIFS..."
            $SUDO apt install -y cifs-utils 2>/dev/null || true
        fi
        ;;
    fedora)
        # NFS
        if ! command -v mount.nfs &>/dev/null; then
            log "INFO" "Instalando suporte NFS..."
            $SUDO dnf install -y nfs-utils 2>/dev/null || true
        fi
        
        # CIFS
        if ! command -v mount.cifs &>/dev/null; then
            log "INFO" "Instalando suporte CIFS..."
            $SUDO dnf install -y cifs-utils 2>/dev/null || true
        fi
        ;;
esac

log "SUCCESS" "Ferramentas de rede verificadas"

# ==============================================================================
# 5. CONFIGURAÇÃO DE PERMISSÕES
# ==============================================================================

log "INFO" "Ajustando permissões de mounts..."

# Garante que os diretórios de mount têm as permissões corretas
$SUDO mkdir -p /mnt/trabalho /mnt/LAN 2>/dev/null || true
$SUDO chown "$REAL_USER:$REAL_USER" /mnt/trabalho /mnt/LAN 2>/dev/null || true
$SUDO chmod 755 /mnt/trabalho /mnt/LAN 2>/dev/null || true

log "SUCCESS" "Permissões de mounts ajustadas"

# ==============================================================================
# 6. INFORMAÇÕES ÚTEIS
# ==============================================================================

log "INFO" "Configuração de mounts concluída"
log "INFO" "Para adicionar novos mounts, edite este script e adicione chamadas a add_fstab_mount"
log "INFO" "Exemplo NFS: add_fstab_mount \"192.168.1.100:/volume1/trabalho\" \"/mnt/trabalho\" \"nfs\" \"defaults,vers=3,soft,timeo=10,retrans=3\" \"0\" \"0\""
log "INFO" "Exemplo CIFS: add_fstab_mount \"//192.168.1.100/compartilhado\" \"/mnt/samba\" \"cifs\" \"username=user,password=pass,uid=1000,gid=1000\" \"0\" \"0\""

log "SUCCESS" "Configuração de mounts de rede concluída."
