#!/bin/bash
# backup-atalhos.sh – Backup universal de atalhos de teclado + configs do Dolphin no KDE

USER=$(logname)
HOME_DIR=$(eval echo "~$USER")
DEST="/mnt/trabalho/Cloud/Compartilhado/Linux/v3rtech-scripts/backups"
DE=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

TMP="$DEST/tmp-$USER"
mkdir -p "$TMP"

case "$DE" in
  *plasma*|*kde*)
    echo "[INFO] KDE/Plasma detectado – copiando arquivos de atalhos..."
    cp "$HOME_DIR/.config/kglobalshortcutsrc" "$TMP/" 2>/dev/null
    cp "$HOME_DIR/.config/khotkeysrc" "$TMP/" 2>/dev/null

    echo "[INFO] Copiando configurações do Dolphin..."
    cp "$HOME_DIR/.config/dolphinrc" "$TMP/" 2>/dev/null
    cp "$HOME_DIR/.config/dolphin-viewmodesrc" "$TMP/" 2>/dev/null
    cp "$HOME_DIR/.local/share/user-places.xbel" "$TMP/" 2>/dev/null
    rsync -a --exclude='thumbnails/' "$HOME_DIR/.local/share/dolphin/" "$TMP/dolphin/" 2>/dev/null

    TARGET="$DEST/${USER}-atalhos-kde.zip"
    ;;

  *gnome*|*budgie*)
    echo "[INFO] GNOME/Budgie detectado – exportando DConf..."
    dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > "$TMP/custom-keybindings.dconf"
    TARGET="$DEST/${USER}-atalhos-gnome.zip"
    ;;

  *xfce*)
    echo "[INFO] XFCE detectado – copiando arquivo XML..."
    cp "$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" "$TMP/" 2>/dev/null
    TARGET="$DEST/${USER}-atalhos-xfce.zip"
    ;;

  *)
    echo "[ERRO] Ambiente de desktop não suportado: $DE"
    exit 1
    ;;
esac

cd "$TMP" && zip -r "$TARGET" . >/dev/null
rm -rf "$TMP"
echo "[SUCESSO] Backup salvo em: $TARGET"

