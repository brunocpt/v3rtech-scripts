#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/logic-apps-reader.sh
# Versão: 11.5.0 (Com Suporte Especializado a Whisper)
# Descrição: Define lógica de instalação e integra alias 'i'.
# ==============================================================================

# --- HABILITA ALIASES NO SCRIPT ---
# Essencial para que o comando 'i' definido no aliases.geral funcione aqui.
shopt -s expand_aliases

# --- CARREGA ALIASES ---
# CORREÇÃO: Busca na pasta 'configs' (irmã da pasta lib ou data)
# Tenta caminho relativo (durante desenvolvimento/teste)
ALIASES_FILE="$(dirname "${BASH_SOURCE[0]}")/../configs/aliases.geral"

# Se não achar, tenta caminho absoluto de instalação
if [ ! -f "$ALIASES_FILE" ]; then
    ALIASES_FILE="/usr/local/share/scripts/v3rtech-scripts/configs/aliases.geral"
fi

if [ -f "$ALIASES_FILE" ]; then
    source "$ALIASES_FILE"
else
    log "WARN" "Aliases não encontrados em $ALIASES_FILE. O comando 'i' pode falhar."
fi

# Arrays Globais
declare -A APP_MAP_NATIVE
declare -A APP_MAP_FLATPAK
declare -A APP_MAP_METHOD

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
# FUNÇÃO: Instalar Flatpak
# ==============================================================================
install_flatpak() {
    local flatpak_id="$1"

    if [ -z "$flatpak_id" ]; then
        log "WARN" "ID do Flatpak não fornecido"
        return 1
    fi

    # Verifica se flatpak está instalado
    if ! command -v flatpak &>/dev/null; then
        log "INFO" "Flatpak não encontrado. Instalando..."

        case "$DISTRO_FAMILY" in
            debian|ubuntu|linuxmint|pop|neon|siduction|lingmo)
                $SUDO apt install -y flatpak
                ;;
            arch|manjaro|endeavouros|biglinux)
                $SUDO pacman -S --noconfirm flatpak
                ;;
            fedora|redhat|almalinux|nobara)
                $SUDO dnf install -y flatpak
                ;;
            *)
                log "ERROR" "Distribuição não suportada para Flatpak"
                return 1
                ;;
        esac
    fi

    # Instala o Flatpak
    log "INFO" "Instalando Flatpak: $flatpak_id"
    if $SUDO flatpak install -y flathub "$flatpak_id"; then
        log "SUCCESS" "✓ Flatpak instalado: $flatpak_id"
        return 0
    else
        log "ERROR" "Falha ao instalar Flatpak: $flatpak_id"
        return 1
    fi
}

# ==============================================================================
# FUNÇÃO: Configurar Flatpak Globalmente
# ==============================================================================
configure_flatpak_global() {
    log "INFO" "Configurando permissões padrão do Flatpak..."

    # Acesso a temas do sistema
    $SUDO flatpak override --filesystem=/usr/share/themes 2>/dev/null || true

    # Acesso a configurações GTK
    $SUDO flatpak override --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    $SUDO flatpak override --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true

    # Acesso a pastas de trabalho
    $SUDO flatpak override --filesystem=/mnt/trabalho 2>/dev/null || true

    # Acesso a scripts locais
    $SUDO flatpak override --filesystem=/usr/local 2>/dev/null || true

    # Permissões de bus (notificações e tray)
    $SUDO flatpak override --talk-name=org.kde.StatusNotifierWatcher 2>/dev/null || true
    $SUDO flatpak override --talk-name=org.freedesktop.Notifications 2>/dev/null || true
    $SUDO flatpak override --socket=system-bus 2>/dev/null || true
    $SUDO flatpak override --socket=session-bus 2>/dev/null || true

    log "SUCCESS" "✓ Overrides do Flatpak aplicados"
}

