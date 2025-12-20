#!/bin/bash

# Script para configuração do Rclone

echo "Configurando Rclone..."

USER_CONFIG_DIR="/usr/local/share/scripts"

if command -v rclone &> /dev/null && [ "$USER" = "bruno" ]; then

  # Copia configuração do Rclone
  mkdir -p "$HOME/.config/rclone"
  cat "$USER_CONFIG_DIR/config/rclone.conf" | tee "$HOME/.config/rclone/rclone.conf" && echo "OK: Configuração do Rclone copiada." || echo "Aviso: rclone.conf não encontrado em ${USER_CONFIG_DIR}/config/ ou falha na cópia."

  echo "Configurando montagens de SharePoint via systemd user services (Rclone)..."

  # Cria diretórios de montagem
  sudo mkdir -p /mnt/LAN/ModalDiretoria /mnt/LAN/ModalProjetos/{RUI,AMA}
  sudo chown -R "$USER:$USER" /mnt/LAN/ModalDiretoria /mnt/LAN/ModalProjetos
  mkdir -p "$HOME/.config/systemd/user"

  # Cria arquivos de serviço systemd
  tee "$HOME/.config/systemd/user/rclone-SharepointModal.service" > /dev/null <<EOF
[Unit]
Description=Mount SharepointModal via rclone
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount SharepointModal:/ /mnt/LAN/ModalDiretoria --config=$HOME/.config/rclone/rclone.conf --vfs-cache-mode writes --allow-other
ExecStop=/usr/bin/fusermount -u /mnt/LAN/ModalDiretoria
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

  tee "$HOME/.config/systemd/user/rclone-SharepointModalProjetosAMA.service" > /dev/null <<EOF
[Unit]
Description=Mount SharePointModalProjetosAMA via rclone
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount SharePointModalProjetosAMA:/ /mnt/LAN/ModalProjetos/AMA --config=$HOME/.config/rclone/rclone.conf --vfs-cache-mode writes --allow-other
ExecStop=/usr/bin/fusermount -u /mnt/LAN/ModalProjetos/AMA
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

  tee "$HOME/.config/systemd/user/rclone-SharePointModalProjetosRUI.service" > /dev/null <<EOF
[Unit]
Description=Mount SharePointModalProjetosRUI via rclone
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount SharePointModalProjetosRUI:/ /mnt/LAN/ModalProjetos/RUI --config=$HOME/.config/rclone/rclone.conf --vfs-cache-mode writes --allow-other
ExecStop=/usr/bin/fusermount -u /mnt/LAN/ModalProjetos/RUI
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

  # Ativa linger
  echo "Habilitando linger para manter serviços ativos..."
  sudo loginctl enable-linger "$USER" && echo "Linger habilitado." || echo "Falha ao habilitar linger."

  # Ativa os serviços
  echo "Recarregando e habilitando serviços rclone-sharepoint..."
  systemctl --user stop rclone-*.service 2>/dev/null
  systemctl --user daemon-reload
  systemctl --user enable --now \
    rclone-SharepointModal.service \
    rclone-SharepointModalProjetosAMA.service \
    rclone-SharePointModalProjetosRUI.service

  echo "OK: Serviços de montagem de SharePoint configurados."

else
  echo "Aviso: Rclone não está instalado ou o usuário não é 'bruno'. Nenhuma configuração foi aplicada."
fi

