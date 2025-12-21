#!/bin/bash
# ==============================================================================
# Script: restaura-config.sh (Versão Final Corrigida)
# Descrição: Restaura configurações sem depender de aplicativo estar instalado
# Versão: 3.0.0 (Bug corrigido - Restaura mesmo sem app instalado)
# ==============================================================================

set -o pipefail

# ==============================================================================
# CONFIGURAÇÕES
# ==============================================================================

DEST_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/backups"
LOG_FILE="$HOME/restaura-config.log"
USERNAME="$USER"

# Limpa logs anteriores
> "$LOG_FILE"

log_msg() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] ❌ ERRO: $msg" | tee -a "$LOG_FILE"
}

log_success() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] ✅ $msg" | tee -a "$LOG_FILE"
}

log_warn() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] ⚠️  $msg" | tee -a "$LOG_FILE"
}

# ==============================================================================
# DIAGNÓSTICO PRÉ-EXECUÇÃO
# ==============================================================================

log_msg "=== INICIANDO DIAGNÓSTICO PRÉ-EXECUÇÃO ==="

# Verifica se o diretório de backup existe
if [ ! -d "$DEST_DIR" ]; then
    log_error "Diretório de backup NÃO EXISTE: $DEST_DIR"
    yad --error --title="Erro Crítico" \
        --text="<big><b>Erro ao acessar diretório de backups!</b></big>\n\nCaminho: <b>$DEST_DIR</b>" \
        --width=500
    exit 1
fi

log_success "Diretório de backup acessível: $DEST_DIR"

# Verifica se há arquivos ZIP no diretório
BACKUP_COUNT=$(find "$DEST_DIR" -name "*.zip" 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -eq 0 ]; then
    log_error "Nenhum arquivo de backup encontrado em: $DEST_DIR"
    yad --warning --title="Aviso" \
        --text="<big><b>Nenhum backup encontrado!</b></big>\n\nDiretório: <b>$DEST_DIR</b>" \
        --width=400
    exit 1
fi

log_success "Encontrados $BACKUP_COUNT arquivo(s) de backup"

# Verifica permissões
if [ ! -r "$DEST_DIR" ]; then
    log_error "Sem permissão de leitura em: $DEST_DIR"
    exit 1
fi

log_success "Permissões de leitura OK"

# Verifica se unzip está instalado
if ! command -v unzip &>/dev/null; then
    log_error "unzip não está instalado"
    exit 1
fi

log_success "unzip disponível"

# Verifica se yad está instalado
if ! command -v yad &>/dev/null; then
    log_error "yad não está instalado"
    exit 1
fi

log_success "yad disponível"

log_msg "=== DIAGNÓSTICO CONCLUÍDO COM SUCESSO ==="

# ==============================================================================
# INTERFACE DE SELEÇÃO
# ==============================================================================

SELECTION=$(yad --title="Restauração de Configurações" \
    --text="<big><b>Selecione os aplicativos para restaurar</b></big>\n\nDiretório: <b>$DEST_DIR</b>\nArquivos encontrados: <b>$BACKUP_COUNT</b>" \
    --list --checklist --width=500 --height=600 \
    --column="Restaurar" --column="Aplicativo" \
    FALSE "BRAVE" FALSE "CHROME" FALSE "EDGE" FALSE "FALKON" \
    FALSE "FIREFOX" FALSE "FLOORP" FALSE "VIVALDI" FALSE "OPERA" FALSE "CALIBRE" \
    FALSE "WAVEBOX" FALSE "RAMBOX" FALSE "FERDIUM" FALSE "NEXTCLOUD" \
    FALSE "FILEZILLA" FALSE "TRANSMISSION" FALSE "OBSIDIAN" FALSE "ZOTERO" \
    FALSE "MASTER_PDF" FALSE "PICARD" FALSE "VSCODE" FALSE "SYSTEM_SETTINGS" FALSE "KWALLET" \
    --button="Selecionar Todos:2" --button="Desmarcar Todos:3" --button="Iniciar:0" --button="Cancelar:1")

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    log_msg "Operação cancelada pelo usuário (código: $EXIT_CODE)"
    exit 0
fi

