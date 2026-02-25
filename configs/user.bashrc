# ~/.bashrc

# Sai se não for shell interativo
[[ $- != *i* ]] && return

# ========== Cores ==========
Blue='\[\e[38;5;33m\]'
Cyan='\[\e[38;5;51m\]'
Yellow='\[\e[38;5;228m\]'
Green='\[\e[38;5;40m\]'
Reset='\[\e[0m\]'

# ========== Prompt ==========
export PS1="${Blue}[\u${Reset}@${Cyan}\h${Reset}]${Yellow}:\w${Reset}${Green} \$ ${Reset}"

# ========== PATH seguro ==========
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:$PATH"
[[ ":$PATH:" != *":$HOME/bin:"* ]] && PATH="$HOME/bin:$PATH"

# ========== Carrega configurações globais (aliases, PATHs, etc) ==========
if [ -f /etc/profile.d/custom_env.sh ]; then
  source /etc/profile.d/custom_env.sh
fi

# ========== shopt (opções úteis do Bash) ==========
shopt -s globstar        # '**' faz busca recursiva
shopt -s cdspell         # corrige erros leves em cd
shopt -s dirspell        # corrige erros leves em tab-complete
shopt -s nocaseglob      # globbing sem diferenciar maiúsculas/minúsculas

# ========== Histórico de comandos ==========
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# ========== Editor ==========
export EDITOR=nano

# ========== Ferramentas opcionais ==========
# bat em vez de cat (se estiver disponível)
if command -v bat &>/dev/null; then
  alias cat='bat --style=plain'
fi

# Sugestões automáticas de correção de comandos (thefuck)
if command -v thefuck &>/dev/null; then
  eval "$(thefuck --alias)"
fi

# ========== Funções úteis ==========

# Cria um arquivo .tar.gz a partir de um diretório
maketar() {
  tar cvzf "${1%%/}.tar.gz" "${1%%/}/"
}

# Cria um ZIP de um arquivo ou diretório
makezip() {
  zip -r "${1%%/}.zip" "$1"
}

# Extrai arquivos com base na extensão
extract() {
  if [ -z "$1" ]; then
    echo "Uso: extract <arquivo>"
    return 1
  elif [ ! -f "$1" ]; then
    echo "Erro: '$1' não existe."
    return 1
  fi

  case "$1" in
    *.tar.bz2)   tar xvjf "$1" ;;
    *.tar.gz)    tar xvzf "$1" ;;
    *.tar.xz)    tar xvJf "$1" ;;
    *.tar)       tar xvf "$1" ;;
    *.tbz2)      tar xvjf "$1" ;;
    *.tgz)       tar xvzf "$1" ;;
    *.bz2)       bunzip2 "$1" ;;
    *.gz)        gunzip "$1" ;;
    *.xz)        unxz "$1" ;;
    *.lzma)      unlzma "$1" ;;
    *.Z)         uncompress "$1" ;;
    *.zip)       unzip "$1" ;;
    *.rar)       unrar x "$1" ;;
    *.7z)        7z x "$1" ;;
    *.exe)       cabextract "$1" ;;
    *)           echo "extract: formato não reconhecido: '$1'" ;;
  esac
}

# Cria um diretório e entra nele
mcd() {
  mkdir -p "$1" && cd "$1"
}

# ========== Dircolors (colorização do ls) ==========
if command -v dircolors &> /dev/null; then
  if [ -r "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  elif [ -r "/etc/DIR_COLORS" ]; then
    eval "$(dircolors -b /etc/DIR_COLORS)"
  else
    eval "$(dircolors -b)"
  fi
fi

# === VS Code Workspace Autoload ===
if [ -n "$VSCODE_CWD" ]; then
  envfile="$VSCODE_CWD/.env"
  [ -f "$envfile" ] && source "$envfile"
fi

