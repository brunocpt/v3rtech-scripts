#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/09-setup-fstab-mounts.sh
# Versão: 2.0.0 (Inteligente - Extração Dinâmica de Diretórios)
# Descrição: Adiciona mounts de rede ao fstab e cria diretórios dinamicamente
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Configurando mounts de rede no fstab..."

# ==============================================================================
# DEBUG: Verificar Variáveis Globais
# ==============================================================================

log "DEBUG" "=== VERIFICAÇÃO DE VARIÁVEIS ==="
log "DEBUG" "BASE_DIR: $BASE_DIR"
log "DEBUG" "REAL_USER: $REAL_USER"
log "DEBUG" "REAL_HOME: $REAL_HOME"
log "DEBUG" "DISTRO_FAMILY: $DISTRO_FAMILY"

# Valida se o usuário está definido
if [ -z "$REAL_USER" ] || [ -z "$REAL_HOME" ]; then
    log "ERROR" "Variáveis REAL_USER ou REAL_HOME não definidas"
    return 1
fi

# Valida se BASE_DIR está definido
if [ -z "$BASE_DIR" ]; then
    log "ERROR" "Variável BASE_DIR não definida. Não é possível continuar."
    return 1
fi

# ==============================================================================
# 1. ADICIONAR ARQUIVO HOSTS (RESOLUÇÃO DE NOMES)
# ==============================================================================

log "INFO" "Configurando resolução de nomes (hosts)..."

HOSTS_FILE="$BASE_DIR/configs/hosts"

if [ -f "$HOSTS_FILE" ]; then
    log "SUCCESS" "✓ Arquivo de hosts encontrado: $HOSTS_FILE"
    
    # Verifica se já existe um marcador de bloco anterior
    if grep -q "# === V3RTECH SCRIPTS: HOSTS BEGIN ===" /etc/hosts 2>/dev/null; then
        log "INFO" "Removendo entradas anteriores de hosts..."
        $SUDO sed -i '/# === V3RTECH SCRIPTS: HOSTS BEGIN ===/,/# === V3RTECH SCRIPTS: HOSTS END ===/d' /etc/hosts
    fi
    
    # Adiciona marcador de início
    echo "# === V3RTECH SCRIPTS: HOSTS BEGIN ===" | $SUDO tee -a /etc/hosts > /dev/null
    
    # Adiciona as entradas do arquivo
    log "DEBUG" "Adicionando entradas de hosts..."
    cat "$HOSTS_FILE" | $SUDO tee -a /etc/hosts > /dev/null
    
    # Adiciona marcador de fim
    echo "# === V3RTECH SCRIPTS: HOSTS END ===" | $SUDO tee -a /etc/hosts > /dev/null
    
    log "SUCCESS" "✓ Arquivo de hosts adicionado com sucesso"
else
    log "WARN" "⚠ Arquivo de hosts não encontrado: $HOSTS_FILE"
    log "INFO" "Pulando configuração de hosts"
fi

# ==============================================================================
# 2. ADICIONAR MOUNTS AO FSTAB
# ==============================================================================

log "INFO" "Configurando mounts de rede no fstab..."

FSTAB_LAN_FILE="$BASE_DIR/configs/fstab.lan"

log "DEBUG" "Procurando arquivo de mounts em: $FSTAB_LAN_FILE"

# Verifica se o arquivo de mounts existe
if [ -f "$FSTAB_LAN_FILE" ]; then
    log "SUCCESS" "✓ Arquivo de mounts encontrado: $FSTAB_LAN_FILE"
    log "DEBUG" "Tamanho do arquivo: $(wc -l < "$FSTAB_LAN_FILE") linhas"
    
    # Verifica se já existe um marcador de bloco anterior
    if grep -q "# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===" /etc/fstab 2>/dev/null; then
        log "INFO" "Removendo entradas anteriores de mounts..."
        if $SUDO sed -i '/# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===/,/# === V3RTECH SCRIPTS: FSTAB MOUNTS END ===/d' /etc/fstab; then
            log "SUCCESS" "✓ Entradas anteriores removidas"
        else
            log "ERROR" "✗ Falha ao remover entradas anteriores"
            return 1
        fi
    else
        log "DEBUG" "Nenhuma entrada anterior encontrada"
    fi
    
    # Adiciona marcador de início
    log "DEBUG" "Adicionando marcador de início..."
    if echo "# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===" | $SUDO tee -a /etc/fstab > /dev/null; then
        log "SUCCESS" "✓ Marcador de início adicionado"
    else
        log "ERROR" "✗ Falha ao adicionar marcador de início"
        return 1
    fi
    
    # Adiciona as entradas do arquivo
    log "DEBUG" "Adicionando entradas de mounts..."
    if cat "$FSTAB_LAN_FILE" | $SUDO tee -a /etc/fstab > /dev/null; then
        log "SUCCESS" "✓ Entradas de mounts adicionadas"
    else
        log "ERROR" "✗ Falha ao adicionar entradas de mounts"
        return 1
    fi
    
    # Adiciona marcador de fim
    log "DEBUG" "Adicionando marcador de fim..."
    if echo "# === V3RTECH SCRIPTS: FSTAB MOUNTS END ===" | $SUDO tee -a /etc/fstab > /dev/null; then
        log "SUCCESS" "✓ Marcador de fim adicionado"
    else
        log "ERROR" "✗ Falha ao adicionar marcador de fim"
        return 1
    fi
    
    # Verifica se as entradas foram adicionadas corretamente
    log "DEBUG" "Verificando integridade do fstab..."
    if grep -q "# === V3RTECH SCRIPTS: FSTAB MOUNTS BEGIN ===" /etc/fstab && \
       grep -q "# === V3RTECH SCRIPTS: FSTAB MOUNTS END ===" /etc/fstab; then
        log "SUCCESS" "✓ Mounts de rede adicionados ao fstab com sucesso"
    else
        log "ERROR" "✗ Falha ao verificar integridade do fstab"
        return 1
    fi
