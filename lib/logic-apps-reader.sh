#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/logic-apps-reader.sh
# Versão: 1.0.0
#
# Descrição: Lê o arquivo data/apps.csv e processa as informações.
# Gera arrays para a interface gráfica e para a lógica de instalação.
#
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

CSV_FILE="$DATA_DIR/apps.csv"

# Arrays globais para armazenar os dados carregados
declare -a APP_LIST_YAD=()    # Formato para o YAD (TRUE, Internet, Chrome...)
declare -A APP_MAP_NATIVE     # Mapeia Nome -> Pacote Nativo (Baseado na Distro)
declare -A APP_MAP_FLATPAK    # Mapeia Nome -> ID Flatpak
declare -A APP_MAP_METHOD     # Mapeia Nome -> Método (native, flatpak, pipx)

# Função para carregar e processar o CSV
load_apps_csv() {
    log "INFO" "Lendo banco de dados de aplicativos: $CSV_FILE"

    if [ ! -f "$CSV_FILE" ]; then
        die "Arquivo de dados $CSV_FILE não encontrado."
    fi

    local line_count=0

    # Lê linha por linha
    while IFS='|' read -r active category name desc pkg_deb pkg_arch pkg_fed flatpak_id method || [ -n "$active" ]; do

        # Ignora linhas de comentário (#) ou linhas vazias
        [[ "$active" =~ ^#.*$ ]] && continue
        [[ -z "$active" ]] && continue

        # Limpa espaços em branco extras (trim)
        name=$(echo "$name" | xargs)
        method=$(echo "$method" | xargs)

        # 1. Determina o nome do pacote nativo baseado na distro detectada
        local native_pkg=""
        case "$DISTRO_FAMILY" in
            debian) native_pkg="$pkg_deb" ;;
            arch)   native_pkg="$pkg_arch" ;;
            fedora) native_pkg="$pkg_fed" ;;
        esac

        # 2. Popula os Arrays Associativos (Mapas)
        # Usamos o NOME como chave única
        APP_MAP_NATIVE["$name"]="$native_pkg"
        APP_MAP_FLATPAK["$name"]="$flatpak_id"
        APP_MAP_METHOD["$name"]="$method"

        # 3. Prepara a linha para o YAD (UI)
        # O formato do YAD checkbox list é: BOOL "Categoria" "Nome" "Descrição"
        # Adicionamos ao array linear
        APP_LIST_YAD+=("$active" "$category" "$name" "$desc")

        ((line_count++))

    done < "$CSV_FILE"

    log "SUCCESS" "Carregados $line_count aplicativos do banco de dados."
}

# Função Auxiliar: Instala um app pelo NOME (chave do CSV)
install_app_by_name() {
    local app_name="$1"
    local method="${APP_MAP_METHOD[$app_name]}"
    local pkg_native="${APP_MAP_NATIVE[$app_name]}"
    local pkg_flatpak="${APP_MAP_FLATPAK[$app_name]}"

    log "STEP" "Processando: $app_name (Método: $method)"

    case "$method" in
        pipx)
            # Instalação Python Isolada
            install_pipx "${app_name,,}" # converte nome para minúsculo como fallback de nome de pacote
            ;;

        flatpak)
            # Força Flatpak (ex: Filebot)
            if [ -n "$pkg_flatpak" ]; then
                install_flatpak "$pkg_flatpak"
            else
                log "ERROR" "App $app_name configurado como Flatpak, mas sem ID no CSV."
            fi
            ;;

        native|*)
            # Tenta Nativo -> Fallback Flatpak
            local installed=false

            # 1. Tenta Nativo se houver pacote definido para a distro
            if [ -n "$pkg_native" ]; then
                if i "$pkg_native"; then
                    installed=true
                else
                    log "WARN" "Falha na instalação nativa de $app_name. Tentando fallback..."
                fi
            fi

            # 2. Fallback para Flatpak se nativo falhou ou não existe
            if [ "$installed" = false ] && [ -n "$pkg_flatpak" ]; then
                log "INFO" "Usando Flatpak como fallback para $app_name."
                install_flatpak "$pkg_flatpak"
            elif [ "$installed" = false ]; then
                log "ERROR" "Não foi possível instalar $app_name (Sem nativo válido e sem ID Flatpak)."
            fi
            ;;
    esac
}