# ==============================================================================
# FUNÇÃO: Pós-Instalação de Filebot
# ==============================================================================
post_install_filebot() {
    log "INFO" "Verificando se Filebot está instalado..."

    # Testa se Filebot está instalado
    if ! flatpak list --app 2>/dev/null | grep -q "net.filebot.FileBot"; then
        log "WARN" "Filebot não está instalado, pulando pós-instalação"
        return 0
    fi

    log "INFO" "Configurando Filebot..."

    # 1. Aplicar licença (se existir)
    LICENSE_FILE="/usr/local/share/scripts/v3rtech-scripts/configs/FileBot_License_PX10290120.psm"

    if [ -f "$LICENSE_FILE" ]; then
        log "INFO" "Aplicando licença do Filebot..."
        cat "$LICENSE_FILE" | flatpak run net.filebot.FileBot --license
      else
        log "DEBUG" "Arquivo de licença não encontrado: $LICENSE_FILE"
    fi

    # 2. Configurar OpenSubtitles v2
    log "INFO" "Configurando OpenSubtitles v2..."
    if flatpak run net.filebot.FileBot -script fn:properties --def net.filebot.WebServices.OpenSubtitles.v2=true 2>/dev/null; then
        log "SUCCESS" "✓ OpenSubtitles v2 configurado"
    else
        log "WARN" "⚠ Falha ao configurar OpenSubtitles v2"
    fi

    # 3. Configurar credenciais OpenSubtitles (se fornecidas)
    # Lê credenciais do arquivo de configuração
    OSDB_CONFIG="/usr/local/share/scripts/v3rtech-scripts/configs/filebot-osdb.conf"

    if [ -f "$OSDB_CONFIG" ]; then
        log "INFO" "Lendo credenciais OpenSubtitles..."

        # Carrega arquivo de configuração (formato: OSDB_USER=... OSDB_PWD=...)
        source "$OSDB_CONFIG"

        if [ -n "$OSDB_USER" ] && [ -n "$OSDB_PWD" ]; then
            log "INFO" "Configurando credenciais OpenSubtitles..."
            if flatpak run net.filebot.FileBot -script fn:configure \
                --def osdbUser="$OSDB_USER" \
                --def osdbPwd="$OSDB_PWD" 2>/dev/null; then
                log "SUCCESS" "✓ Credenciais OpenSubtitles configuradas"
            else
                log "WARN" "⚠ Falha ao configurar credenciais OpenSubtitles"
            fi
        else
            log "DEBUG" "Credenciais OpenSubtitles não configuradas no arquivo"
        fi
    else
        log "DEBUG" "Arquivo de configuração não encontrado: $OSDB_CONFIG"
    fi

    log "SUCCESS" "✓ Filebot configurado com sucesso"
}

# ==============================================================================
# FUNÇÃO: Pós-Instalação de Whisper
# ==============================================================================
post_install_whisper() {
    log "INFO" "Verificando se Whisper está instalado..."

    # Testa se Whisper está instalado
    if ! command -v whisper &>/dev/null; then
        log "WARN" "Whisper não está instalado, pulando pós-instalação"
        return 0
    fi

    log "INFO" "Configurando Whisper..."

    # Detecta GPU
    local GPU=$(detect_gpu)
    log "INFO" "GPU detectada: $GPU"

    # Remove instalações anteriores
    log "INFO" "Removendo instalações anteriores do Whisper..."
    pipx uninstall whisper 2>/dev/null || true
    pipx uninstall openai-whisper 2>/dev/null || true
    rm -f "$HOME/.local/bin/whisper" 2>/dev/null || true

    # Reinstala com --force
    log "INFO" "Reinstalando openai-whisper com --force..."
    if pipx install openai-whisper --force 2>/dev/null; then
        log "SUCCESS" "✓ OpenAI Whisper reinstalado"
    else
        log "WARN" "⚠ Falha ao reinstalar OpenAI Whisper"
        return 1
    fi

    # Se NVIDIA: injeta dependências CUDA
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

    # Cria link simbólico em /usr/bin (se não existir)
    if [ ! -f /usr/bin/whisper ]; then
        log "INFO" "Criando link simbólico para whisper em /usr/bin..."
        if $SUDO ln -s "$HOME/.local/bin/whisper" /usr/bin/whisper 2>/dev/null; then
            log "SUCCESS" "✓ Link simbólico criado"
        else
            log "WARN" "⚠ Falha ao criar link simbólico"
        fi
    fi

    # Cria diretório de cache
    local MODELS_DIR="$HOME/.cache/whisper"
    if [ ! -d "$MODELS_DIR" ]; then
        log "INFO" "Criando diretório de cache para modelos do Whisper..."
        mkdir -p "$MODELS_DIR"
    fi

    log "SUCCESS" "✓ Whisper configurado com sucesso"
}

