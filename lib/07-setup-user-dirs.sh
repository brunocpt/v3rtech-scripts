#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/07-setup-user-dirs.sh
# Versão: 2.3.1 (Logic Fix - Fuse Config Deduplication)
# Descrição: Configura diretórios do usuário, links simbólicos, bookmarks GTK
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Configurando diretórios do usuário e bookmarks..."

# Valida se o usuário está definido
if [ -z "$REAL_USER" ] || [ -z "$REAL_HOME" ]; then
    log "WARN" "Variáveis REAL_USER ou REAL_HOME não definidas"
    return 1
fi

# ==============================================================================
# 1. CRIAÇÃO DE DIRETÓRIOS ESSENCIAIS
# ==============================================================================

log "INFO" "Criando diretórios essenciais..."

# Diretórios do usuário
mkdir -p "$REAL_HOME"/{.backup,.config/autostart,.config/systemd/user}
mkdir -p "$REAL_HOME"/{Desktop,Documents,Pictures,Music,Videos}
mkdir -p "$REAL_HOME"/.local/bin

# Diretórios do sistema
$SUDO mkdir -p /etc/sudoers.d
$SUDO chmod 755 /usr/local/bin

log "SUCCESS" "Diretórios criados"

# ==============================================================================
# 2. CONFIGURAÇÃO DE LINKS SIMBÓLICOS (BOOKMARKS)
# ==============================================================================

log "INFO" "Configurando links simbólicos para pastas estratégicas..."

# Função auxiliar para criar links simbólicos sem loops
create_safe_symlink() {
    local target="$1"
    local link_path="$2"
    local link_name="$3"
    
    # Verifica se o alvo existe
    if [ ! -d "$target" ]; then
        log "DEBUG" "Alvo não existe: $target"
        return 1
    fi
    
    # Resolve o caminho real do alvo (sem links simbólicos)
    local target_real=$(cd "$target" 2>/dev/null && pwd -P)
    
    # Resolve o caminho real do link (se ele já existir)
    local link_real=""
    if [ -L "$link_path" ]; then
        link_real=$(cd "$(dirname "$link_path")" 2>/dev/null && pwd -P)/$(basename "$(readlink "$link_path")")
    fi
    
    # Verifica se o link já aponta para o alvo correto
    if [ "$link_real" = "$target_real" ]; then
        log "DEBUG" "Link já existe e está correto: $link_name"
        return 0
    fi
    
    # Verifica se criar este link causaria um loop (alvo contém o link)
    if [[ "$target_real" == "$link_path"* ]]; then
        log "WARN" "⚠ Loop detectado! Não criando link: $link_name"
        log "WARN" "  Alvo: $target_real"
        log "WARN" "  Link: $link_path"
        return 1
    fi
    
    # Remove link antigo se existir
    if [ -L "$link_path" ]; then
        rm -f "$link_path"
    fi
    
    # Cria o novo link
    if ln -sf "$target" "$link_path"; then
        log "SUCCESS" "Link criado: $link_name → $target"
        return 0
    else
        log "WARN" "⚠ Falha ao criar link: $link_name"
        return 1
    fi
}

# Remove diretórios padrão (se existirem como diretórios reais)
if [ -d "$REAL_HOME/Downloads" ] && [ ! -L "$REAL_HOME/Downloads" ]; then
    rm -rf "$REAL_HOME/Downloads"
fi

# Link para pasta Downloads
create_safe_symlink "/mnt/trabalho/Downloads" "$REAL_HOME/Downloads" "~/Downloads"

# Se Downloads não foi criado como link, cria como diretório
if [ ! -e "$REAL_HOME/Downloads" ]; then
    mkdir -p "$REAL_HOME/Downloads"
    log "INFO" "Diretório local criado: ~/Downloads"
fi

# Link para pasta de trabalho
create_safe_symlink "/mnt/trabalho" "$REAL_HOME/Desktop/Trabalho" "~/Desktop/Trabalho"

# Link para pasta Cloud (COM PROTEÇÃO CONTRA LOOP)
create_safe_symlink "/mnt/trabalho/Cloud" "$REAL_HOME/Desktop/Cloud" "~/Desktop/Cloud"

# Link para pasta de Backup
create_safe_symlink "/mnt/trabalho/Backup" "$REAL_HOME/Desktop/Backup" "~/Desktop/Backup"

# ==============================================================================
# 3. CONFIGURAÇÃO DE BOOKMARKS GTK (Nautilus, Thunar, etc)
# ==============================================================================

