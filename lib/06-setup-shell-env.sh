#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/06-setup-shell-env.sh
# Versão: 1.1.0 (Corrigido - Verdadeiramente Idempotente)
# Descrição: Configura ambiente de shell (bash/zsh) com aliases e variáveis
# Compatível com: Arch, Debian/Ubuntu, Fedora
# ==============================================================================

log "INFO" "Configurando ambiente de shell..."

# Valida se o usuário está definido
if [ -z "$REAL_USER" ] || [ -z "$REAL_HOME" ]; then
    log "WARN" "Variáveis REAL_USER ou REAL_HOME não definidas"
    return 1
fi

# Arquivo de configuração de aliases
BASHRC_FILE="$REAL_HOME/.bashrc"
ALIAS_MARKER="# v3rtech-scripts: Aliases e funções globais"
ALIAS_MARKER_END="# v3rtech-scripts: Fim de Aliases"

# Cria .bashrc se não existir
if [ ! -f "$BASHRC_FILE" ]; then
    log "INFO" "Criando $BASHRC_FILE..."
    cat > "$BASHRC_FILE" <<'EOF'
# ~/.bashrc: executado por bash(1) para shells interativos não-login.
# veja /usr/share/doc/bash/examples/startup-files (no pacote bash-doc)
# para exemplos

# Se não estiver rodando interativamente, não faz nada
case $- in
    *i*) ;;
      *) return;;
esac

# Não coloca linhas duplicadas ou linhas começando com espaço no histórico.
HISTCONTROL=ignoreboth

# Aumenta o tamanho do histórico
HISTSIZE=1000
HISTFILESIZE=2000

# Verifica o tamanho da janela após cada comando e, se necessário, atualiza LINES e COLUMNS.
shopt -s checkwinsize

# Habilita "globstar" para que ** funcione como recursivo
shopt -s globstar

# Torna menos verboso o bash
set +H

# Alias para ls
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lha'
alias l='ls -CF'

# Alias para grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Alias para navegação
alias ..='cd ..'
alias ...='cd ../..'

# Prompt colorido
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Habilita bash_completion se disponível
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
EOF
    chown "$REAL_USER:$REAL_USER" "$BASHRC_FILE"
fi

# Verifica se o bloco de aliases já existe
if grep -qF "$ALIAS_MARKER" "$BASHRC_FILE"; then
    log "INFO" "Aliases já configurados em $BASHRC_FILE. Removendo versão antiga..."
    
    # Remove o bloco antigo (entre MARKER e MARKER_END)
    # Usa sed para remover linhas entre os marcadores
    local TMPFILE
    TMPFILE=$(mktemp)
    
    # Copia o arquivo removendo o bloco antigo
    sed "/$ALIAS_MARKER/,/$ALIAS_MARKER_END/d" "$BASHRC_FILE" > "$TMPFILE"
    
    # Copia de volta
    cp "$TMPFILE" "$BASHRC_FILE"
    rm -f "$TMPFILE"
    
    log "INFO" "Versão antiga removida. Adicionando versão atualizada..."
else
    log "INFO" "Aliases não encontrados. Adicionando..."
fi

# Adiciona o bloco de aliases (agora com marcador de fim)
log "INFO" "Adicionando aliases ao $BASHRC_FILE..."

cat >> "$BASHRC_FILE" <<'EOF'

# ==============================================================================
# v3rtech-scripts: Aliases e funções globais
# ==============================================================================

# Exporta PATH para incluir diretórios locais
export PATH="$PATH:/usr/local/bin:/usr/local/share/scripts:$HOME/.local/bin"

# Define editor padrão
export EDITOR=nano

# Exporta variáveis de dados
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"

# Aliases úteis para gerenciamento de pacotes
if command -v pacman &>/dev/null; then
    alias update='sudo pacman -Syu'
    alias clean='sudo pacman -Sc --noconfirm'
    alias install='sudo pacman -S'
    alias remove='sudo pacman -R'
    alias search='pacman -Ss'
elif command -v apt &>/dev/null; then
    alias update='sudo apt update && sudo apt upgrade -y'
    alias clean='sudo apt autoremove -y && sudo apt clean'
    alias install='sudo apt install -y'
    alias remove='sudo apt remove -y'
    alias search='apt search'
elif command -v dnf &>/dev/null; then
    alias update='sudo dnf upgrade -y'
    alias clean='sudo dnf autoremove -y && sudo dnf clean all'
    alias install='sudo dnf install -y'
    alias remove='sudo dnf remove -y'
    alias search='dnf search'
fi

# Aliases de navegação
alias home='cd ~'
alias desk='cd ~/Desktop'
alias down='cd ~/Downloads'
alias docs='cd ~/Documents'

# Aliases de sistema
alias df='df -h'
alias du='du -h'
alias ps='ps aux'
alias top='top -u $USER'

# Função para criar diretório e entrar nele
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Função para extrair arquivos
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *)           echo "Não sei como extrair '$1'" ;;
        esac
    else
        echo "'$1' não é um arquivo válido"
    fi
}

# Função para criar arquivo .hushlogin (login silencioso)
hush() {
    touch ~/.hushlogin
    echo "Login silencioso ativado"
}

# v3rtech-scripts: Fim de Aliases
# ==============================================================================
EOF

chown "$REAL_USER:$REAL_USER" "$BASHRC_FILE"
log "SUCCESS" "Aliases adicionados ao $BASHRC_FILE"

log "SUCCESS" "Configuração de shell concluída."
