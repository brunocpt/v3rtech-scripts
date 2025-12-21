#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/07-setup-user-dirs.sh
# Versão: 2.0.0 (Melhorado - Com Bookmarks e Links Simbólicos)
# Descrição: Configura diretórios do usuário, links simbólicos, bookmarks GTK
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Configurando diretórios do usuário e bookmarks..."

# Valida se o usuário está definido
if [ -z "$REAL_USER" ] || [ -z "$HOME" ]; then
    log "WARN" "Variáveis REAL_USER ou REAL_HOME não definidas"
    return 1
fi

# ==============================================================================
# 1. CRIAÇÃO DE DIRETÓRIOS ESSENCIAIS
# ==============================================================================

log "INFO" "Criando diretórios essenciais..."

# Diretórios do usuário
mkdir -p "$HOME"/{.backup,.config/autostart,.config/systemd/user}
mkdir -p "$HOME"/{Desktop,Documents,Pictures,Music,Videos}
mkdir -p "$HOME"/.local/bin

# Diretórios do sistema
$SUDO mkdir -p /etc/sudoers.d /mnt/LAN
$SUDO chmod 755 /usr/local/bin

log "SUCCESS" "Diretórios criados"

# ==============================================================================
# 2. CONFIGURAÇÃO DE LINKS SIMBÓLICOS (BOOKMARKS)
# ==============================================================================

log "INFO" "Configurando links simbólicos para pastas estratégicas..."

# Remove diretórios padrão (se existirem como diretórios reais)
if [ -d "$HOME/Downloads" ] && [ ! -L "$HOME/Downloads" ]; then
    rm -rf "$HOME/Downloads"
fi

# Cria links simbólicos para pastas de rede (se existirem)
if [ -d "/mnt/trabalho/Downloads" ]; then
    ln -sf "/mnt/trabalho/Downloads" "$HOME/Downloads"
    log "SUCCESS" "Link criado: ~/Downloads → /mnt/trabalho/Downloads"
else
    mkdir -p "$HOME/Downloads"
    log "INFO" "Diretório local criado: ~/Downloads"
fi

# Link para pasta de trabalho
if [ -d "/mnt/trabalho" ]; then
    mkdir -p "$HOME"
    ln -sf "/mnt/trabalho" "$HOME/Trabalho"
    log "SUCCESS" "Link criado: Trabalho → /mnt/trabalho"
fi

# Link para pasta Cloud
if [ -d "/mnt/trabalho/Cloud" ]; then
    ln -sf "/mnt/trabalho/Cloud" "$HOME/Cloud"
    log "SUCCESS" "Link criado: Cloud → /mnt/trabalho/Cloud"
fi

# Link para pasta de Backup
if [ -d "/mnt/trabalho/Backup" ]; then
    ln -sf "/mnt/trabalho/Backup" "$HOME/Backup"
    log "SUCCESS" "Link criado: Backup → /mnt/trabalho/Backup"
fi

# ==============================================================================
# 3. CONFIGURAÇÃO DE BOOKMARKS GTK (Nautilus, Thunar, etc)
# ==============================================================================

log "INFO" "Configurando bookmarks GTK..."

# Arquivo de bookmarks do GTK
GTK_BOOKMARKS="$HOME/.local/share/gtk-3.0/bookmarks"

# Cria diretório se não existir
mkdir -p "$(dirname "$GTK_BOOKMARKS")"

# Remove arquivo antigo se existir
[ -f "$GTK_BOOKMARKS" ] && rm -f "$GTK_BOOKMARKS"

# Adiciona bookmarks (formato: file:///path Nome)
{
    echo "file://$HOME Desktop"
    echo "file://$HOME/Downloads Downloads"
    echo "file://$HOME/Documents Documentos"
    echo "file://$HOME/Pictures Imagens"
    echo "file://$HOME/Music Música"
    echo "file://$HOME/Videos Vídeos"
    
    # Adiciona bookmarks de rede (se existirem)
    if [ -d "/mnt/trabalho" ]; then
        echo "file:///mnt/trabalho Trabalho"
    fi
    
    if [ -d "/mnt/trabalho/Cloud" ]; then
        echo "file:///mnt/trabalho/Cloud Cloud"
    fi
    
    if [ -d "/mnt/trabalho/Downloads" ]; then
        echo "file:///mnt/trabalho/Downloads Downloads (Rede)"
    fi
    
    if [ -d "/mnt/trabalho/Backup" ]; then
        echo "file:///mnt/trabalho/Backup Backup"
    fi
    
    if [ -d "/mnt/LAN" ]; then
        echo "file:///mnt/LAN Rede LAN"
    fi
} > "$GTK_BOOKMARKS"

