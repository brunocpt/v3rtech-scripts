#!/usr/bin/env bash
# ==============================================================================
# Script: calibre-up.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalação e atualização automatizada do Calibre E-book Manager
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

set -euo pipefail

# Variáveis
CALIBRE_DESKTOP="/usr/share/applications/calibre.desktop"
CALIBRE_BIN="/opt/calibre/calibre"
CALIBRE_ICON="/opt/calibre/resources/images/library.png"
INSTALLER="/tmp/linux-installer.sh"

echo "Baixando instalador oficial do Calibre..."
curl -fsSL -o "$INSTALLER" "https://download.calibre-ebook.com/linux-installer.sh"
sudo chmod 755 "$INSTALLER"
sudo sh "$INSTALLER"

# Cria entrada de menu .desktop (se não existir)
if [ -f "$CALIBRE_BIN" ]; then
  sudo tee "$CALIBRE_DESKTOP" >/dev/null <<EOF
[Desktop Entry]
Version=1.0
Name=Calibre
Exec=$CALIBRE_BIN %F
Icon=$CALIBRE_ICON
Type=Application
Categories=Office;Viewer;Application;
EOF
  echo "Menu do Calibre criado."
else
  echo "Aviso: Binário do Calibre não encontrado em $CALIBRE_BIN."
fi

# Cria timer e serviço systemd para atualizar semanalmente
sudo tee /etc/systemd/system/calibre-up.service >/dev/null <<EOF
[Unit]
Description=Atualiza Calibre (oficial)
[Service]
Type=oneshot
ExecStart=$INSTALLER
EOF

sudo tee /etc/systemd/system/calibre-up.timer >/dev/null <<EOF
[Unit]
Description=Atualiza Calibre semanalmente (timer)
[Timer]
Unit=calibre-up.service
OnCalendar=Sat *-*-* 12:00:00
Persistent=true
[Install]
WantedBy=timers.target
EOF

# Ativa o timer
sudo systemctl daemon-reload
sudo systemctl enable --now calibre-up.timer

echo "Instalação e atualização automática do Calibre configuradas!"

