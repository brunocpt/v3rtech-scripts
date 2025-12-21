#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/11-setup-whisper.sh
# Versão: 1.0.0
# Descrição: Instalação especializada de OpenAI Whisper com suporte a GPU
# ==============================================================================

# --- CARREGA VARIÁVEIS GLOBAIS ---
# Espera que core/env.sh já tenha sido carregado
# Variáveis esperadas: SUDO, DISTRO_FAMILY, REAL_USER, BASE_DIR

# ==============================================================================
# FUNÇÃO: Detectar GPU
# ==============================================================================
detect_gpu() {
    if lspci 2>/dev/null | grep -i 'NVIDIA' &>/dev/null; then
        echo "nvidia"
    elif lspci 2>/dev/null | grep -i 'AMD' | grep -i 'VGA' &>/dev/null; then
        echo "amd"
    else
        echo "none"
    fi
}

# ==============================================================================
# FUNÇÃO: Instalar Whisper
# ==============================================================================
install_whisper() {
    log "STEP" "Instalando OpenAI Whisper..."
    
    # Detecta GPU
    local GPU=$(detect_gpu)
    log "INFO" "GPU detectada: $GPU"
    
    # 1. Remove instalações anteriores
    log "INFO" "Removendo instalações anteriores do Whisper..."
    pipx uninstall whisper 2>/dev/null || true
    pipx uninstall openai-whisper 2>/dev/null || true
    rm -f "$HOME/.local/bin/whisper" 2>/dev/null || true
    
    # 2. Instala Whisper com --force
    log "INFO" "Instalando openai-whisper via pipx..."
    if pipx install openai-whisper --force 2>/dev/null; then
        log "SUCCESS" "✓ OpenAI Whisper instalado"
    else
        log "ERROR" "Falha ao instalar OpenAI Whisper"
        return 1
    fi
    
    # 3. Se NVIDIA: injeta dependências CUDA
    if [ "$GPU" = "nvidia" ]; then
        log "INFO" "GPU NVIDIA detectada. Instalando suporte CUDA..."
        if pipx inject openai-whisper torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 2>/dev/null; then
            log "SUCCESS" "✓ Suporte CUDA instalado"
        else
            log "WARN" "⚠ Falha ao instalar suporte CUDA (pode continuar com CPU)"
        fi
    else
        log "INFO" "Nenhuma GPU NVIDIA detectada. Usando CPU."
    fi
    
    # 4. Cria link simbólico em /usr/bin (se não existir)
    if [ ! -f /usr/bin/whisper ]; then
        log "INFO" "Criando link simbólico para whisper em /usr/bin..."
        if $SUDO ln -s "$HOME/.local/bin/whisper" /usr/bin/whisper 2>/dev/null; then
            log "SUCCESS" "✓ Link simbólico criado"
        else
            log "WARN" "⚠ Falha ao criar link simbólico (Whisper pode estar em $HOME/.local/bin/whisper)"
        fi
    else
        log "DEBUG" "Link simbólico já existe em /usr/bin/whisper"
    fi
    
    # 5. Verifica instalação
    if command -v whisper &>/dev/null; then
        log "SUCCESS" "✓ Whisper instalado com sucesso"
        log "INFO" "Versão: $(whisper --version 2>/dev/null || echo 'desconhecida')"
        return 0
    else
        log "ERROR" "Whisper não foi encontrado após instalação"
        return 1
    fi
}

# ==============================================================================
# FUNÇÃO: Pós-Instalação de Whisper
# ==============================================================================
post_install_whisper() {
    log "INFO" "Executando pós-instalação de Whisper..."
    
    # Testa se Whisper está instalado
    if ! command -v whisper &>/dev/null; then
        log "WARN" "Whisper não está instalado, pulando pós-instalação"
        return 0
    fi
    
    # Cria diretório de modelos (se não existir)
    local MODELS_DIR="$HOME/.cache/whisper"
    if [ ! -d "$MODELS_DIR" ]; then
        log "INFO" "Criando diretório de cache para modelos do Whisper..."
        mkdir -p "$MODELS_DIR"
    fi
    
    log "SUCCESS" "✓ Pós-instalação de Whisper concluída"
}

# ==============================================================================
# EXECUÇÃO PRINCIPAL
# ==============================================================================

# Verifica se core/env.sh foi carregado
if [ -z "$SUDO" ]; then
    log "ERROR" "Variáveis globais não carregadas. Execute core/env.sh primeiro."
    exit 1
fi

# Verifica se pipx está instalado
if ! command -v pipx &>/dev/null; then
    log "ERROR" "pipx não está instalado. Instale com: pip3 install pipx"
    exit 1
fi

# Instala Whisper
if install_whisper; then
    # Executa pós-instalação
    post_install_whisper
    log "SUCCESS" "✓ Whisper pronto para usar!"
else
    log "ERROR" "Falha na instalação de Whisper"
    exit 1
fi
