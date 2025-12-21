#!/bin/bash
# Instalação de ferramentas de Inteligência Artificial (Whisper + atalhos)

# ======================
# LOGS COLORIDOS
# ======================
VERMELHO=$(tput setaf 1)
VERDE=$(tput setaf 2)
AMARELO=$(tput setaf 3)
AZUL=$(tput setaf 4)
RESET=$(tput sgr0)

log_info()    { echo "${AZUL}[INFO] ${1}${RESET}"; }
log_success() { echo "${VERDE}[SUCESSO] ${1}${RESET}"; }
log_warn()    { echo "${AMARELO}[AVISO] ${1}${RESET}"; }
log_error()   { echo "${VERMELHO}[ERRO] ${1}${RESET}"; }

# ======================
# DETECÇÃO DE GPU
# ======================
detect_gpu() {
  if lspci | grep -i 'NVIDIA' &>/dev/null; then
    echo "nvidia"
  elif lspci | grep -i 'AMD' | grep -i 'VGA' &>/dev/null; then
    echo "amd"
  else
    echo "none"
  fi
}

GPU=$(detect_gpu)
log_info "GPU detectada: $GPU"

# ======================
# INSTALAÇÃO DO WHISPER
# ======================
log_info "Removendo instalações anteriores do Whisper..."
pipx uninstall whisper 2>/dev/null || true
pipx uninstall openai-whisper 2>/dev/null || true
rm -f ~/.local/bin/whisper

log_info "Instalando Whisper..."
#pipx install git+https://github.com/openai/whisper.git --force
pipx install openai-whisper --force

if [ "$GPU" = "nvidia" ]; then
  log_info "GPU NVIDIA detectada. Instalando suporte CUDA..."
  pipx inject openai-whisper torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
else
  log_info "Instalação padrão (CPU Only). Nenhuma GPU NVIDIA detectada."
fi

if [ ! -f /usr/bin/whisper ]; then
  log_info "Criando link simbólico para whisper em /usr/bin..."
  sudo ln -s "$HOME/.local/bin/whisper" /usr/bin/
fi

log_success "Whisper instalado com sucesso!"

# ======================
# OLLAMA (opcional - comentado)
# ======================
#: <<'OLLAMA'
# log_info "Instalando Ollama..."
# curl -fsSL https://ollama.com/install.sh | sh
# log_success "Ollama instalado. Você pode executar com: ollama run llama3.1"
#OLLAMA

# ======================
# FINALIZAÇÃO
# ======================
echo
log_success "Instalação de ferramentas de IA concluída!"

