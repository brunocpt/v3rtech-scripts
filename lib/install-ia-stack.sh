#!/bin/bash
# ==============================================================================
# Script: lib/install-ia-stack.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar stack completa de IA (PyTorch, Whisper, AnythingLLM, Ollama)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Instala stack completa de IA com suporte a NVIDIA CUDA:
# - PyTorch e TorchVision (com CUDA se GPU disponível)
# - Whisper (reconhecimento de fala via Git+Pipx)
# - AnythingLLM e Ollama (via Docker Compose)
# - Configuração automática para GPU NVIDIA
#
# Este script é independente e pode ser executado isoladamente.
#
# ==============================================================================

set -e

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
[ -z "$BASE_DIR" ] && BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }
source "$BASE_DIR/lib/detect-system.sh" || { echo "[ERRO] Não foi possível carregar lib/detect-system.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# DETECÇÃO DE HARDWARE
# ==============================================================================

detect_hardware() {
    log "STEP" "Detectando hardware..."

    # Detecta RAM
    MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM=$((MEM_KB / 1024 / 1024))
    log "INFO" "RAM disponível: ${TOTAL_RAM}GB"

    # Detecta GPU NVIDIA
    if lspci 2>/dev/null | grep -iq nvidia; then
        HAS_GPU_NVIDIA=true
        log "INFO" "GPU NVIDIA detectada"
    else
        HAS_GPU_NVIDIA=false
        log "INFO" "Nenhuma GPU NVIDIA detectada"
    fi

    # Salva configuração
    echo "HAS_GPU_NVIDIA=$HAS_GPU_NVIDIA" >> "$CONFIG_FILE"
    echo "TOTAL_RAM=$TOTAL_RAM" >> "$CONFIG_FILE"
}

# ==============================================================================
# INSTALAÇÃO DE DEPENDÊNCIAS
# ==============================================================================

install_dependencies() {
    log "STEP" "Instalando dependências do sistema..."

    case "$DISTRO_FAMILY" in
        arch)
            log "INFO" "Sincronizando repositórios Arch..."
            sudo pacman -Sy --noconfirm

            # Instala drivers NVIDIA se necessário
            if [ "$HAS_GPU_NVIDIA" = "true" ]; then
                if ! command -v nvidia-smi &>/dev/null; then
                    log "WARN" "Drivers NVIDIA não detectados. Tentando instalar..."
                    sudo pacman -S --noconfirm nvidia-open nvidia-utils nvidia-settings 2>/dev/null || \
                    sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings 2>/dev/null || \
                    log "ERROR" "Não foi possível instalar drivers NVIDIA"
                    log "WARN" "REINICIALIZAÇÃO NECESSÁRIA após o script!"
                fi
            fi

            log "INFO" "Instalando pacotes base e PyTorch CUDA..."
            local arch_packages=(
                "docker"
                "docker-compose"
                "python-pipx"
                "curl"
                "git"
                "python-pytorch-cuda"
                "python-torchvision-cuda"
                "python-numpy"
            )

            [ "$HAS_GPU_NVIDIA" = "true" ] && arch_packages+=("nvidia-container-toolkit")

            for pkg in "${arch_packages[@]}"; do
                i "$pkg" || log "WARN" "Falha ao instalar $pkg"
            done
            ;;

        debian|ubuntu)
            log "INFO" "Atualizando repositórios Debian/Ubuntu..."
            sudo apt-get update

            # Configura NVIDIA Container Toolkit se necessário
            if [ "$HAS_GPU_NVIDIA" = "true" ] && ! command -v nvidia-ctk &>/dev/null; then
                log "INFO" "Configurando NVIDIA Container Toolkit..."
                curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
                    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
                curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
                sudo apt-get update
            fi

            local deb_packages=(
                "docker.io"
                "docker-compose-v2"
                "python3-pipx"
                "curl"
                "git"
            )

            [ "$HAS_GPU_NVIDIA" = "true" ] && deb_packages+=("nvidia-container-toolkit")

            sudo apt-get install -y "${deb_packages[@]}"
            ;;

        fedora|redhat)
            log "INFO" "Instalando pacotes Fedora/RHEL..."

            local fed_packages=(
                "moby-engine"
                "docker-compose-plugin"
                "pipx"
                "curl"
                "git"
            )

            sudo dnf install -y "${fed_packages[@]}"

            # Configura NVIDIA Container Toolkit se necessário
            if [ "$HAS_GPU_NVIDIA" = "true" ] && ! command -v nvidia-ctk &>/dev/null; then
                log "INFO" "Configurando NVIDIA Container Toolkit..."
                curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
                    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
                sudo dnf install -y nvidia-container-toolkit
            fi
            ;;

        *)
            die "Distribuição não suportada: $DISTRO_FAMILY"
            ;;
    esac
}

