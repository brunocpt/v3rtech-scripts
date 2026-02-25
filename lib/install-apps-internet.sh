#!/bin/bash
# ==============================================================================
# Script: lib/install-apps-internet.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalar aplicativos de Internet (navegadores, nuvem, comunicação)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Carrega dependências
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$BASE_DIR/core/env.sh" || { echo "[ERRO] Não foi possível carregar core/env.sh"; exit 1; }
source "$BASE_DIR/core/logging.sh" || { echo "[ERRO] Não foi possível carregar core/logging.sh"; exit 1; }
source "$BASE_DIR/core/package-mgr.sh" || { echo "[ERRO] Não foi possível carregar core/package-mgr.sh"; exit 1; }
source "$BASE_DIR/lib/apps-data.sh" || { echo "[ERRO] Não foi possível carregar lib/apps-data.sh"; exit 1; }

# Carrega configuração
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# ==============================================================================
# VALIDAÇÃO INICIAL
# ==============================================================================
if [ -z "$DISTRO_FAMILY" ]; then
    log "INFO" "Detectando sistema..."
    source "$BASE_DIR/lib/detect-system.sh" || die "Falha ao detectar sistema"
fi

# ==============================================================================
# GPU COMPOSITING FIX (PARA NVIDIA E WEBCAM EM APPS CHROMIUM)
# ==============================================================================

# Lista de nomes de pacotes (ou parte deles) que são baseados em Chromium
# O nome deve corresponder ao pacote nativo ou ao nome do arquivo .desktop
CHROMIUM_APPS_GPU_FIX=("wavebox" "google-chrome" "microsoft-edge" "brave" "vivaldi" "opera")

# Função para aplicar a flag --disable-gpu-compositing em arquivos .desktop
apply_gpu_fix() {
    local app_name="$1"
    log "INFO" "Procurando arquivo .desktop para '$app_name' para aplicar o fix da GPU..."

    # Encontra o caminho do arquivo .desktop em locais comuns
    local desktop_file_path
    desktop_file_path=$(find /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications -iname "*${app_name}*.desktop" -print -quit)

    if [ -z "$desktop_file_path" ]; then
        log "WARN" "Não foi possível encontrar o arquivo .desktop para '$app_name'. O fix da GPU não será aplicado."
        return 1
    fi

    log "INFO" "Arquivo .desktop encontrado: $desktop_file_path"

    # Verifica se o fix já foi aplicado para não duplicar
    if grep -q -- "--disable-gpu-compositing" "$desktop_file_path"; then
        log "INFO" "O fix da GPU já está aplicado em '$desktop_file_path'."
        return 0
    fi

    log "STEP" "Aplicando o fix '--disable-gpu-compositing' em '$desktop_file_path'..."

    # Adiciona a flag a todas as linhas que começam com Exec=
    # Usamos um delimitador diferente (pipe) para o sed por causa das barras no path
    sudo sed -i 's|^Exec=\(.*\)|Exec=\1 --disable-gpu-compositing|g' "$desktop_file_path"

    if [ $? -eq 0 ]; then
        log "SUCCESS" "Fix da GPU aplicado com sucesso para '$app_name'."
        # Atualiza o banco de dados de desktops para que a mudança tenha efeito imediato
        update-desktop-database &>/dev/null || true
    else
        log "ERROR" "Falha ao aplicar o fix da GPU para '$app_name'."
        return 1
    fi
}

