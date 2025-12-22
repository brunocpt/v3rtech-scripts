#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/04-limpeza-final.sh
# Versão: 1.0.0
# Descrição: Remove entradas de repositório duplicadas (.list vs .sources)
#            geradas automaticamente por instaladores de pacotes.
# ==============================================================================

log "STEP" "Iniciando limpeza final de sistema e repositórios..."

# Diretório de fontes do APT
APT_SOURCES_DIR="/etc/apt/sources.list.d"

# Lista de aplicações conhecidas por criar duplicatas
# Adicione aqui qualquer app que reclame de "alvo configurado várias vezes"
APPS_DUPLICADOS=("microsoft-edge" "vivaldi" "google-chrome" "vscode" "code")

if [ -d "$APT_SOURCES_DIR" ]; then
    log "INFO" "Verificando duplicidade de repositórios..."

    for app in "${APPS_DUPLICADOS[@]}"; do
        # Verifica se existem AMBOS os arquivos (.sources e .list) para o mesmo app
        # Ex: microsoft-edge.sources E microsoft-edge.list

        # Nota: O nome pode variar ligeiramente (ex: vivaldi.list vs vivaldi-archive.sources)
        # Então usamos find com wildcard para ser mais agressivo na busca do padrão

        FILE_SOURCES=$(find "$APT_SOURCES_DIR" -name "*$app*.sources" | head -n 1)
        FILE_LIST=$(find "$APT_SOURCES_DIR" -name "*$app*.list" | head -n 1)

        if [ -n "$FILE_SOURCES" ] && [ -n "$FILE_LIST" ]; then
            log "WARN" "Duplicidade detectada para $app."
            log "INFO" "Mantendo formato moderno: $(basename "$FILE_SOURCES")"
            log "INFO" "Removendo legado gerado pelo instalador: $(basename "$FILE_LIST")"

            $SUDO rm -f "$FILE_LIST"

            # Remove também o backup .save se existir
            $SUDO rm -f "${FILE_LIST}.save"
        fi
    done

    # Atualiza o cache para confirmar que os erros sumiram
    log "INFO" "Atualizando cache do APT para validar limpeza..."
    if command -v apt &>/dev/null; then
        $SUDO apt update -qq 2>/dev/null && log "SUCCESS" "Repositórios limpos e atualizados." || log "WARN" "Ainda pode haver avisos no apt update."
    fi
else
    log "INFO" "Diretório de fontes não encontrado ou não é Debian/Ubuntu. Pulei."
fi

# Limpeza de pacotes órfãos e cache (bônus)
log "INFO" "Limpando cache de pacotes desnecessários..."
case "$DISTRO_FAMILY" in
    debian|ubuntu)
        $SUDO apt autoremove -y &>/dev/null
        $SUDO apt clean &>/dev/null
        ;;
    fedora)
        $SUDO dnf autoremove -y &>/dev/null
        $SUDO dnf clean all &>/dev/null
        ;;
    arch)
        # No Arch, limpeza requer cuidado, limpamos apenas cache não usado
        if command -v pacman &>/dev/null; then
            $SUDO pacman -Sc --noconfirm &>/dev/null
        fi
        ;;
esac

log "SUCCESS" "Limpeza final concluída."
