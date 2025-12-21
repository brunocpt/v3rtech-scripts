#!/bin/bash
# ============================================================================
#
#        ARQUIVO: configs-zip (Versão Corrigida - v2.0)
#
#        UTILIZAÇÃO: ./configs-zip
#
#        DESCRIÇÃO: Realiza backup de configurações com uma interface YAD.
#                   Versão corrigida com tratamento de erros e killall
#                   para todos os aplicativos.
#
#        AUTOR: Gemini (Revisão: v3rtech-scripts)
#        REVISÃO: 2.0 - Bugs corrigidos:
#                       - Adicionado killall para todos os apps
#                       - Verificação de erro após zip
#                       - Mensagens corretas no log
#                       - Variáveis escapadas
#
# ============================================================================

DEST_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/backups"
TMP_DIR="/tmp/backup_script_$$"
LOG_FILE="$HOME/configs-zip.log"
USERNAME="$USER"

# --- LISTA DE APLICATIVOS PARA O YAD ---
declare -a APP_LIST=(
    "BRAVE" "CHROME" "EDGE" "FALKON" "FIREFOX" "FLOORP" "VIVALDI" "OPERA" "ZEN BROWSER" "CALIBRE"
    "WAVEBOX" "RAMBOX" "FERDIUM" "NEXTCLOUD" "FILEZILLA" "TRANSMISSION" "OBSIDIAN" "ZOTERO" "TINTERO"
    "MASTER_PDF" "PICARD" "VSCODE" "ANTIGRAVITY" "PYCHARM" "DBEAVER" "POSTMAN" "REMMINA" "SYSTEM_SETTINGS"
)

# --- FUNÇÕES AUXILIARES ---

log_msg() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

log_success() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] ✅ $msg" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="$1"
    echo "[$(date +'%H:%M:%S')] ❌ ERRO: $msg" | tee -a "$LOG_FILE"
}

# Função para fazer backup com verificação de erro
backup_zip() {
    local app_name="$1"
    local zip_file="$2"
    shift 2
    local dirs=("$@")

    log_msg "  Criando ZIP: $(basename "$zip_file")"

    if zip -qr "$zip_file" "${dirs[@]}" 2>/dev/null; then
        if [ -f "$zip_file" ]; then
            mv "$zip_file" "$DEST_DIR/"
            log_success "$app_name: Backup realizado com sucesso"
            return 0
        else
            log_error "$app_name: Arquivo ZIP não foi criado"
            return 1
        fi
    else
        log_error "$app_name: Erro ao criar ZIP"
        return 1
    fi
}

# --- INÍCIO DA EXECUÇÃO ---
trap 'rm -rf "$TMP_DIR"' EXIT
> "$LOG_FILE"
mkdir -p "$DEST_DIR" || { echo "ERRO CRÍTICO: Não foi possível criar o diretório de destino $DEST_DIR." | tee -a "$LOG_FILE"; exit 1; }
mkdir -p "$TMP_DIR"  || { echo "ERRO CRÍTICO: Não foi possível criar o diretório temporário $TMP_DIR." | tee -a "$LOG_FILE"; exit 1; }

# --- INTERFACE GRÁFICA (YAD) PARA SELEÇÃO ---
initial_state=()
for app in "${APP_LIST[@]}"; do initial_state+=(FALSE "$app"); done

while true; do
    SELECTIONS=$(yad --title="Utilitário de Backup" \
        --text="<big><b>Selecione os itens para fazer backup</b></big>\n\nOs arquivos serão salvos em: <b>$DEST_DIR</b>" \
        --list --checklist --width=500 --height=800 \
        --column="Fazer Backup" --column="Aplicativo / Item" \
        "${initial_state[@]}" \
        --button="Selecionar Todos:2" --button="Desmarcar Todos:3" --button="Iniciar Backup:0" --button="Cancelar:1")
    exit_code=$?

    case $exit_code in
        0) break ;;
        1|252) echo "[$(date +'%H:%M:%S')] Operação cancelada pelo usuário." > "$LOG_FILE"; exit 0 ;;
        2) initial_state=(); for app in "${APP_LIST[@]}"; do initial_state+=(TRUE "$app"); done ;;
        3) initial_state=(); for app in "${APP_LIST[@]}"; do initial_state+=(FALSE "$app"); done ;;
        *) echo "[$(date +'%H:%M:%S')] Erro inesperado do YAD (código: $exit_code)." > "$LOG_FILE"; exit 1 ;;
    esac