log "INFO" "Configurando bookmarks GTK..."

# Arquivo de bookmarks do GTK
GTK_BOOKMARKS="$REAL_HOME/.local/share/gtk-3.0/bookmarks"

# Cria diretório se não existir
mkdir -p "$(dirname "$GTK_BOOKMARKS")"

# Remove arquivo antigo se existir
[ -f "$GTK_BOOKMARKS" ] && rm -f "$GTK_BOOKMARKS"

# Verifica se existe arquivo de bookmarks no projeto
BOOKMARKS_SOURCE="$BASE_DIR/configs/bookmarks"

if [ -f "$BOOKMARKS_SOURCE" ]; then
    # Copia arquivo de bookmarks do projeto
    log "INFO" "Copiando arquivo de bookmarks de $BOOKMARKS_SOURCE..."
    cp "$BOOKMARKS_SOURCE" "$GTK_BOOKMARKS"
    log "SUCCESS" "Arquivo de bookmarks copiado"
else
    # Cria bookmarks padrão se arquivo não existir
    log "INFO" "Arquivo de bookmarks não encontrado, criando padrão..."
    
    {
        echo "file://$REAL_HOME Desktop"
        echo "file://$REAL_HOME/Downloads Downloads"
        echo "file://$REAL_HOME/Documents Documentos"
        echo "file://$REAL_HOME/Pictures Imagens"
        echo "file://$REAL_HOME/Music Música"
        echo "file://$REAL_HOME/Videos Vídeos"
        
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
    
    log "SUCCESS" "Bookmarks padrão criados"
fi

# Ajusta permissões
chown "$REAL_USER:$REAL_USER" "$GTK_BOOKMARKS"
chmod 644 "$GTK_BOOKMARKS"

log "SUCCESS" "Bookmarks GTK configurados"

# ==============================================================================
# 4. CONFIGURAÇÃO DE USER-DIRS (XDG)
# ==============================================================================

log "INFO" "Configurando diretórios XDG..."

# Arquivo de configuração XDG
XDG_DIRS="$REAL_HOME/.config/user-dirs.dirs"

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
touch "$REAL_HOME/.hushlogin"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.hushlogin"
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
    # 1. Limpeza de Duplicatas e Normalização:
    # Remove todas as linhas que são EXATAMENTE 'user_allow_other' ou '#user_allow_other'
    # exceto a primeira ocorrência encontrada. Isso evita conflitos de múltiplas definições.
    
    # Conta quantas vezes a diretiva (ativa ou comentada) aparece de forma isolada
    OCURRENCIAS=$(grep -cE "^#?[[:space:]]*user_allow_other[[:space:]]*$" "$FUSE_CONF")

    if [ "$OCURRENCIAS" -gt 1 ]; then
        log "INFO" "Limpando duplicatas de user_allow_other em $FUSE_CONF..."
        # Mantém apenas a primeira ocorrência e remove as demais
        $SUDO sed -i '0,/^#\?[[:space:]]*user_allow_other[[:space:]]*$/{s/^#\?[[:space:]]*user_allow_other[[:space:]]*$/USER_KEEP_MARKER/}; /^#\?[[:space:]]*user_allow_other[[:space:]]*$/d; s/USER_KEEP_MARKER/user_allow_other/' "$FUSE_CONF"
    fi

    # 2. Verificação e Ativação:
    if grep -qE "^user_allow_other[[:space:]]*$" "$FUSE_CONF"; then
        log "INFO" "user_allow_other já está configurado e único em $FUSE_CONF"
    
    elif grep -qE "^#[[:space:]]*user_allow_other[[:space:]]*$" "$FUSE_CONF"; then
        log "INFO" "Descomentando a linha única de user_allow_other..."
        $SUDO sed -i "s|^#[[:space:]]*user_allow_other[[:space:]]*$|user_allow_other|" "$FUSE_CONF"
    
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
# 8. PERMISSÕES FINAIS
# ==============================================================================

log "INFO" "Ajustando permissões finais..."

# Garante que o usuário é proprietário de seu home
$SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME"

# Permissões de scripts locais
$SUDO chmod -R 755 /usr/local/share/scripts/ 2>/dev/null || true
$SUDO chmod -R 755 /usr/local/bin/ 2>/dev/null || true

log "SUCCESS" "Permissões ajustadas"

log "SUCCESS" "Configuração de diretórios do usuário concluída."