# --- 1. FUNÇÃO DE DEFINIÇÃO (Modo Lógico) ---
add_app() {
    local active="$1"
    local category="$2"
    local name="$3"
    local desc="$4"
    local pkg_deb="$5"
    local pkg_arch="$6"
    local pkg_fed="$7"
    local flatpak_id="$8"
    local method="$9"

    local native_pkg=""
    case "${DISTRO_FAMILY:-debian}" in
        debian|ubuntu|linuxmint|pop|neon|siduction|lingmo) native_pkg="$pkg_deb" ;;
        arch|manjaro|endeavouros|biglinux)                 native_pkg="$pkg_arch" ;;
        fedora|redhat|almalinux|nobara)                    native_pkg="$pkg_fed" ;;
        *)                                                 native_pkg="$pkg_deb" ;;
    esac

    APP_MAP_NATIVE["$name"]="$native_pkg"
    APP_MAP_FLATPAK["$name"]="$flatpak_id"
    APP_MAP_METHOD["$name"]="$method"
}

# --- 2. CARREGAMENTO DO BANCO DE DADOS ---
load_apps_database() {
    log "INFO" "Carregando lógica de instalação..."
    local db_path="${DATA_DIR:-data}/apps-data.sh"
    if [ ! -f "$db_path" ]; then db_path="lib/apps-data.sh"; fi

    if [ -f "$db_path" ]; then
        source "$db_path"
        log "SUCCESS" "Dados carregados."
    else
        log "ERROR" "Arquivo de dados não encontrado: $db_path"
        return 1
    fi
}

# --- 3. MOTOR DE INSTALAÇÃO ---
install_app_by_name() {
    local app_name="$1"
    local method="${APP_MAP_METHOD[$app_name]}"
    local pkg_native="${APP_MAP_NATIVE[$app_name]}"
    local pkg_flatpak="${APP_MAP_FLATPAK[$app_name]}"

    method=$(echo "$method" | xargs)
    log "STEP" "Instalando: $app_name (Método: $method)"

    case "$method" in
        pipx)
            if command -v install_pipx &>/dev/null; then install_pipx "${app_name,,}";
            elif command -v pipx &>/dev/null; then pipx install "${app_name,,}";
            else log "WARN" "Pipx ausente. Pulando $app_name"; fi
            ;;
        flatpak)
            [ -n "$pkg_flatpak" ] && install_flatpak "$pkg_flatpak"
            ;;
        custom)
            local script_path="/usr/local/bin/${pkg_native}"
            if command -v "$pkg_native" &>/dev/null; then "$pkg_native";
            elif [ -f "$script_path" ]; then "$script_path";
            else log "WARN" "Script customizado não encontrado: $pkg_native"; fi
            ;;
        native|*)
            local installed=false
            if [ -n "$pkg_native" ]; then
                # Verifica se 'i' é um alias ou função válida
                if type i &>/dev/null; then
                    log "INFO" "Instalando: $pkg_native"
                    # CORREÇÃO: Usar expansão sem aspas para que múltiplos pacotes sejam tratados corretamente
                    # Exemplo: "geany geany-plugins" é expandido para dois argumentos separados
                    if i $pkg_native; then installed=true; fi

                # Fallbacks manuais (caso o alias falhe ou não exista)
                elif command -v apt &>/dev/null; then $SUDO apt install -y $pkg_native && installed=true;
                elif command -v pacman &>/dev/null; then $SUDO pacman -S --noconfirm $pkg_native && installed=true;
                elif command -v dnf &>/dev/null; then $SUDO dnf install -y $pkg_native && installed=true;
                fi
            fi

            if [ "$installed" = false ] && [ -n "$pkg_flatpak" ]; then
                log "INFO" "Fallback para Flatpak..."
                install_flatpak "$pkg_flatpak"
            elif [ "$installed" = false ]; then
                log "ERROR" "Falha na instalação de $app_name"
            fi
            ;;
    esac
}

# --- 4. INTERFACE DE SELEÇÃO ---
select_and_install_apps() {
    log "INFO" "Iniciando seleção de aplicativos..."

    # Carrega banco de dados
    load_apps_database

    # Configura Flatpak globalmente (uma única vez)
    if command -v flatpak &>/dev/null; then
        configure_flatpak_global
    fi

    # Aqui você pode adicionar lógica para selecionar e instalar apps
    # Por exemplo, via YAD ou linha de comando
    log "INFO" "Aplicativos prontos para instalação"
}

# --- 5. FUNÇÃO DE PÓS-INSTALAÇÃO ---
post_install_apps() {
    log "INFO" "Executando pós-instalação..."

    # Configura Filebot se estiver instalado
    post_install_filebot

    # Configura Whisper se estiver instalado
    post_install_whisper

    log "SUCCESS" "✓ Pós-instalação concluída"
}

log "SUCCESS" "Motor de instalação carregado"
