#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/setup-docker.sh
# Versão: 1.0.0
#
# Descrição: Realiza a configuração pós-instalação do Docker Engine.
# 1. Habilita serviço no Systemd.
# 2. Adiciona usuário atual ao grupo docker (Rootless mode).
# 3. Configura rotação de logs padrão (Daemon.json).
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

log "STEP" "Iniciando configuração pós-instalação do Docker..."

# 1. Verifica se o Docker foi realmente instalado
if ! command -v docker &> /dev/null; then
    log "WARN" "Docker não encontrado no sistema. Pulando configuração."
    return 0
fi

# 2. Habilita e Inicia o Serviço (Systemd)
log "INFO" "Habilitando serviço Docker (Systemd)..."
if systemctl list-unit-files | grep -q docker.service; then
    $SUDO systemctl enable --now docker.service
    $SUDO systemctl enable --now containerd.service
    log "SUCCESS" "Serviços Docker/Containerd iniciados."
else
    log "WARN" "Unit docker.service não encontrada (você está usando init diferente de systemd?)"
fi

# 3. Gerenciamento de Grupo (Permite rodar sem sudo)
log "INFO" "Configurando permissões de usuário para o grupo 'docker'..."

# Cria o grupo se não existir (raro, pois o pacote cria)
if ! getent group docker > /dev/null; then
    $SUDO groupadd docker
fi

# Adiciona o usuário real ao grupo
if ! groups "$REAL_USER" | grep -q "\bdocker\b"; then
    $SUDO usermod -aG docker "$REAL_USER"
    log "SUCCESS" "Usuário $REAL_USER adicionado ao grupo docker."
    log "WARN" "Atenção: Você precisará fazer Logoff/Login para que as permissões do Docker surtam efeito."
else
    log "INFO" "Usuário já pertence ao grupo docker."
fi

# 4. Configuração de Rotação de Logs (Daemon.json)
# Evita que containers consumam todo o disco com logs gigantes
DAEMON_CONFIG="/etc/docker/daemon.json"

log "INFO" "Verificando configuração de Log Rotation..."

if [ ! -f "$DAEMON_CONFIG" ]; then
    log "INFO" "Criando $DAEMON_CONFIG com políticas de log..."

    # Cria configuração segura
    echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}' | $SUDO tee "$DAEMON_CONFIG" > /dev/null

    # Reinicia para aplicar
    $SUDO systemctl restart docker
    log "SUCCESS" "Daemon configurado e reiniciado."
else
    log "INFO" "Arquivo daemon.json já existe. Mantendo original."
fi

# 5. Validação
log "INFO" "Versão instalada:"
docker --version
docker compose version

log "SUCCESS" "Configuração do Docker concluída."
