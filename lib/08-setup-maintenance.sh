#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/08-setup-maintenance.sh
# Versão: 1.0.0 (Novo)
# Descrição: Cria scripts de manutenção e configura timers systemd
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Configurando scripts de manutenção do sistema..."

# ==============================================================================
# 1. SCRIPT DE ATUALIZAÇÃO (up)
# ==============================================================================

log "INFO" "Criando script de atualização: /usr/local/bin/up"

cat <<'EOF' | $SUDO tee /usr/local/bin/up > /dev/null
#!/usr/bin/env bash
# Script de atualização multi-distro

set -e

echo "--- Atualizando sistema ---"

# Carrega informações da distro
if [ -f /etc/os-release ]; then
    source /etc/os-release
fi

VARIANT="${VARIANT:-}"

# Fedora Kinoite (ostree-based)
if [[ "$VARIANT" == "Kinoite" ]]; then
    echo "[INFO] Atualizando Fedora Kinoite..."
    if sudo fuser /var/lib/rpm/.rpm.lock &>/dev/null; then
        echo "[ERRO] Banco de dados RPM em uso. Aguarde."
        exit 1
    fi
    sudo rpm-ostree upgrade
    echo "--- Atualização concluída (Kinoite). Reinicie para aplicar. ---"
    exit 0
fi

# Arch Linux
if [[ "$ID" =~ ^(arch|rebornos|archcraft|cachyos|endeavouros|manjaro|biglinux)$ ]]; then
    echo "[INFO] Atualizando Arch Linux..."
    
    # Aguarda lock do pacman se necessário
    LOCK="/var/lib/pacman/db.lck"
    timeout=15
    waited=0
    while [[ -e "$LOCK" ]] && sudo fuser "$LOCK" &>/dev/null; do
        sleep 1
        ((waited++))
        if (( waited >= timeout )); then
            echo "[AVISO] Lock do pacman não liberado. Tentando forçar..."
            sudo rm -f "$LOCK" 2>/dev/null || true
            break
        fi
    done
    
    if command -v paru &>/dev/null; then
        paru -Syu --noconfirm
    else
        sudo pacman -Syu --noconfirm
    fi
    
    # Limpeza
    if command -v paccache &>/dev/null; then
        sudo paccache -r -k3
    fi
    
    # Remove pacotes órfãos
    orphans="$(pacman -Qtdq 2>/dev/null || true)"
    if [[ -n "$orphans" ]]; then
        echo "[INFO] Removendo pacotes órfãos..."
        sudo pacman -Rns --noconfirm $orphans || true
    fi
    exit 0
fi

# Debian/Ubuntu
if [[ "$ID" =~ ^(debian|ubuntu|elementary|neon|zorin|lingmo|siduction)$ ]]; then
    echo "[INFO] Atualizando Debian/Ubuntu..."
    
    # Repara dependências quebradas
    if ! sudo apt -f install -y; then
        echo "[AVISO] Reconfigurando pacotes..."
        sudo dpkg --configure -a
    fi
    
    sudo apt update
    
    if command -v apt-fast &>/dev/null; then
        sudo DEBIAN_FRONTEND=noninteractive apt-fast full-upgrade -y
    else
        sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    fi
    
    sudo apt autoremove -y
    sudo apt clean
    exit 0
fi

# Fedora
if [[ "$ID" =~ ^(fedora|rhel|nobara)$ ]]; then
    echo "[INFO] Atualizando Fedora..."
    
    if sudo fuser /var/lib/rpm/.rpm.lock &>/dev/null; then
        echo "[ERRO] Banco de dados RPM em uso. Aguarde."
        exit 1
    fi
    
    sudo dnf upgrade --refresh -y
    sudo dnf autoremove -y
    sudo dnf clean all
    exit 0
fi

echo "[ERRO] Distribuição não suportada: $ID"
exit 1
EOF

$SUDO chmod +x /usr/local/bin/up
log "SUCCESS" "Script 'up' criado"

# ==============================================================================
# 2. SCRIPT DE MANUTENÇÃO COMPLETA (upsnapshot)
# ==============================================================================

log "INFO" "Criando script de manutenção completa: /usr/local/bin/upsnapshot"

cat <<'EOF' | $SUDO tee /usr/local/bin/upsnapshot > /dev/null
#!/usr/bin/env bash
# Script de manutenção completa do sistema

set -e

echo "--- Iniciando manutenção completa ---"

# 1. Atualização de pacotes
echo "[1/4] Atualizando pacotes do sistema..."
/usr/local/bin/up || true

# 2. Flatpak (se disponível)
if command -v flatpak &>/dev/null; then
    echo "[2/4] Atualizando Flatpaks..."
    sudo flatpak update --noninteractive --assumeyes || true
    
    echo "[2/4] Removendo runtimes não utilizados..."
    sudo flatpak uninstall --unused --assumeyes || true
fi

# 3. Pipx (se disponível)
if command -v pipx &>/dev/null; then
    echo "[3/4] Atualizando pacotes pipx..."
    pipx upgrade-all || true