done

mapfile -t selected_apps < <(echo "$SELECTIONS" | awk -F'|' '{for(i=1; i<=NF; i+=2) if ($i == "TRUE") print $(i+1)}')

if [ ${#selected_apps[@]} -eq 0 ]; then
    yad --title="Aviso" --text="Nenhum item foi selecionado para backup." --button="OK:0"
    exit 0
fi

# --- PROCESSO DE BACKUP ---
log_msg "=== INICIANDO PROCESSO DE BACKUP ==="
log_msg "Itens selecionados: ${selected_apps[*]}"
log_msg "============================================================"

cd "$HOME" || { log_error "Não foi possível acessar o diretório $HOME"; exit 1; }

for app in "${selected_apps[@]}"; do
    log_msg "--- Processando: $app ---"

    # Inicia a janela de progresso genérica
    yad --progress --pulsate --title="Backup de $app" --text="<big>Compactando arquivos de $app...</big>" --width=400 --auto-close --no-buttons >/dev/null 2>&1 &
    YAD_PID=$!

    case "$app" in
        "BRAVE")
            killall brave-browser brave-browser-beta &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.brave.Browser'; then
                backup_zip "BRAVE (Flatpak)" "$TMP_DIR/brave-flatpak-${USERNAME}.zip" ".var/app/com.brave.Browser" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            else
                backup_zip "BRAVE (Nativo)" "$TMP_DIR/brave-${USERNAME}.zip" ".config/BraveSoftware" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            fi
            ;;
        "CHROME")
            killall google-chrome google-chrome-beta &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.google.Chrome'; then
                backup_zip "CHROME (Flatpak)" "$TMP_DIR/chrome-flatpak-${USERNAME}.zip" ".var/app/com.google.Chrome" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Service Worker/*" "*/Crashpad/*"
            else
                backup_zip "CHROME (Nativo)" "$TMP_DIR/google-chrome-${USERNAME}.zip" ".config/google-chrome" ".config/google-chrome-beta" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Service Worker/*" "*/Crashpad/*" "*/Crash Reports/*" "*/Storage/*"
            fi
            ;;
        "EDGE")
            killall msedge msedge-beta &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.microsoft.Edge'; then
                backup_zip "EDGE (Flatpak)" "$TMP_DIR/edge-flatpak-${USERNAME}.zip" ".var/app/com.microsoft.Edge" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            else
                backup_zip "EDGE (Nativo)" "$TMP_DIR/edge-${USERNAME}.zip" ".config/microsoft-edge" ".config/microsoft-edge-beta" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            fi
            ;;
        "FALKON")
            killall falkon &>/dev/null; sleep 1
            backup_zip "FALKON" "$TMP_DIR/falkon-${USERNAME}.zip" ".config/falkon"
            ;;
        "FIREFOX")
            killall firefox &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'org.mozilla.firefox'; then
                backup_zip "FIREFOX (Flatpak)" "$TMP_DIR/firefox-flatpak-${USERNAME}.zip" ".var/app/org.mozilla.firefox" -x "*/cache2/*" "*/storage/*" "*.db-wal" "*.db-shm" "*/Crash Reports/*"
            else
                backup_zip "FIREFOX (Nativo)" "$TMP_DIR/firefox-${USERNAME}.zip" ".mozilla" -x ".mozilla/firefox/*/cache2/*" ".mozilla/firefox/*/storage/*" "*.db-wal" "*.db-shm" "*/Crash Reports/*"
            fi
            ;;
        "FLOORP")
            killall floorp &>/dev/null; sleep 1
            backup_zip "FLOORP" "$TMP_DIR/floorp-${USERNAME}.zip" ".floorp" -x ".floorp/*/.cache2/*" ".floorp/*/.storage/*" "*.db-wal" "*.db-shm" "*/.Crash Reports/*"
            ;;
        "VIVALDI")
            killall vivaldi-stable &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.vivaldi.Vivaldi'; then
                backup_zip "VIVALDI (Flatpak)" "$TMP_DIR/vivaldi-flatpak-${USERNAME}.zip" ".var/app/com.vivaldi.Vivaldi" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            else
                backup_zip "VIVALDI (Nativo)" "$TMP_DIR/vivaldi-${USERNAME}.zip" ".config/vivaldi" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            fi
            ;;
        "OPERA")
            killall opera-stable &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.opera.Opera'; then
                backup_zip "OPERA (Flatpak)" "$TMP_DIR/opera-flatpak-${USERNAME}.zip" ".var/app/com.opera.Opera" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            else
                backup_zip "OPERA (Nativo)" "$TMP_DIR/opera-${USERNAME}.zip" ".config/opera" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
            fi
            ;;
        "ZEN BROWSER")
            killall zen-browser &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'app.zen_browser.zen'; then
                backup_zip "ZEN BROWSER (Flatpak)" "$TMP_DIR/zen-flatpak-${USERNAME}.zip" ".var/app/app.zen_browser.zen" -x "*/cache2/*" "*/storage/*" "*.db-wal" "*.db-shm" "*/Crash Reports/*"
            else
                backup_zip "ZEN BROWSER (Nativo)" "$TMP_DIR/zen-${USERNAME}.zip" ".zen" -x "*.db-wal" "*.db-shm" "*/Crash Reports/*"
            fi
            ;;
        "CALIBRE")
            killall calibre &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.calibre_ebook.calibre'; then
                backup_zip "CALIBRE (Flatpak)" "$TMP_DIR/calibre-flatpak-${USERNAME}.zip" ".var/app/com.calibre_ebook.calibre" -x "*/caches/*"
            else
                backup_zip "CALIBRE (Nativo)" "$TMP_DIR/calibre-${USERNAME}.zip" ".config/calibre" -x "calibre/caches/*"
            fi
            ;;
        "WAVEBOX")
            killall wavebox &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'io.wavebox.Wavebox'; then
                backup_zip "WAVEBOX (Flatpak)" "$TMP_DIR/wavebox-flatpak-${USERNAME}.zip" ".var/app/io.wavebox.Wavebox" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*" "*/Crash Reports/*" "*/Storage/*"
            else
                backup_zip "WAVEBOX (Nativo)" "$TMP_DIR/wavebox-${USERNAME}.zip" ".config/wavebox" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*" "*/Crash Reports/*" "*/Storage/*"
            fi
            ;;
        "RAMBOX")
            killall rambox &>/dev/null; sleep 1
            backup_zip "RAMBOX" "$TMP_DIR/rambox-${USERNAME}.zip" ".config/rambox" -x "*Cache*" "*cache*"
            ;;
        "FERDIUM")
            killall ferdium &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'org.ferdium.Ferdium'; then
                backup_zip "FERDIUM (Flatpak)" "$TMP_DIR/ferdium-flatpak-${USERNAME}.zip" ".var/app/org.ferdium.Ferdium" -x "*Cache*" "*cache*"
            else
                backup_zip "FERDIUM (Nativo)" "$TMP_DIR/ferdium-${USERNAME}.zip" ".config/Ferdium" -x "*Cache*" "*cache*"
            fi
            ;;
        "NEXTCLOUD")
            killall nextcloud &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.nextcloud.desktopclient.nextcloud'; then
                backup_zip "NEXTCLOUD (Flatpak)" "$TMP_DIR/nextcloud-flatpak-${USERNAME}.zip" ".var/app/com.nextcloud.desktopclient.nextcloud" -x "*/logs/*"
            else
                backup_zip "NEXTCLOUD (Nativo)" "$TMP_DIR/nextcloud-${USERNAME}.zip" ".config/Nextcloud" -x "Nextcloud/logs/*"
            fi
            ;;
        "FILEZILLA")
            killall filezilla &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'org.filezillaproject.Filezilla'; then
                backup_zip "FILEZILLA (Flatpak)" "$TMP_DIR/filezilla-flatpak-${USERNAME}.zip" ".var/app/org.filezillaproject.Filezilla"
            else
                backup_zip "FILEZILLA (Nativo)" "$TMP_DIR/filezilla-${USERNAME}.zip" ".config/filezilla"
            fi
            ;;
        "TRANSMISSION")
            killall transmission &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.transmissionbt.Transmission'; then
                backup_zip "TRANSMISSION (Flatpak)" "$TMP_DIR/transmission-flatpak-${USERNAME}.zip" ".var/app/com.transmissionbt.Transmission"
            else
                backup_zip "TRANSMISSION (Nativo)" "$TMP_DIR/transmission-${USERNAME}.zip" ".config/transmission-daemon"
            fi
            ;;
        "OBSIDIAN")
            killall obsidian &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'md.obsidian.Obsidian'; then
                backup_zip "OBSIDIAN (Flatpak)" "$TMP_DIR/obsidian-flatpak-${USERNAME}.zip" ".var/app/md.obsidian.Obsidian"
            else
                backup_zip "OBSIDIAN (Nativo)" "$TMP_DIR/obsidian-${USERNAME}.zip" ".config/obsidian"
            fi
            ;;
        "ZOTERO")
            killall zotero &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'org.zotero.Zotero'; then
                backup_zip "ZOTERO (Flatpak)" "$TMP_DIR/zotero-flatpak-${USERNAME}.zip" ".var/app/org.zotero.Zotero" "Zotero"
            else
                backup_zip "ZOTERO (Nativo)" "$TMP_DIR/zotero-${USERNAME}.zip" ".zotero" "Zotero"
            fi
            ;;
        "TINTERO")
            killall tintero &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'app.tintero.Tintero'; then
                backup_zip "TINTERO (Flatpak)" "$TMP_DIR/tintero-flatpak-${USERNAME}.zip" ".var/app/app.tintero.Tintero" "tintero"
            else
                backup_zip "TINTERO (Nativo)" "$TMP_DIR/tintero-${USERNAME}.zip" ".config/tintero" "tintero"
            fi
            ;;
        "MASTER_PDF")
            killall masterpdfeditor5 &>/dev/null; sleep 1
            backup_zip "MASTER_PDF" "$TMP_DIR/master_pdf-${USERNAME}.zip" ".masterpdfeditor" ".config/Code Industry"
            ;;
        "PICARD")
            killall picard &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'org.musicbrainz.Picard'; then
                backup_zip "PICARD (Flatpak)" "$TMP_DIR/picard-flatpak-${USERNAME}.zip" ".var/app/org.musicbrainz.Picard"
            else
                backup_zip "PICARD (Nativo)" "$TMP_DIR/picard-${USERNAME}.zip" ".picard" "picard"
            fi
            ;;
        "VSCODE")
            killall code code-oss &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.visualstudio.code'; then
                backup_zip "VSCODE (Flatpak)" "$TMP_DIR/vscode-flatpak-${USERNAME}.zip" ".var/app/com.visualstudio.code" -x "*/CachedData/*" "*/CachedExtensionVSIXs/*"
            else
                backup_zip "VSCODE (Nativo)" "$TMP_DIR/vscode-${USERNAME}.zip" ".vscode" ".config/Code" -x ".config/Code/CachedData/*" ".config/Code/CachedExtensionVSIXs/*"
            fi
            ;;
        "ANTIGRAVITY")
            killall antigravity &>/dev/null; sleep 1
            backup_zip "ANTIGRAVITY" "$TMP_DIR/antigravity-${USERNAME}.zip" ".antigravity" ".config/Antigravity" -x ".config/Antigravity/CachedData/*" ".config/Antigravity/CachedExtensionVSIXs/*"
            ;;
        "PYCHARM")
            killall pycharm.sh pycharm &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.jetbrains.PyCharm-Professional'; then
                backup_zip "PYCHARM (Flatpak)" "$TMP_DIR/pycharm-flatpak-${USERNAME}.zip" ".var/app/com.jetbrains.PyCharm-Professional"
            else
                backup_zip "PYCHARM (Nativo)" "$TMP_DIR/pycharm-${USERNAME}.zip" ".pycharm" ".config/pycharm"
            fi
            ;;
        "DBEAVER")
            killall dbeaver &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'io.dbeaver.DBeaverCommunity'; then
                backup_zip "DBEAVER (Flatpak)" "$TMP_DIR/dbeaver-flatpak-${USERNAME}.zip" ".var/app/io.dbeaver.DBeaverCommunity"
            else
                backup_zip "DBEAVER (Nativo)" "$TMP_DIR/dbeaver-${USERNAME}.zip" ".dbeaver" ".config/dbeaver"
            fi
            ;;
        "REMMINA")
            killall remmina &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'org.remmina.Remmina'; then
                backup_zip "REMMINA (Flatpak)" "$TMP_DIR/remmina-flatpak-${USERNAME}.zip" ".var/app/org.remmina.Remmina"
            else
                backup_zip "REMMINA (Nativo)" "$TMP_DIR/remmina-${USERNAME}.zip" ".remmina" ".config/remmina"
            fi
            ;;
        "POSTMAN")
            killall postman &>/dev/null; sleep 1
            if flatpak list --app 2>/dev/null | grep -q 'com.getpostman.Postman'; then
                backup_zip "POSTMAN (Flatpak)" "$TMP_DIR/postman-flatpak-${USERNAME}.zip" ".var/app/com.getpostman.Postman"
            else
                backup_zip "POSTMAN (Nativo)" "$TMP_DIR/postman-${USERNAME}.zip" ".postman" ".config/postman"
            fi
            ;;
        "SYSTEM_SETTINGS")
            if command -v dconf &>/dev/null; then dconf dump / > "$TMP_DIR/dconf-settings.dump"; fi
            backup_zip "SYSTEM_SETTINGS" "$TMP_DIR/system-settings-${USERNAME}.zip" ".config" ".local/share" ".themes" ".icons" -x "*/Cache/*" "*/cache/*" ".config/google-chrome/*" ".config/BraveSoftware/*" ".mozilla/*"
            if [ -f "$TMP_DIR/dconf-settings.dump" ]; then
                zip -qju "$DEST_DIR/system-settings-${USERNAME}.zip" "$TMP_DIR/dconf-settings.dump"
            fi
            ;;
        *)
            log_error "Lógica para '$app' não foi implementada. Pulando."
            ;;
    esac

    # Fecha a janela de progresso
    kill "$YAD_PID" 2>/dev/null || true
    wait "$YAD_PID" 2>/dev/null || true
done

log_msg "============================================================"
log_msg "=== PROCESSO DE BACKUP CONCLUÍDO ==="

# Exibe a notificação final para o usuário.
yad --info --title="Backup Concluído" \
    --text="<big><b>O processo de backup foi concluído!</b></big>\n\nUm log detalhado da operação foi salvo em:\n<b>$LOG_FILE</b>\n\nEssa janela será fechada automaticamente em 10 segundos." \
    --width=450 --height=150 --timeout=10

exit 0