# ==============================================================================
# CONFIGURAÇÃO DOCKER + NVIDIA
# ==============================================================================

configure_docker() {
    log "STEP" "Configurando Docker..."

    # Inicia Docker
    sudo systemctl enable --now docker 2>/dev/null || true

    # Configura NVIDIA Container Runtime se GPU disponível
    if [ "$HAS_GPU_NVIDIA" = "true" ]; then
        log "INFO" "Configurando NVIDIA Container Runtime..."
        sudo nvidia-ctk runtime configure --runtime=docker 2>/dev/null || true
        sudo systemctl restart docker 2>/dev/null || true
    fi

    log "SUCCESS" "Docker configurado"
}

# ==============================================================================
# INSTALAÇÃO DO WHISPER
# ==============================================================================

install_whisper() {
    log "STEP" "Instalando Whisper via Git+Pipx..."

    # Remove instalações anteriores
    pipx uninstall openai-whisper 2>/dev/null || true
    pipx uninstall whisper 2>/dev/null || true

    # Instala Whisper
    if [ "$DISTRO_FAMILY" = "arch" ]; then
        log "INFO" "Instalando Whisper com suporte a site-packages (Arch)..."
        pipx install git+https://github.com/openai/whisper.git --force --system-site-packages 2>/dev/null || \
        log "WARN" "Falha ao instalar Whisper com --system-site-packages"
    else
        log "INFO" "Instalando Whisper..."
        pipx install git+https://github.com/openai/whisper.git --force 2>/dev/null || \
        log "WARN" "Falha ao instalar Whisper"

        # Injeta suporte CUDA se GPU disponível
        if [ "$HAS_GPU_NVIDIA" = "true" ]; then
            log "INFO" "Injetando suporte CUDA (cu118) no Whisper..."
            pipx inject openai-whisper torch torchvision torchaudio \
                --index-url https://download.pytorch.org/whl/cu118 --force 2>/dev/null || \
            log "WARN" "Falha ao injetar CUDA no Whisper"
        fi
    fi

    # Cria symlink para /usr/bin/whisper
    if [ -f "$HOME/.local/bin/whisper" ]; then
        sudo ln -sf "$HOME/.local/bin/whisper" /usr/bin/whisper 2>/dev/null || true
        log "SUCCESS" "Whisper instalado em /usr/bin/whisper"
    else
        log "WARN" "Whisper não encontrado em $HOME/.local/bin/"
    fi
}

# ==============================================================================
# CONFIGURAÇÃO DOCKER COMPOSE
# ==============================================================================

setup_docker_compose() {
    log "STEP" "Configurando Docker Compose para AnythingLLM e Ollama..."

    # Cria diretório para Docker Compose
    local docker_dir="$HOME/docker/stack/ai-stack"
    mkdir -p "$docker_dir"

    log "INFO" "Diretório Docker: $docker_dir"

    # Cria arquivo .env
    cat > "$docker_dir/.env" <<EOF
# Configuração de Storage
ANYTHINGLLM_STORAGE=$docker_dir/anythingllm_storage
OLLAMA_STORAGE=$docker_dir/ollama_data

# Configuração de Segurança
JWT_SECRET="$(openssl rand -hex 16)"

# Configuração de Porta
SERVER_PORT=3001
EOF

    log "SUCCESS" "Arquivo .env criado"

    # Cria docker-compose.yml
    cat > "$docker_dir/docker-compose.yml" <<'EOF'
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ${OLLAMA_STORAGE}:/root/.ollama
    restart: always
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
EOF

    # Adiciona suporte GPU se disponível
    if [ "$HAS_GPU_NVIDIA" = "true" ]; then
        cat >> "$docker_dir/docker-compose.yml" <<'EOF'
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
EOF
    fi

    # Adiciona AnythingLLM
    cat >> "$docker_dir/docker-compose.yml" <<'EOF'

  anythingllm:
    image: mintplexlabs/anythingllm:latest
    container_name: anythingllm
    ports:
      - "${SERVER_PORT}:3001"
    environment:
      - STORAGE_DIR=/app/server/storage
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - ${ANYTHINGLLM_STORAGE}:/app/server/storage
    restart: always
    depends_on:
      - ollama
EOF

    log "SUCCESS" "docker-compose.yml criado"

    # Cria diretórios de storage
    mkdir -p "$docker_dir/anythingllm_storage" "$docker_dir/ollama_data"
    sudo chmod -R 777 "$docker_dir/" 2>/dev/null || true

    log "SUCCESS" "Diretórios de storage criados"
}