else
    log "WARN" "⚠ Arquivo de mounts não encontrado: $FSTAB_LAN_FILE"
    log "INFO" "Pulando configuração de mounts de rede"
    return 0
fi

# ==============================================================================
# 3. CRIAR DIRETÓRIOS DE MOUNT DINAMICAMENTE
# ==============================================================================

log "INFO" "Criando diretórios de mount dinamicamente..."

log "DEBUG" "Extraindo pontos de montagem do fstab.lan..."

# Extrai os caminhos de montagem (terceira coluna) do fstab.lan
# Filtra apenas linhas que não começam com # e que contêm /mnt/LAN
# Extrai o caminho completo e depois apenas o nome do diretório

declare -a mount_dirs

# Lê o arquivo linha por linha
while IFS= read -r line; do
    # Pula linhas vazias e comentários
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    # Extrai o terceiro campo (ponto de montagem)
    mount_point=$(echo "$line" | awk '{print $2}')
    
    # Verifica se é um ponto de montagem válido em /mnt/LAN
    if [[ "$mount_point" =~ ^/mnt/LAN/ ]]; then
        mount_dirs+=("$mount_point")
        log "DEBUG" "Encontrado ponto de montagem: $mount_point"
    fi
done < "$FSTAB_LAN_FILE"

# Verifica se encontrou algum ponto de montagem
if [ ${#mount_dirs[@]} -eq 0 ]; then
    log "WARN" "⚠ Nenhum ponto de montagem encontrado em $FSTAB_LAN_FILE"
    log "INFO" "Pulando criação de diretórios"
else
    log "SUCCESS" "✓ Encontrados ${#mount_dirs[@]} ponto(s) de montagem"
    
    # Cria /mnt/LAN se não existir
    log "DEBUG" "Criando diretório base /mnt/LAN..."
    if $SUDO mkdir -p /mnt/LAN; then
        log "SUCCESS" "✓ Diretório /mnt/LAN criado"
    else
        log "WARN" "⚠ Falha ao criar /mnt/LAN (pode já existir)"
    fi
    
    # Cria cada diretório de montagem
    log "DEBUG" "Criando diretórios de montagem..."
    for mount_dir in "${mount_dirs[@]}"; do
        log "DEBUG" "Criando: $mount_dir"
        if $SUDO mkdir -p "$mount_dir"; then
            log "DEBUG" "✓ $mount_dir criado"
        else
            log "WARN" "⚠ Falha ao criar $mount_dir"
        fi
    done
    
    log "SUCCESS" "✓ Todos os diretórios de montagem criados"
fi

# ==============================================================================
# 4. INSTALAR FERRAMENTAS DE REDE
# ==============================================================================

log "INFO" "Verificando ferramentas de rede..."

case "$DISTRO_FAMILY" in
    arch)
        log "DEBUG" "Detectado Arch Linux"
        # CIFS
        if ! command -v mount.cifs &>/dev/null; then
            log "INFO" "Instalando suporte CIFS..."
            if $SUDO pacman -S --noconfirm cifs-utils 2>/dev/null; then
                log "SUCCESS" "✓ cifs-utils instalado"
            else
                log "WARN" "⚠ Falha ao instalar cifs-utils"
            fi
        else
            log "SUCCESS" "✓ mount.cifs já disponível"
        fi
        ;;
    debian)
        log "DEBUG" "Detectado Debian/Ubuntu"
        # CIFS
        if ! command -v mount.cifs &>/dev/null; then
            log "INFO" "Instalando suporte CIFS..."
            if $SUDO apt install -y cifs-utils 2>/dev/null; then
                log "SUCCESS" "✓ cifs-utils instalado"
            else
                log "WARN" "⚠ Falha ao instalar cifs-utils"
            fi
        else
            log "SUCCESS" "✓ mount.cifs já disponível"
        fi
        ;;
    fedora)
        log "DEBUG" "Detectado Fedora"
        # CIFS
        if ! command -v mount.cifs &>/dev/null; then
            log "INFO" "Instalando suporte CIFS..."
            if $SUDO dnf install -y cifs-utils 2>/dev/null; then
                log "SUCCESS" "✓ cifs-utils instalado"
            else
                log "WARN" "⚠ Falha ao instalar cifs-utils"
            fi
        else
            log "SUCCESS" "✓ mount.cifs já disponível"
        fi
        ;;
    *)
        log "WARN" "⚠ Distro não reconhecida: $DISTRO_FAMILY"
        ;;
esac

log "SUCCESS" "✓ Ferramentas de rede verificadas"

# ==============================================================================
# RESUMO FINAL
# ==============================================================================

log "SUCCESS" "✓ Configuração de mounts de rede concluída."
log "DEBUG" "=== FIM DA CONFIGURAÇÃO DE MOUNTS ==="
