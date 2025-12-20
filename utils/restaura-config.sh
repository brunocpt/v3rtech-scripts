#!/bin/bash

DEST_DIR="/mnt/trabalho/Cloud/Compartilhado/Linux/config"
LOG_FILE="$HOME/restaura-config.log"
USERNAME="$USER"
> "$LOG_FILE"

SELECTION=$(yad --title="Restauração de Configurações" \
    --text="<big><b>Selecione os aplicativos para restaurar</b></big>" \
    --list --checklist --width=500 --height=600 \
    --column="Restaurar" --column="Aplicativo" \
    FALSE "BRAVE" FALSE "CHROME" FALSE "EDGE" FALSE "FALKON" \
    FALSE "FIREFOX" FALSE "FLOORP" FALSE "VIVALDI" FALSE "OPERA" FALSE "CALIBRE" \
    FALSE "WAVEBOX" FALSE "RAMBOX" FALSE "FERDIUM" FALSE "NEXTCLOUD" \
    FALSE "FILEZILLA" FALSE "TRANSMISSION" FALSE "OBSIDIAN" FALSE "ZOTERO" \
    FALSE "MASTER_PDF" FALSE "PICARD" FALSE "VSCODE" FALSE "SYSTEM_SETTINGS" FALSE "KWALLET" \
    --button="Selecionar Todos:2" --button="Desmarcar Todos:3" --button="Iniciar:0" --button="Cancelar:1")

[ $? -ne 0 ] && echo "[$(date +'%H:%M:%S')] Operação cancelada." >> "$LOG_FILE" && exit 0

mapfile -t selected_apps < <(echo "$SELECTION" | awk -F'|' '{for(i=1;i<=NF;i+=2) if ($i == "TRUE") print $(i+1)}')

yad --question --title="Confirmar Restauração" \
    --text="Deseja realmente restaurar os aplicativos selecionados?" \
    --button=Sim:0 --button=Não:1
[ $? -ne 0 ] && echo "[$(date +'%H:%M:%S')] Restauração cancelada pelo usuário." >> "$LOG_FILE" && exit 0