# Extrai aplicativos selecionados
mapfile -t selected_apps < <(echo "$SELECTION" | awk -F'|' '{for(i=1;i<=NF;i+=2) if ($i == "TRUE") print $(i+1)}')

if [ ${#selected_apps[@]} -eq 0 ]; then
    log_msg "Nenhum aplicativo selecionado"
    exit 0
fi

# Confirmação
yad --question --title="Confirmar Restauração" \
    --text="Deseja realmente restaurar $(echo ${#selected_apps[@]}) aplicativo(s)?" \
    --button=Sim:0 --button=Não:1

if [ $? -ne 0 ]; then
    log_msg "Restauração cancelada pelo usuário"
    exit 0
fi

# ==============================================================================
# FUNÇÃO DE RESTAURAÇÃO
# ==============================================================================

restore_app() {
    local app_name="$1"
    local zip_file="$2"

    log_msg "  Processando: $app_name"

    # Verifica se o arquivo ZIP existe
    if [ ! -f "$zip_file" ]; then
        log_error "$app_name: Arquivo não encontrado: $zip_file"
        return 1
    fi

    # Verifica se o arquivo é um ZIP válido
    if ! unzip -t "$zip_file" &>/dev/null; then
        log_error "$app_name: Arquivo ZIP inválido ou corrompido: $zip_file"
        return 1
    fi

    log_msg "    → Extraindo para: $HOME"

    # Tenta extrair
    if unzip -oq "$zip_file" -d "$HOME" 2>/dev/null; then
        log_success "$app_name: Restaurado com sucesso"
        return 0
    else
        log_error "$app_name: Erro ao extrair"
        return 1
    fi
}

# ==============================================================================
# PROCESSAMENTO DE CADA APLICATIVO
# ==============================================================================

TOTAL=${#selected_apps[@]}
CURRENT=0
SUCCESS=0
FAILED=0

log_msg "=== INICIANDO RESTAURAÇÃO DE $TOTAL APLICATIVO(S) ==="

for app in "${selected_apps[@]}"; do
    CURRENT=$((CURRENT + 1))
    PROGRESS=$((CURRENT * 100 / TOTAL))

    # Mostra barra de progresso
    (
        echo "$PROGRESS"
        echo "# Restaurando: $app ($CURRENT/$TOTAL)"
    ) | yad --progress --title="Restauração em Andamento" \
        --text="Processando: $app\n\nProgresso: $CURRENT de $TOTAL" \
        --width=400 --auto-close 2>/dev/null &

    YAD_PID=$!

    log_msg "--- [$CURRENT/$TOTAL] Processando: $app ---"

    case "$app" in
        "BRAVE")
            # Tenta restaurar versão flatpak
            restore_app "BRAVE (Flatpak)" "$DEST_DIR/brave-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            # Tenta restaurar versão nativa
            restore_app "BRAVE (Nativo)" "$DEST_DIR/brave-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "CHROME")
            restore_app "CHROME (Flatpak)" "$DEST_DIR/chrome-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "CHROME (Nativo)" "$DEST_DIR/google-chrome-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "EDGE")
            restore_app "EDGE (Flatpak)" "$DEST_DIR/edge-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "EDGE (Nativo)" "$DEST_DIR/edge-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "FALKON")
            restore_app "FALKON" "$DEST_DIR/falkon-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))
            ;;
        "FIREFOX")
            restore_app "FIREFOX (Flatpak)" "$DEST_DIR/firefox-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "FIREFOX (Nativo)" "$DEST_DIR/firefox-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "FLOORP")
            restore_app "FLOORP" "$DEST_DIR/floorp-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))
            ;;
        "VIVALDI")
            restore_app "VIVALDI (Flatpak)" "$DEST_DIR/vivaldi-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "VIVALDI (Nativo)" "$DEST_DIR/vivaldi-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "OPERA")
            restore_app "OPERA (Flatpak)" "$DEST_DIR/opera-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "OPERA (Nativo)" "$DEST_DIR/opera-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "CALIBRE")
            restore_app "CALIBRE (Flatpak)" "$DEST_DIR/calibre-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "CALIBRE (Nativo)" "$DEST_DIR/calibre-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "WAVEBOX")
            restore_app "WAVEBOX (Flatpak)" "$DEST_DIR/wavebox-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "WAVEBOX (Nativo)" "$DEST_DIR/wavebox-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))
            ;;
        "RAMBOX")
            restore_app "RAMBOX" "$DEST_DIR/rambox-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))
            ;;
        "FERDIUM")
            restore_app "FERDIUM (Flatpak)" "$DEST_DIR/ferdium-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "FERDIUM (Nativo)" "$DEST_DIR/ferdium-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "NEXTCLOUD")
            restore_app "NEXTCLOUD (Flatpak)" "$DEST_DIR/nextcloud-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "NEXTCLOUD (Nativo)" "$DEST_DIR/nextcloud-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "FILEZILLA")
            restore_app "FILEZILLA (Flatpak)" "$DEST_DIR/filezilla-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "FILEZILLA (Nativo)" "$DEST_DIR/filezilla-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "TRANSMISSION")
            restore_app "TRANSMISSION (Flatpak)" "$DEST_DIR/transmission-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "TRANSMISSION (Nativo)" "$DEST_DIR/transmission-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "OBSIDIAN")
            restore_app "OBSIDIAN (Flatpak)" "$DEST_DIR/obsidian-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "OBSIDIAN (Nativo)" "$DEST_DIR/obsidian-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "ZOTERO")
            restore_app "ZOTERO (Flatpak)" "$DEST_DIR/zotero-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "ZOTERO (Nativo)" "$DEST_DIR/zotero-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "MASTER_PDF")
            restore_app "MASTER_PDF" "$DEST_DIR/master_pdf-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))
            ;;
        "PICARD")
            restore_app "PICARD (Flatpak)" "$DEST_DIR/picard-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "PICARD (Nativo)" "$DEST_DIR/picard-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "VSCODE")
            restore_app "VSCODE (Flatpak)" "$DEST_DIR/vscode-flatpak-$USERNAME.zip" && ((SUCCESS++)) || true
            restore_app "VSCODE (Nativo)" "$DEST_DIR/vscode-$USERNAME.zip" && ((SUCCESS++)) || true
            ;;
        "KWALLET")
            restore_app "KWALLET" "$DEST_DIR/kwallet-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))
            ;;
        "SYSTEM_SETTINGS")
            restore_app "SYSTEM_SETTINGS" "$DEST_DIR/system-settings-$USERNAME.zip" && ((SUCCESS++)) || ((FAILED++))

            # Tenta restaurar dconf se disponível
            if unzip -p "$DEST_DIR/system-settings-$USERNAME.zip" dconf-settings.dump > /tmp/dconf-settings.dump 2>/dev/null; then
                if [ -s /tmp/dconf-settings.dump ]; then
                    log_msg "  Aplicando dconf-settings.dump"
                    dconf load / < /tmp/dconf-settings.dump && log_success "dconf restaurado" || log_error "Erro ao aplicar dconf"
                fi
            fi
            ;;
    esac

    # Mata a barra de progresso
    kill "$YAD_PID" 2>/dev/null || true
    wait "$YAD_PID" 2>/dev/null || true
done

# ==============================================================================
# LIMPEZA FINAL E RELATÓRIO
# ==============================================================================

log_msg "--- Finalizando restauração ---"

# Corrige permissões (uma única vez)
log_msg "Corrigindo permissões de arquivos..."
chown -R "$USERNAME:$USERNAME" "$HOME" 2>/dev/null || true

log_msg "=== Restauração Concluída ==="
log_msg "Sucesso: $SUCCESS | Falhas: $FAILED"

# Mostra relatório final
RESULT_TEXT="<big><b>Restauração Concluída!</b></big>\n\n"
RESULT_TEXT+="<b>Sucesso:</b> $SUCCESS\n"
RESULT_TEXT+="<b>Falhas:</b> $FAILED\n\n"
RESULT_TEXT+="Log salvo em:\n<b>$LOG_FILE</b>"

if [ $FAILED -gt 0 ]; then
    yad --warning --title="Restauração com Erros" \
        --text="$RESULT_TEXT" \
        --width=450 --height=250
else
    yad --info --title="Restauração Concluída com Sucesso" \
        --text="$RESULT_TEXT" \
        --width=450 --height=200
fi