# Função para criar um hook que reaplica o fix após atualizações
create_update_hook() {
    local app_name="$1"
    local package_name="${APP_MAP_NATIVE[$app_name]:-$app_name}" # Usa o nome do pacote se disponível

    case "$DISTRO_FAMILY" in
        arch)
            log "INFO" "Criando hook do pacman para '$package_name'..."
            local hook_dir="/etc/pacman.d/hooks"
            local hook_file="$hook_dir/v3rtech-gpu-fix-${package_name}.hook"
            sudo mkdir -p "$hook_dir"

            # Cria o hook para ser acionado na instalação/atualização do pacote
            echo "[Trigger]" | sudo tee "$hook_file"
            echo "Operation = Install" | sudo tee -a "$hook_file"
            echo "Operation = Upgrade" | sudo tee -a "$hook_file"
            echo "Type = Package" | sudo tee -a "$hook_file"
            echo "Target = $package_name" | sudo tee -a "$hook_file"
            echo "" | sudo tee -a "$hook_file"
            echo "[Action]" | sudo tee -a "$hook_file"
            echo "Description = Re-applying GPU compositing fix for $app_name..." | sudo tee -a "$hook_file"
            echo "When = PostTransaction" | sudo tee -a "$hook_file"
            # O caminho para o script principal deve ser absoluto
            echo "Exec = $TARGET_DIR/lib/install-apps-internet.sh --apply-fix $app_name" | sudo tee -a "$hook_file"
            log "SUCCESS" "Hook do pacman criado em '$hook_file'."
            ;;
        debian)
            log "INFO" "Criando hook do dpkg/apt para '$app_name'..."
            local hook_dir="/etc/apt/apt.conf.d"
            local hook_file="$hook_dir/99v3rtech-gpu-fix"
            sudo mkdir -p "$hook_dir"

            # Adiciona um hook Post-Invoke que roda nosso script
            # Nota: Este hook roda após QUALQUER operação do apt.
            # O script precisa ser inteligente para aplicar o fix somente quando necessário.
            if ! grep -q "v3rtech-gpu-fix.sh" "$hook_file" 2>/dev/null; then
                echo "DPkg::Post-Invoke { \"/usr/local/bin/v3rtech-gpu-fix.sh\"; };" | sudo tee "$hook_file"
                
                # Cria o script que será chamado pelo hook
                local fix_script="/usr/local/bin/v3rtech-gpu-fix.sh"
                echo "#!/bin/bash" | sudo tee "$fix_script"
                echo "# Script para reaplicar fixes da V3RTECH" | sudo tee -a "$fix_script"
                echo "source \"$TARGET_DIR/core/env.sh\"" | sudo tee -a "$fix_script"
                echo "source \"$TARGET_DIR/core/logging.sh\"" | sudo tee -a "$fix_script"
                echo "log 'INFO' 'Hook do APT acionado. Verificando necessidade de aplicar fixes...'" | sudo tee -a "$fix_script"
                # Chama o script de internet com a flag para aplicar o fix em todos os apps da lista
                echo "bash \"$TARGET_DIR/lib/install-apps-internet.sh\" --apply-fix-all" | sudo tee -a "$fix_script"
                sudo chmod +x "$fix_script"
                log "SUCCESS" "Hook do APT criado. O script /usr/local/bin/v3rtech-gpu-fix.sh será executado após transações."
            else
                log "INFO" "Hook do APT já configurado."
            fi
            ;;
        *)
            log "WARN" "Criação de hook não suportada para a família de distros '$DISTRO_FAMILY'. O fix não será reaplicado automaticamente após atualizações."
            ;;
    esac
}

# Função principal que orquestra o fix e a criação do hook
apply_gpu_fix_and_create_hook() {
    local app_name="$1"
    apply_gpu_fix "$app_name"
    create_update_hook "$app_name"
}

# ==============================================================================
# PROCESSAMENTO DE ARGUMENTOS (PARA HOOKS)
# ==============================================================================

if [[ "$1" == "--apply-fix" && -n "$2" ]]; then
    apply_gpu_fix "$2"
    exit 0
fi

if [[ "$1" == "--apply-fix-all" ]]; then
    for app in "${CHROMIUM_APPS_GPU_FIX[@]}"; do
        # Verifica se o app está instalado antes de tentar aplicar o fix
        if command -v "$app" &>/dev/null || grep -q "$app" "$CONFIG_HOME/selected-apps.conf" 2>/dev/null; then
             apply_gpu_fix "$app"
        fi
    done
    exit 0
fi

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# ==============================================================================
install_native_app() {
    local app_name="$1"
    local package="${APP_MAP_NATIVE[$app_name]}"
    if [ -z "$package" ]; then
        log "WARN" "Pacote nativo não disponível para $app_name em $DISTRO_FAMILY"
        return 1
    fi
    log "INFO" "Instalando $app_name (nativo)..."
    i "$package"
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"
    else
        log "WARN" "Falha ao instalar $app_name"
        return 1
    fi
}

install_flatpak_app() {
    local app_name="$1"
    local flatpak_id="${APP_MAP_FLATPAK[$app_name]}"
    if [ -z "$flatpak_id" ]; then
        log "WARN" "Flatpak ID não disponível para $app_name"
        return 1
    fi
    log "INFO" "Instalando $app_name (Flatpak)..."
    install_flatpak "$flatpak_id"
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"
    else
        log "WARN" "Falha ao instalar $app_name"
        return 1
    fi
}

