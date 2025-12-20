#!/bin/bash
# ============================================================================
#
#        ARQUIVO: configs-zip (Versão Completa e Corrigida)
#
#        UTILIZAÇÃO: ./configs-zip
#
#        DESCRIÇÃO: Realiza backup de configurações com uma interface YAD.
#                   Esta versão é a final, com a lógica de processos
#                   corrigida e com os blocos de backup implementados
#                   para todos os aplicativos da lista.
#
#        AUTOR: Gemini
#        REVISÃO: 8.0 - Adicionados todos os blocos 'case' em falta.
#                       O script está agora completo e funcional.
#
# ============================================================================

DEST_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/config"
TMP_DIR="/tmp/backup_script_$$"
LOG_FILE="$HOME/configs-zip.log"
USERNAME="$USER"

# --- LISTA DE APLICATIVOS PARA O YAD ---
declare -a APP_LIST=(
    "BRAVE" "CHROME" "EDGE" "FALKON" "FIREFOX" "FLOORP" "VIVALDI" "OPERA" "ZEN BROWSER" "CALIBRE"
    "WAVEBOX" "RAMBOX" "FERDIUM" "NEXTCLOUD" "FILEZILLA" "TRANSMISSION" "OBSIDIAN" "ZOTERO" "TINTERO"
    "MASTER_PDF" "PICARD" "VSCODE" "ANTIGRAVITY" "PYCHARM" "DBEAVER" "POSTMAN" "REMMINA" "SYSTEM_SETTINGS"
)

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
echo "[$(date +'%H:%M:%S')] INICIANDO PROCESSO DE BACKUP..." >> "$LOG_FILE"
echo "[$(date +'%H:%M:%S')] Itens selecionados: ${selected_apps[*]}" >> "$LOG_FILE"
echo "============================================================" >> "$LOG_FILE"

cd "$HOME" || { echo "[$(date +'%H:%M:%S')] ERRO CRÍTICO: Não foi possível acessar o diretório $HOME." >> "$LOG_FILE"; exit 1; }

