#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/logic-apps-reader.sh
# Versão: 11.1.0 (Multi-Package Fix)
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
                    log "INFO" "Usando comando 'i' para instalar: $pkg_native"
                    # CORREÇÃO: Usar expansão sem aspas para que múltiplos pacotes sejam tratados corretamente
                    # Exemplo: "geany geany-plugins" é expandido para dois argumentos separados
                    if i $pkg_native; then installed=true; fi

                # Fallbacks manuais (caso o alias falhe ou não exista)
                elif command -v apt &>/dev/null; then sudo apt install -y $pkg_native && installed=true;
                elif command -v pacman &>/dev/null; then sudo pacman -S --noconfirm $pkg_native && installed=true;
                elif command -v dnf &>/dev/null; then sudo dnf install -y $pkg_native && installed=true;
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