install_app() {
    local app_name="$1"
    local app_method="${APP_MAP_METHOD[$app_name]}"
    local prefer_native="${PREFER_NATIVE:-false}"
    local install_success=0

    if [ "$app_method" = "flatpak" ]; then
        install_flatpak_app "$app_name"
        install_success=$?
    elif [ "$app_method" = "pipx" ] || [ "$app_method" = "custom" ]; then
        log "DEBUG" "$app_name será tratado por outro script (método: $app_method)"
        return 0  # Não é um erro, apenas não será instalado aqui
    else
        if [ "$prefer_native" = "true" ]; then
            install_native_app "$app_name"
            install_success=$?
            if [ $install_success -ne 0 ]; then
                install_flatpak_app "$app_name"
                install_success=$?
            fi
        else
            install_flatpak_app "$app_name"
            install_success=$?
            if [ $install_success -ne 0 ]; then
                install_native_app "$app_name"
                install_success=$?
            fi
        fi
    fi

    # Se a instalação foi bem-sucedida, verifica se precisa do fix da GPU
    if [ $install_success -eq 0 ]; then
        log "SUCCESS" "$app_name instalado com sucesso"

        # >>> INÍCIO DA MODIFICAÇÃO <<<
        # Itera na lista de apps que precisam do fix
        for chromium_app in "${CHROMIUM_APPS_GPU_FIX[@]}"; do
            if [ "$app_name" == "$chromium_app" ]; then
                apply_gpu_fix_and_create_hook "$app_name"
                break  # Sai do loop assim que encontrar
            fi
        done
        # >>> FIM DA MODIFICAÇÃO <<<

        return 0
    else
        log "WARN" "Falha ao instalar $app_name"
        return 1
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================
section "Instalação de Aplicativos de Internet"

SELECTED_APPS_FILE="$CONFIG_HOME/selected-apps.conf"
if [ ! -f "$SELECTED_APPS_FILE" ]; then
    log "WARN" "Arquivo de seleção não encontrado. Nenhum app de Internet será instalado."
    exit 0
fi

# Carrega o arquivo de configuração para ter acesso às variáveis SELECTED_APP_*
source "$SELECTED_APPS_FILE"

log "STEP" "Instalando aplicativos de Internet selecionados..."

installed_count=0
for i in "${!APP_NAMES_ORDERED[@]}"; do
    app_name="${APP_NAMES_ORDERED[$i]}"
    category="${APP_MAP_CATEGORY[$app_name]}"
    
    if [ "$category" = "Internet" ] || [ "$category" = "Nuvem" ] || [ "$category" = "Comunicação" ]; then
        var_name="SELECTED_APP_$i"
        if declare -p "$var_name" &>/dev/null && [ "${!var_name}" = "true" ]; then
            log "DEBUG" "App '$app_name' selecionado para instalação"
            install_app "$app_name"
            ((installed_count++))
        fi
    fi
done

if [ $installed_count -eq 0 ]; then
    log "INFO" "Nenhum aplicativo de Internet foi selecionado para instalação."
else
    log "SUCCESS" "Instalação de $installed_count aplicativo(s) de Internet concluída!"
fi

# ==============================================================================
# VARREDURA FINAL: APLICAR FIX DE GPU EM TODOS OS APPS CHROMIUM ENCONTRADOS
# ==============================================================================
# Esta seção executa APÓS todas as instalações, independentemente do resultado
# Detecta todos os apps Chromium no sistema (nativos e flatpaks) e aplica o fix

log ""
log "STEP" "Detectando e corrigindo apps Chromium instalados no sistema..."

local_fixed_count=0
local_already_fixed_count=0
local_not_found_count=0
local_flatpak_hook_created=false

for chromium_app in "${CHROMIUM_APPS_GPU_FIX[@]}"; do
    log "INFO" "Verificando $chromium_app..."

    # Procura pelo arquivo .desktop em todos os locais possíveis
    desktop_file=$(find /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications -iname "*${chromium_app}*.desktop" -print -quit 2>/dev/null || true)

    if [ -z "$desktop_file" ]; then
        log "DEBUG" "$chromium_app não encontrado no sistema."
        ((local_not_found_count++))
        continue
    fi

    log "DEBUG" "Arquivo .desktop encontrado: $desktop_file"

    # Verifica se o fix já foi aplicado
    if grep -q -- "--disable-gpu-compositing" "$desktop_file"; then
        log "INFO" "Fix de GPU já está aplicado para $chromium_app."
        ((local_already_fixed_count++))
        continue
    fi

    # Aplica o fix em TODAS as linhas Exec= (não apenas a primeira)
    log "STEP" "Aplicando fix --disable-gpu-compositing em $desktop_file..."
    sudo sed -i '/^Exec=.*--disable-gpu-compositing/!s|^Exec=\(.*\)$|Exec=\1 --disable-gpu-compositing|' "$desktop_file"

    if [ $? -eq 0 ]; then
        log "SUCCESS" "Fix de GPU aplicado com sucesso para $chromium_app."
        update-desktop-database &>/dev/null || true
        ((local_fixed_count++))

        # Determina se é nativo ou flatpak baseado no caminho
        if [[ "$desktop_file" == *"flatpak"* ]]; then
            # Cria hook para Flatpak (systemd timer)
            if [ "$local_flatpak_hook_created" = false ]; then
                log "INFO" "Criando hook de atualização para Flatpaks via systemd..."
                local service_file="/etc/systemd/system/v3rtech-gpu-fix.service"
                local timer_file="/etc/systemd/system/v3rtech-gpu-fix.timer"

                if [ ! -f "$service_file" ] || [ ! -f "$timer_file" ]; then
                    sudo tee "$service_file" > /dev/null << SERVICE_EOF
[Unit]
Description=V3RTECH GPU Fix - Re-apply for Chromium apps
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $TARGET_DIR/lib/install-apps-internet.sh --apply-fix-all
SERVICE_EOF

                    sudo tee "$timer_file" > /dev/null << TIMER_EOF
[Unit]
Description=Run V3RTECH GPU fix daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
TIMER_EOF

                    sudo systemctl daemon-reload
                    sudo systemctl enable --now v3rtech-gpu-fix.timer
                    log "SUCCESS" "Hook para Flatpak (systemd timer) ativado."
                    local_flatpak_hook_created=true
                fi
            fi
        else
            # Cria hook para pacote nativo
            package_name="${APP_MAP_NATIVE[$chromium_app]:-$chromium_app}"
            
            case "$DISTRO_FAMILY" in
                arch)
                    hook_dir="/etc/pacman.d/hooks"
                    hook_file="$hook_dir/v3rtech-gpu-fix-${package_name}.hook"
                    
                    if [ ! -f "$hook_file" ]; then
                        log "INFO" "Criando hook do pacman para $package_name..."
                        sudo mkdir -p "$hook_dir"
                        
                        sudo tee "$hook_file" > /dev/null << HOOK_EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = $package_name