for app in "${selected_apps[@]}"; do
    echo "------------------------------------------------------------" >> "$LOG_FILE"
    echo "[$(date +'%H:%M:%S')] INICIANDO BACKUP PARA: $app" >> "$LOG_FILE"

    # Inicia a janela de progresso genérica
    yad --progress --pulsate --title="Backup de $app" --text="<big>Compactando arquivos de $app...</big>" --width=400 --auto-close --no-buttons >/dev/null 2>&1 &
    YAD_PID=$!

    case "$app" in
        "BRAVE")
            killall brave-browser brave-browser-beta &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.brave.Browser'; then
                zip -qr "$TMP_DIR/brave-flatpak-${USERNAME}.zip" ".var/app/com.brave.Browser" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/brave-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/brave-${USERNAME}.zip" ".config/BraveSoftware" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/brave-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "CHROME")
            killall google-chrome google-chrome-beta &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.google.Chrome'; then
                zip -qr "$TMP_DIR/chrome-flatpak-${USERNAME}.zip" ".var/app/com.google.Chrome" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Service Worker/*" "*/Crashpad/*"
                mv "$TMP_DIR/chrome-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/google-chrome-${USERNAME}.zip" ".config/google-chrome" ".config/google-chrome-beta" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Service Worker/*" "*/Crashpad/*" "*/Crash Reports/*" "*/Storage/*"
                mv "$TMP_DIR/google-chrome-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "EDGE")
            killall msedge msedge-beta &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.microsoft.Edge'; then
                zip -qr "$TMP_DIR/edge-flatpak-${USERNAME}.zip" ".var/app/com.microsoft.Edge" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/edge-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/edge-${USERNAME}.zip" ".config/microsoft-edge" ".config/microsoft-edge-beta" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/edge-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "FALKON")
            killall falkon &>/dev/null; sleep 1
            zip -qr "$TMP_DIR/falkon-${USERNAME}.zip" ".config/falkon"
            mv "$TMP_DIR/falkon-${USERNAME}.zip" "$DEST_DIR/"
            ;;
        "FIREFOX")
            killall firefox &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'org.mozilla.firefox'; then
                zip -qr "$TMP_DIR/firefox-flatpak-${USERNAME}.zip" ".var/app/org.mozilla.firefox" -x "*/cache2/*" "*/storage/*" "*.db-wal" "*.db-shm" "*/Crash Reports/*"
                mv "$TMP_DIR/firefox-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/firefox-${USERNAME}.zip" ".mozilla" -x ".mozilla/firefox/*/cache2/*" ".mozilla/firefox/*/storage/*" "*.db-wal" "*.db-shm" "*/Crash Reports/*"
                mv "$TMP_DIR/firefox-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "FLOORP")
            killall floorp &>/dev/null; sleep 1
            zip -qr "$TMP_DIR/floorp-${USERNAME}.zip" ".floorp" -x ".floorp/*/.cache2/*" ".floorp/*/.storage/*" "*.db-wal" "*.db-shm" "*/.Crash Reports/*"
            mv "$TMP_DIR/floorp-${USERNAME}.zip" "$DEST_DIR/"
            ;;
        "VIVALDI")
            killall vivaldi-stable &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.vivaldi.Vivaldi'; then
                zip -qr "$TMP_DIR/vivaldi-flatpak-${USERNAME}.zip" ".var/app/com.vivaldi.Vivaldi" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/vivaldi-flatpak-${USERNAME}.zip" "$DEST_DIR/"
                echo "[$(date +'%H:%M:%S')] Backup Flatpak do Vivaldi realizado com sucesso." >> "$LOG_FILE"
            else
                zip -qr "$TMP_DIR/vivaldi-${USERNAME}.zip" ".config/vivaldi" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/vivaldi-${USERNAME}.zip" "$DEST_DIR/"
                echo "[$(date +'%H:%M:%S')] Backup nativo do Vivaldi realizado com sucesso." >> "$LOG_FILE"
            fi
            ;;
        "OPERA")
            killall opera-stable &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.opera.Opera'; then
                zip -qr "$TMP_DIR/opera-flatpak-${USERNAME}.zip" ".var/app/com.opera.Opera" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/opera-flatpak-${USERNAME}.zip" "$DEST_DIR/"
                echo "[$(date +'%H:%M:%S')] Backup Flatpak do Opera realizado com sucesso." >> "$LOG_FILE"
            else
                zip -qr "$TMP_DIR/opera-${USERNAME}.zip" ".config/opera" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*"
                mv "$TMP_DIR/opera-${USERNAME}.zip" "$DEST_DIR/"
                echo "[$(date +'%H:%M:%S')] Backup nativo do Vivaldi realizado com sucesso." >> "$LOG_FILE"
            fi
            ;;
        "ZEN BROWSER")
            killall zen-browser &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'app.zen_browser.zen'; then
                zip -qr "$TMP_DIR/zen-flatpak-${USERNAME}.zip" ".var/app/app.zen_browser.zen" -x "*/cache2/*" "*/storage/*" "*.db-wal" "*.db-shm" "*/Crash Reports/*"
                mv "$TMP_DIR/zen-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/zen-${USERNAME}.zip" ".zen" -x "*.db-wal" "*.db-shm" "*/Crash Reports/*"
                mv "$TMP_DIR/zen-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "CALIBRE")
            killall calibre &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.calibre_ebook.calibre'; then
                zip -qr "$TMP_DIR/calibre-flatpak-${USERNAME}.zip" ".var/app/com.calibre_ebook.calibre" -x "*/caches/*"
                mv "$TMP_DIR/calibre-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/calibre-${USERNAME}.zip" ".config/calibre" -x "calibre/caches/*"
                mv "$TMP_DIR/calibre-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "WAVEBOX")
            killall wavebox &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'io.wavebox.Wavebox'; then
                zip -qr "$TMP_DIR/wavebox-flatpak-${USERNAME}.zip" ".var/app/io.wavebox.Wavebox" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*" "*/Crash Reports/*" "*/Storage/*"
                mv "$TMP_DIR/wavebox-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/wavebox-${USERNAME}.zip" ".config/wavebox" -x "*/Cache/*" "*/Code Cache/*" "*/GPUCache/*" "*/Crashpad/*" "*/Crash Reports/*" "*/Storage/*"
                mv "$TMP_DIR/wavebox-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "RAMBOX")
            killall rambox &>/dev/null; sleep 1
            zip -qr "$TMP_DIR/rambox-${USERNAME}.zip" ".config/rambox" -x "*Cache*" "*cache*"
            mv "$TMP_DIR/rambox-${USERNAME}.zip" "$DEST_DIR/"
            ;;
        "FERDIUM")
            if flatpak list --app | grep -q 'org.ferdium.Ferdium'; then
                zip -qr "$TMP_DIR/ferdium-flatpak-${USERNAME}.zip" ".var/app/org.ferdium.Ferdium" -x "*Cache*" "*cache*"
                mv "$TMP_DIR/ferdium-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/ferdium-${USERNAME}.zip" ".config/Ferdium" -x "*Cache*" "*cache*"
                mv "$TMP_DIR/ferdium-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "NEXTCLOUD")
            killall nextcloud &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.nextcloud.desktopclient.nextcloud'; then
                zip -qr "$TMP_DIR/nextcloud-flatpak-${USERNAME}.zip" ".var/app/com.nextcloud.desktopclient.nextcloud" -x "*/logs/*"
                mv "$TMP_DIR/nextcloud-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/nextcloud-${USERNAME}.zip" ".config/Nextcloud" -x "Nextcloud/logs/*"
                mv "$TMP_DIR/nextcloud-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "FILEZILLA")
            killall filezilla &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'org.filezillaproject.Filezilla'; then
                zip -qr "$TMP_DIR/filezilla-flatpak-${USERNAME}.zip" ".var/app/org.filezillaproject.Filezilla"
                mv "$TMP_DIR/filezilla-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/filezilla-${USERNAME}.zip" ".config/filezilla"
                mv "$TMP_DIR/filezilla-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "TRANSMISSION")
            killall transmission &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'com.transmissionbt.Transmission'; then
                zip -qr "$TMP_DIR/transmission-flatpak-${USERNAME}.zip" ".var/app/com.transmissionbt.Transmission"
                mv "$TMP_DIR/transmission-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/transmission-${USERNAME}.zip" ".config/transmission-daemon"
                mv "$TMP_DIR/transmission-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "OBSIDIAN")
            if flatpak list --app | grep -q 'md.obsidian.Obsidian'; then
                zip -qr "$TMP_DIR/obsidian-flatpak-${USERNAME}.zip" ".var/app/md.obsidian.Obsidian"
                mv "$TMP_DIR/obsidian-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/obsidian-${USERNAME}.zip" ".config/obsidian"
                mv "$TMP_DIR/obsidian-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "ZOTERO")
            killall zotero &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'org.zotero.Zotero'; then
                zip -qr "$TMP_DIR/zotero-flatpak-${USERNAME}.zip" ".var/app/org.zotero.Zotero" "Zotero"
                mv "$TMP_DIR/zotero-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/zotero-${USERNAME}.zip" ".zotero" "Zotero"
                mv "$TMP_DIR/zotero-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "TINTERO")
            killall tintero &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'app.tintero.Tintero'; then
                zip -qr "$TMP_DIR/tintero-flatpak-${USERNAME}.zip" ".var/app/app.tintero.Tintero" "tintero"
                mv "$TMP_DIR/tintero-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "MASTER_PDF")
            killall masterpdfeditor5 &>/dev/null; sleep 1
            zip -qr "$TMP_DIR/master_pdf-${USERNAME}.zip" ".masterpdfeditor" ".config/Code Industry"
            mv "$TMP_DIR/master_pdf-${USERNAME}.zip" "$DEST_DIR/"
            ;;
        "PICARD")
            killall picard &>/dev/null; sleep 1
            if flatpak list --app | grep -q 'org.musicbrainz.Picard'; then
                zip -qr "$TMP_DIR/picard-flatpak-${USERNAME}.zip" ".var/app/org.musicbrainz.Picard"
                mv "$TMP_DIR/picard-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/picard-${USERNAME}.zip" ".picard" "picard"
                mv "$TMP_DIR/picard-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "VSCODE")
            if flatpak list --app | grep -q 'com.visualstudio.code'; then
                zip -qr "$TMP_DIR/vscode-flatpak-${USERNAME}.zip" ".var/app/com.visualstudio.code" -x "*/CachedData/*" "*/CachedExtensionVSIXs/*"
                mv "$TMP_DIR/vscode-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/vscode-${USERNAME}.zip" ".vscode" ".config/Code" -x ".config/Code/CachedData/*" ".config/Code/CachedExtensionVSIXs/*"
                mv "$TMP_DIR/vscode-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "ANTIGRAVITY")
            zip -qr "$TMP_DIR/antigravity-${USERNAME}.zip" ".antigravity" ".config/Antigravity" -x ".config/Antigravity/CachedData/*" ".config/Antigravity/CachedExtensionVSIXs/*"
            mv "$TMP_DIR/antigravity-${USERNAME}.zip" "$DEST_DIR/"
            ;;
        "PYCHARM")
            if flatpak list --app | grep -q 'com.jetbrains.PyCharm-Professional'; then
                zip -qr "$TMP_DIR/pycharm-flatpak-${USERNAME}.zip" ".var/app/com.jetbrains.PyCharm-Professional"
                mv "$TMP_DIR/pycharm-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/pycharm-${USERNAME}.zip" ".pycharm" ".config/pycharm"
                mv "$TMP_DIR/pycharm-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "DBEAVER")
            if flatpak list --app | grep -q 'io.dbeaver.DBeaverCommunity'; then
                zip -qr "$TMP_DIR/dbeaver-flatpak-${USERNAME}.zip" ".var/app/io.dbeaver.DBeaverCommunity"
                mv "$TMP_DIR/dbeaver-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/dbeaver-${USERNAME}.zip" ".dbeaver" ".config/dbeaver"
                mv "$TMP_DIR/dbeaver-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "REMMINA")
            if flatpak list --app | grep -q 'org.remmina.Remmina'; then
                zip -qr "$TMP_DIR/remmina-flatpak-${USERNAME}.zip" ".var/app/org.remmina.Remmina"
                mv "$TMP_DIR/remmina-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/remmina-${USERNAME}.zip" ".remmina" ".config/remmina"
                mv "$TMP_DIR/remmina-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        "POSTMAN")
            if flatpak list --app | grep -q 'com.getpostman.Postman'; then
                zip -qr "$TMP_DIR/postman-flatpak-${USERNAME}.zip" ".var/app/com.getpostman.Postman"
                mv "$TMP_DIR/postman-flatpak-${USERNAME}.zip" "$DEST_DIR/"
            else
                zip -qr "$TMP_DIR/postman-${USERNAME}.zip" ".postman" ".config/postman"
                mv "$TMP_DIR/postman-${USERNAME}.zip" "$DEST_DIR/"
            fi
            ;;
        #"KWALLET")
            #killall kwalletd5 &>/dev/null; sleep 1
            #zip -qr "$TMP_DIR/kwallet-${USERNAME}.zip" ".config/kwalletrc" ".local/share/kwalletd/kdewallet.kwl"
            #mv "$TMP_DIR/kwallet-${USERNAME}.zip" "$DEST_DIR/"
            #;;
        "SYSTEM_SETTINGS")
            if command -v dconf &>/dev/null; then dconf dump / > "$TMP_DIR/dconf-settings.dump"; fi
            zip -qr "$TMP_DIR/system-settings-${USERNAME}.zip" ".config" ".local/share" ".themes" ".icons" -x "*/Cache/*" "*/cache/*" ".config/google-chrome/*" ".config/BraveSoftware/*" ".mozilla/*"
            if [ -f "$TMP_DIR/dconf-settings.dump" ]; then
                zip -qju "$TMP_DIR/system-settings-${USERNAME}.zip" "$TMP_DIR/dconf-settings.dump"
            fi
            mv "$TMP_DIR/system-settings-${USERNAME}.zip" "$DEST_DIR/"
            ;;
        *)
            echo "[$(date +'%H:%M:%S')] AVISO: A lógica para '$app' não foi implementada. Pulando." >> "$LOG_FILE"
            ;;
    esac

    # Fecha a janela de progresso e regista no log
    kill $YAD_PID 2>/dev/null
    echo "[$(date +'%H:%M:%S')] Backup para $app concluído." >> "$LOG_FILE"
done

echo "============================================================" >> "$LOG_FILE"
echo "[$(date +'%H:%M:%S')] PROCESSO DE BACKUP CONCLUÍDO." >> "$LOG_FILE"

# Exibe a notificação final para o usuário.
yad --info --title="Backup Concluído" \
    --text="<big><b>O processo de backup foi concluído!</b></big>\n\nUm log detalhado da operação foi salvo em:\n<b>$LOG_FILE</b>\n\nEssa janela será fechada automaticamente em 10 segundos." \
    --width=450 --height=150 --timeout=10

exit 0