for app in "${selected_apps[@]}"; do

    yad --progress --pulsate --title="Restaurando $app" --text="Extraindo backup..." \
        --width=400 --auto-close --no-buttons >/dev/null &
    YAD_PID=$!

    echo "[$(date +'%H:%M:%S')] Iniciando restauração para $app" >> "$LOG_FILE"

    case "$app" in
        "BRAVE")
            if flatpak list --app | grep -q com.brave.Browser; then
                echo "[$(date +'%H:%M:%S')] Extraindo: brave-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/brave-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v brave-browser &>/dev/null || [ -d "$HOME/.config/BraveSoftware" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: brave-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/brave-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "CHROME")
            if flatpak list --app | grep -q com.google.Chrome; then
                echo "[$(date +'%H:%M:%S')] Extraindo: chrome-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/chrome-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v google-chrome &>/dev/null || [ -d "$HOME/.config/google-chrome" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: google-chrome-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/google-chrome-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "EDGE")
            if flatpak list --app | grep -q com.microsoft.Edge; then
                echo "[$(date +'%H:%M:%S')] Extraindo: edge-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/edge-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v msedge &>/dev/null || [ -d "$HOME/.config/microsoft-edge" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: edge-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/edge-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "FALKON")
            if command -v falkon &>/dev/null || [ -d "$HOME/.config/falkon" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: falkon-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/falkon-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "FIREFOX")
            if flatpak list --app | grep -q org.mozilla.firefox; then
                echo "[$(date +'%H:%M:%S')] Extraindo: firefox-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/firefox-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v firefox &>/dev/null || [ -d "$HOME/.mozilla" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: firefox-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/firefox-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "FLOORP")
            if command -v floorp &>/dev/null || [ -d "$HOME/.floorp" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: floorp-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/floorp-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "VIVALDI")
            if flatpak list --app | grep -q com.vivaldi.Vivaldi; then
                echo "[$(date +'%H:%M:%S')] Extraindo: vivaldi-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/vivaldi-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v vivaldi-stable &>/dev/null || [ -d "$HOME/.config/vivaldi" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: vivaldi-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/vivaldi-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "OPERA")
            if flatpak list --app | grep -q com.opera.Opera; then
                echo "[$(date +'%H:%M:%S')] Extraindo: opera-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/opera-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v opera-stable &>/dev/null || [ -d "$HOME/.config/opera" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: opera-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/opera-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "CALIBRE")
            if flatpak list --app | grep -q com.calibre_ebook.calibre; then
                echo "[$(date +'%H:%M:%S')] Extraindo: calibre-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/calibre-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v calibre &>/dev/null || [ -d "$HOME/.config/calibre" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: calibre-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/calibre-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "WAVEBOX")
            if flatpak list --app | grep -q io.wavebox.Wavebox; then
                echo "[$(date +'%H:%M:%S')] Extraindo: wavebox-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/wavebox-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v wavebox &>/dev/null || [ -d "$HOME/.config/wavebox" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: wavebox-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/wavebox-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "RAMBOX")
            if command -v rambox &>/dev/null || [ -d "$HOME/.config/rambox" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: rambox-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/rambox-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "FERDIUM")
            if flatpak list --app | grep -q org.ferdium.Ferdium; then
                echo "[$(date +'%H:%M:%S')] Extraindo: ferdium-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/ferdium-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if [ -d "$HOME/.config/Ferdium" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: ferdium-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/ferdium-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "NEXTCLOUD")
            if flatpak list --app | grep -q com.nextcloud.desktopclient.nextcloud; then
                echo "[$(date +'%H:%M:%S')] Extraindo: nextcloud-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/nextcloud-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if [ -d "$HOME/.config/Nextcloud" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: nextcloud-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/nextcloud-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "FILEZILLA")
            if flatpak list --app | grep -q org.filezillaproject.Filezilla; then
                echo "[$(date +'%H:%M:%S')] Extraindo: filezilla-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/filezilla-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v filezilla &>/dev/null || [ -d "$HOME/.config/filezilla" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: filezilla-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/filezilla-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "TRANSMISSION")
            if flatpak list --app | grep -q com.transmissionbt.Transmission; then
                echo "[$(date +'%H:%M:%S')] Extraindo: transmission-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/transmission-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if [ -d "$HOME/.config/transmission-daemon" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: transmission-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/transmission-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "OBSIDIAN")
            if flatpak list --app | grep -q md.obsidian.Obsidian; then
                echo "[$(date +'%H:%M:%S')] Extraindo: obsidian-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/obsidian-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if [ -d "$HOME/.config/obsidian" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: obsidian-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/obsidian-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "ZOTERO")
            if flatpak list --app | grep -q org.zotero.Zotero; then
                echo "[$(date +'%H:%M:%S')] Extraindo: zotero-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/zotero-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if [ -d "$HOME/.zotero" ] || [ -d "$HOME/Zotero" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: zotero-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/zotero-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "MASTER_PDF")
            echo "[$(date +'%H:%M:%S')] Extraindo: master_pdf-$USERNAME.zip" >> "$LOG_FILE"
            unzip -oq "$DEST_DIR/master_pdf-$USERNAME.zip" -d "$HOME"
            ;;
        "PICARD")
            if flatpak list --app | grep -q org.musicbrainz.Picard; then
                echo "[$(date +'%H:%M:%S')] Extraindo: picard-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/picard-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if command -v picard-stable &>/dev/null || [ -d "$HOME/.config/picard" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: picard-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/picard-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "VSCODE")
            if flatpak list --app | grep -q com.visualstudio.code; then
                echo "[$(date +'%H:%M:%S')] Extraindo: vscode-flatpak-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/vscode-flatpak-$USERNAME.zip" -d "$HOME"
            fi
            if [ -d "$HOME/.vscode" ] || [ -d "$HOME/.config/Code" ]; then
                echo "[$(date +'%H:%M:%S')] Extraindo: vscode-$USERNAME.zip" >> "$LOG_FILE"
                unzip -oq "$DEST_DIR/vscode-$USERNAME.zip" -d "$HOME"
            fi
            ;;
        "KWALLET")
            echo "[$(date +'%H:%M:%S')] Extraindo: kwallet-$USERNAME.zip" >> "$LOG_FILE"
            unzip -oq "$DEST_DIR/kwallet-$USERNAME.zip" -d "$HOME"
            ;;
        "SYSTEM_SETTINGS")
            echo "[$(date +'%H:%M:%S')] Extraindo: system-settings-$USERNAME.zip" >> "$LOG_FILE"
            unzip -oq "$DEST_DIR/system-settings-$USERNAME.zip" -d "$HOME"
            unzip -p "$DEST_DIR/system-settings-$USERNAME.zip" dconf-settings.dump > /tmp/dconf-settings.dump 2>/dev/null
            if [ -s /tmp/dconf-settings.dump ]; then
                echo "[$(date +'%H:%M:%S')] Aplicando dconf-settings.dump" >> "$LOG_FILE"
                dconf load / < /tmp/dconf-settings.dump
            fi
            ;;
    esac

    kill "$YAD_PID" 2>/dev/null
    chown -R "$USER:$USER" "$HOME"
    echo "[$(date +'%H:%M:%S')] Restauração concluída para $app" >> "$LOG_FILE"
done

yad --info --title="Restauração Concluída" \
    --text="<big><b>O processo de restauração foi concluído!</b></big>\n\nO log foi salvo em:\n<b>$LOG_FILE</b>\n\nEsta janela será fechada em 10 segundos." \
    --width=450 --height=150 --timeout=10