# ==============================================================================
# INICIAR CONTAINERS
# ==============================================================================

start_containers() {
    log "STEP" "Iniciando containers Docker..."

    local docker_dir="$HOME/docker/stack/ai-stack"

    cd "$docker_dir"
    sudo docker compose up -d

    log "SUCCESS" "Containers iniciados"

    # Aguarda Ollama ficar pronto
    log "INFO" "Aguardando Ollama ficar pronto (15s)..."
    sleep 15
}

# ==============================================================================
# DOWNLOAD DE MODELOS OLLAMA
# ==============================================================================

download_models() {
    log "STEP" "Baixando modelos Ollama..."

    # Define modelos com base em RAM e GPU
    local models=()

    if [ "$HAS_GPU_NVIDIA" = "true" ] && [ "$TOTAL_RAM" -ge 30 ]; then
        log "INFO" "GPU NVIDIA com 30GB+ RAM: instalando modelos grandes"
        models=("llama3.1:8b" "mistral-nemo" "deepseek-v2:lite")
    elif [ "$TOTAL_RAM" -ge 14 ]; then
        log "INFO" "14GB+ RAM: instalando modelos médios"
        models=("llama3.1:8b" "phi3:latest")
    else
        log "INFO" "Menos de 14GB RAM: instalando modelos pequenos"
        models=("phi3:mini" "tinyllama")
    fi

    # Baixa cada modelo
    for model in "${models[@]}"; do
        log "INFO" "Baixando modelo: $model"
        if ! sudo docker exec ollama ollama pull "$model" 2>/dev/null; then
            log "WARN" "Falha ao baixar $model. Tentando fallback..."
            case "$model" in
                "deepseek-v2:lite")
                    sudo docker exec ollama ollama pull "deepseek-coder" 2>/dev/null || \
                    log "WARN" "Fallback também falhou para $model"
                    ;;
                *)
                    log "WARN" "Nenhum fallback disponível para $model"
                    ;;
            esac
        else
            log "SUCCESS" "Modelo $model baixado com sucesso"
        fi
    done
}

# ==============================================================================
# VERIFICAÇÃO FINAL
# ==============================================================================

verify_installation() {
    log "STEP" "Verificando instalação..."

    local errors=0

    # Verifica Docker
    if command -v docker &>/dev/null; then
        log "SUCCESS" "Docker instalado"
    else
        log "ERROR" "Docker não encontrado"
        ((errors++))
    fi

    # Verifica Whisper
    if command -v whisper &>/dev/null; then
        log "SUCCESS" "Whisper instalado"
    else
        log "WARN" "Whisper não encontrado em PATH"
    fi

    # Verifica containers
    if sudo docker ps 2>/dev/null | grep -q "ollama\|anythingllm"; then
        log "SUCCESS" "Containers Docker rodando"
    else
        log "WARN" "Containers Docker não estão rodando"
    fi

    if [ $errors -eq 0 ]; then
        log "SUCCESS" "Instalação concluída com sucesso!"
        return 0
    else
        log "ERROR" "Instalação completada com erros"
        return 1
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

section "Instalação da Stack de IA"

# Detecta hardware
detect_hardware

# Instala dependências
install_dependencies

# Configura Docker
configure_docker

# Instala Whisper
install_whisper

# Configura Docker Compose
setup_docker_compose

# Inicia containers
start_containers

# Baixa modelos
download_models

# Verifica instalação
verify_installation

log "SUCCESS" "Stack de IA instalada com sucesso!"
log "INFO" "AnythingLLM disponível em: http://localhost:3001"
log "INFO" "Ollama disponível em: http://localhost:11434"

if [ "$HAS_GPU_NVIDIA" = "true" ]; then
    log "WARN" "Se você instalou drivers NVIDIA, é necessário REINICIAR o sistema!"
fi
