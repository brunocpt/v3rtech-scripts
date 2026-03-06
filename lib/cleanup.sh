#!/bin/bash
# ==============================================================================
# Script: lib/cleanup.sh
# Versão: 4.7.0
# Data: 2026-03-06
# Objetivo: Limpeza final pós-instalação
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Remove pacotes órfãos, limpa cache do gerenciador de pacotes,
# remove Flatpaks não utilizados e limpa arquivos temporários.
#
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh"         || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh"     || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }

section "Limpeza Final do Sistema"

# ==============================================================================
# 1. PACOTES ÓRFÃOS E CACHE DO GERENCIADOR DE PACOTES
# ==============================================================================

log "STEP" "Limpando pacotes e cache..."

case "$DISTRO_FAMILY" in
    debian)
        $SUDO apt autoremove -y
        $SUDO apt autoclean -y
        ;;
    arch)
        orphans=$(paru -Qdtq 2>/dev/null)
        if [ -n "$orphans" ]; then
            log "INFO" "Removendo pacotes órfãos: $orphans"
            paru -Rns --noconfirm $orphans
        else
            log "INFO" "Nenhum pacote órfão encontrado."
        fi
        $SUDO paccache -rk1 2>/dev/null || log "WARN" "paccache não disponível; cache não limpo."
        ;;
    fedora)
        $SUDO dnf autoremove -y
        $SUDO dnf clean all
        ;;
    *)
        log "WARN" "Distribuição desconhecida; limpeza de pacotes pulada."
        ;;
esac

log "SUCCESS" "Cache de pacotes limpo."

# ==============================================================================
# 2. FLATPAKS NÃO UTILIZADOS
# ==============================================================================

if command -v flatpak &>/dev/null; then
    log "STEP" "Removendo Flatpaks não utilizados..."
    $SUDO flatpak uninstall --unused -y && log "SUCCESS" "Flatpaks órfãos removidos." \
        || log "WARN" "Falha ao remover Flatpaks não utilizados."
fi

# ==============================================================================
# 3. ARQUIVOS TEMPORÁRIOS
# ==============================================================================

log "STEP" "Limpando arquivos temporários..."

find "$BASE_DIR" -maxdepth 3 -name "*.bak" -delete 2>/dev/null && \
    log "INFO" "Arquivos .bak removidos."

find /tmp -maxdepth 1 -user "$REAL_USER" -mtime +1 -delete 2>/dev/null || true

log "SUCCESS" "Limpeza concluída!"