fi

# 4. Snap (se disponível)
if command -v snap &>/dev/null; then
    echo "[4/4] Atualizando pacotes snap..."
    sudo snap refresh || true
fi

# Limpeza de logs
echo "[Limpeza] Limpando logs do journal..."
sudo journalctl --vacuum-time=2d

echo "--- Manutenção completa finalizada ---"
EOF

$SUDO chmod +x /usr/local/bin/upsnapshot
log "SUCCESS" "Script 'upsnapshot' criado"

# ==============================================================================
# 3. SCRIPT DE CORREÇÃO DE PERMISSÕES
# ==============================================================================

log "INFO" "Criando script de correção de permissões: /usr/local/bin/fixperm"

cat <<'EOF' | $SUDO tee /usr/local/bin/fixperm > /dev/null
#!/usr/bin/env bash
# Script para corrigir permissões do sistema

echo "--- Corrigindo permissões ---"

USER="${1:-$USER}"

echo "Corrigindo permissões para: $USER"
sudo chown -R "$USER:$USER" ~
sudo chmod -R 755 /usr/local/share/scripts/ 2>/dev/null || true
sudo chmod -R 755 /usr/local/bin/ 2>/dev/null || true

echo "--- Permissões corrigidas ---"
EOF

$SUDO chmod +x /usr/local/bin/fixperm
log "SUCCESS" "Script 'fixperm' criado"

# ==============================================================================
# 4. SYSTEMD TIMER PARA MANUTENÇÃO AUTOMÁTICA
# ==============================================================================

log "INFO" "Configurando timer systemd para manutenção automática..."

# Service
cat <<'EOF' | $SUDO tee /etc/systemd/system/upsnapshot.service > /dev/null
[Unit]
Description=Executa manutenção completa do sistema (v3rtech-scripts)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/upsnapshot
StandardOutput=journal
StandardError=journal
EOF

# Timer
cat <<'EOF' | $SUDO tee /etc/systemd/system/upsnapshot.timer > /dev/null
[Unit]
Description=Timer para manutenção diária do sistema (v3rtech-scripts)

[Timer]
OnBootSec=30min
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Ativa o timer
$SUDO systemctl daemon-reload
$SUDO systemctl enable --now upsnapshot.timer

log "SUCCESS" "Timer systemd configurado"

# ==============================================================================
# 5. OTIMIZAÇÕES DE SISTEMA
# ==============================================================================

log "INFO" "Aplicando otimizações de sistema..."

# Systemd-journald (reduz uso de disco)
log "INFO" "Configurando systemd-journald..."
$SUDO mkdir -p /etc/systemd/journald.conf.d
cat <<'EOF' | $SUDO tee /etc/systemd/journald.conf.d/99-v3rtech.conf > /dev/null
[Journal]
Storage=persistent
SystemMaxUse=100M
RuntimeMaxUse=50M
MaxRetentionSec=7day
EOF

# Sysctl (otimizações de kernel)
log "INFO" "Aplicando otimizações de sysctl..."
cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-v3rtech-tuning.conf > /dev/null
# ==============================================================================
# Otimizações de performance - v3rtech-scripts
# ==============================================================================

# Memória virtual
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Inotify (para file watchers)
fs.inotify.max_user_watches=1048576

# Limites de arquivo
fs.file-max=2097152
EOF

$SUDO sysctl --system > /dev/null 2>&1 || true

log "SUCCESS" "Otimizações de sistema aplicadas"

# ==============================================================================
# 6. OTIMIZAÇÕES DE ARMAZENAMENTO (FSTAB & FSTRIM)
# ==============================================================================

log "INFO" "Otimizando fstab e armazenamento..."

# Executa otimização de fstab
OPTIMIZE_SCRIPT="$UTILS_DIR/optimize-fstab.sh"

if [ -f "$OPTIMIZE_SCRIPT" ]; then
    log "INFO" "Executando otimizador de fstab..."
    if $SUDO "$OPTIMIZE_SCRIPT"; then
        log "SUCCESS" "✓ Fstab otimizado"
        # Recarrega systemd daemon para processar mudanças no fstab (se necessário mount -a faria o remount)
        $SUDO systemctl daemon-reload
        # Opcional: Remount para aplicar sem reiniciar? 
        # mount -o remount / 2>/dev/null || true
        # Mas fstab é majoritariamente para o próximo boot, exceto lazytime/commit que podem ser remount.
        # Vamos manter simples.
    else
        log "WARN" "⚠ Falha ao executar otimizador de fstab"
    fi
else
    log "WARN" "Script de otimização não encontrado: $OPTIMIZE_SCRIPT"
fi

# Habilita fstrim.timer
log "INFO" "Habilitando fstrim.timer..."
if $SUDO systemctl enable --now fstrim.timer; then
    log "SUCCESS" "✓ fstrim.timer habilitado"
else
    log "WARN" "⚠ Falha ao habilitar fstrim.timer"
fi

log "SUCCESS" "Configuração de manutenção concluída."