[Action]
Description = Re-applying V3RTECH GPU compositing fix for $chromium_app...
When = PostTransaction
Exec = /bin/bash $TARGET_DIR/lib/install-apps-internet.sh --apply-fix $chromium_app
HOOK_EOF
                        sudo chmod 644 "$hook_file"
                        log "SUCCESS" "Hook do pacman criado em $hook_file."
                    fi
                    ;;
                debian)
                    hook_file="/etc/apt/apt.conf.d/99v3rtech-gpu-fix"
                    fix_script="/usr/local/bin/v3rtech-gpu-fix.sh"
                    
                    if [ ! -f "$hook_file" ]; then
                        log "INFO" "Criando hook do dpkg/apt para $chromium_app..."
                        echo "DPkg::Post-Invoke { \"$fix_script\"; };" | sudo tee "$hook_file" > /dev/null
                        
                        sudo tee "$fix_script" > /dev/null << FIX_SCRIPT_EOF
#!/bin/bash
if [ -d "$TARGET_DIR" ]; then
    /bin/bash "$TARGET_DIR/lib/install-apps-internet.sh" --apply-fix-all
fi
FIX_SCRIPT_EOF
                        sudo chmod +x "$fix_script"
                        log "SUCCESS" "Hook do APT criado."
                    fi
                    ;;
                fedora)
                    hook_dir="/etc/dnf/plugins/post_transaction_actions.d"
                    hook_file="$hook_dir/v3rtech-gpu-fix.action"
                    
                    if [ ! -f "$hook_file" ]; then
                        log "INFO" "Criando hook do DNF para $chromium_app..."
                        sudo mkdir -p "$hook_dir"
                        echo "*:* /bin/bash $TARGET_DIR/lib/install-apps-internet.sh --apply-fix-all" | sudo tee "$hook_file" > /dev/null
                        sudo chmod 644 "$hook_file"
                        log "SUCCESS" "Hook do DNF criado."
                    fi
                    ;;
            esac
        fi
    else
        log "ERROR" "Falha ao aplicar o fix de GPU para $chromium_app."
    fi
done

log "SUCCESS" "Varredura de apps Chromium concluída!"
log "INFO" "Resumo: $local_fixed_count corrigidos, $local_already_fixed_count já estavam corrigidos, $local_not_found_count não encontrados."