chown "$REAL_USER:$REAL_USER" "$GTK_BOOKMARKS"
chmod 644 "$GTK_BOOKMARKS"

log "SUCCESS" "Bookmarks GTK configurados"

# ==============================================================================
# 4. CONFIGURAÇÃO DE USER-DIRS (XDG)
# ==============================================================================

log "INFO" "Configurando diretórios XDG..."

# Arquivo de configuração XDG
XDG_DIRS="$HOME/.config/user-dirs.dirs"

# Cria arquivo de configuração XDG
mkdir -p "$(dirname "$XDG_DIRS")"

cat > "$XDG_DIRS" <<'EOF'
# This file is written by xdg-user-dirs-update
# If you want to change or remove the definitions used here, edit the file
# and run the command `xdg-user-dirs-update` afterwards to apply the changes.

XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
EOF

chown "$REAL_USER:$REAL_USER" "$XDG_DIRS"
chmod 644 "$XDG_DIRS"

# Atualiza XDG user dirs
$SUDO -u "$REAL_USER" xdg-user-dirs-update 2>/dev/null || true

log "SUCCESS" "Diretórios XDG configurados"

# ==============================================================================
# 5. CRIAÇÃO DE ARQUIVO .hushlogin (LOGIN SILENCIOSO)
# ==============================================================================

log "INFO" "Criando arquivo .hushlogin para login silencioso..."
touch "$HOME/.hushlogin"
chown "$REAL_USER:$REAL_USER" "$HOME/.hushlogin"
log "SUCCESS" "Login silencioso configurado"

# ==============================================================================
# 6. CONFIGURAÇÃO DE GRUPOS
# ==============================================================================

log "INFO" "Configurando grupos do usuário..."

# Grupo fuse (para montagem de sistemas de arquivos)
if ! id -nG "$REAL_USER" | grep -qw "fuse"; then
    log "INFO" "Adicionando $REAL_USER ao grupo fuse..."
    $SUDO usermod -aG fuse "$REAL_USER"
    log "INFO" "Reinicie a sessão para aplicar mudanças de grupo"
fi

# Grupo autologin (para alguns display managers)
$SUDO groupadd -r autologin 2>/dev/null || true
$SUDO gpasswd -a "$REAL_USER" autologin 2>/dev/null || true

log "SUCCESS" "Grupos configurados"

# ==============================================================================
# 7. CONFIGURAÇÃO DE FUSE
# ==============================================================================

log "INFO" "Configurando FUSE..."

FUSE_CONF="/etc/fuse.conf"

if [ -f "$FUSE_CONF" ]; then
    # Verifica se user_allow_other já está presente e descomentada
    if grep -qE "^[[:space:]]*user_allow_other[[:space:]]*$" "$FUSE_CONF"; then
        log "INFO" "user_allow_other já está configurado em $FUSE_CONF"
    elif grep -qE "^[[:space:]]*#.*user_allow_other" "$FUSE_CONF"; then
        log "INFO" "Descomentando user_allow_other em $FUSE_CONF..."
        $SUDO sed -i "s|^[[:space:]]*#\s*user_allow_other|user_allow_other|" "$FUSE_CONF"
    else
        log "INFO" "Adicionando user_allow_other a $FUSE_CONF..."
        echo "user_allow_other" | $SUDO tee -a "$FUSE_CONF" > /dev/null
    fi
else
    log "INFO" "Criando $FUSE_CONF com user_allow_other..."
    echo "user_allow_other" | $SUDO tee "$FUSE_CONF" > /dev/null
fi

log "SUCCESS" "FUSE configurado"

# ==============================================================================
# 8. ESTRUTURA DE REDE (OPCIONAL)
# ==============================================================================

log "INFO" "Verificando estrutura de rede (/mnt/LAN)..."

# Cria estrutura de diretórios de rede
$SUDO mkdir -p /mnt/LAN/{DNS320L,AppData,Backup,Cloud,Downloads,Musicas,SOs,Videos}
$SUDO chown -R "$REAL_USER:$REAL_USER" /mnt/LAN 2>/dev/null || true

log "SUCCESS" "Estrutura de rede verificada"

# ==============================================================================
# 9. PERMISSÕES FINAIS
# ==============================================================================

log "INFO" "Ajustando permissões finais..."

# Garante que o usuário é proprietário de seu home
$SUDO chown -R "$REAL_USER:$REAL_USER" "$HOME"

# Permissões de scripts locais
$SUDO chmod -R 755 /usr/local/share/scripts/ 2>/dev/null || true
$SUDO chmod -R 755 /usr/local/bin/ 2>/dev/null || true

log "SUCCESS" "Permissões ajustadas"

log "SUCCESS" "Configuração de diretórios do usuário concluída."
