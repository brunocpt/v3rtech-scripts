#!/bin/bash

# wpchanger.sh - Um script para trocar periodicamente o papel de parede do desktop.
# Suporta: KDE, Gnome, Budgie, Elementary (Pantheon), Cinnamon, XFCE, MATE

# --- Variáveis Globais ---
CONFIG_DIR="$HOME/.config/wpchanger"
CONFIG_FILE="$CONFIG_DIR/config"
LOG_FILE="$CONFIG_DIR/wpchanger.log"
LAST_IMAGE_FILE="$CONFIG_DIR/last_image_index"

# --- Funções ---

# Função de log
log_message() {
    mkdir -p "$CONFIG_DIR"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Função para detectar o ambiente de desktop
get_desktop_environment() {
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]'
    elif [ -n "$DESKTOP_SESSION" ]; then
        echo "$DESKTOP_SESSION" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Função para converter opções de preenchimento para cada DE
convert_fill_option() {
    local fill_type="$1"
    local de="$2"

    case "$de" in
        *gnome*|*budgie*|*cinnamon*|*mate*)
            case "$fill_type" in
                "Zoom") echo "zoom" ;;
                "Escalonado") echo "scaled" ;;
                "Centralizado") echo "centered" ;;
                "Ladrilho") echo "wallpaper" ;;
                "Esticado") echo "stretched" ;;
                *) echo "zoom" ;;
            esac
            ;;
        *xfce*)
            case "$fill_type" in
                "Zoom") echo "5" ;;
                "Escalonado") echo "4" ;;
                "Centralizado") echo "1" ;;
                "Ladrilho") echo "2" ;;
                "Esticado") echo "3" ;;
                *) echo "5" ;;
            esac
            ;;
        *kde*)
            case "$fill_type" in
                "Zoom") echo "2" ;;
                "Escalonado") echo "1" ;;
                "Centralizado") echo "6" ;;
                "Ladrilho") echo "3" ;;
                "Esticado") echo "0" ;;
                *) echo "2" ;;
            esac
            ;;
        *)
            echo "zoom"
            ;;
    esac
}

# Função para definir o papel de parede
set_wallpaper() {
    local image_path="$1"
    local fill_type="$2"
    local de="$(get_desktop_environment)"
    local converted_fill="$(convert_fill_option "$fill_type" "$de")"

    log_message "Definindo papel de parede: $image_path com preenchimento $fill_type ($converted_fill) no ambiente $de"

    case "$de" in
        *gnome*|*budgie*)
            gsettings set org.gnome.desktop.background picture-options "$converted_fill"
            gsettings set org.gnome.desktop.background picture-uri "file://$image_path"
            ;;
        *cinnamon*)
            gsettings set org.cinnamon.desktop.background picture-options "$converted_fill"
            gsettings set org.cinnamon.desktop.background picture-uri "file://$image_path"
            ;;
        *mate*)
            gsettings set org.mate.background picture-options "$converted_fill"
            gsettings set org.mate.background picture-uri "file://$image_path"
            ;;
        *xfce*)
            # Para XFCE, precisa configurar para cada monitor/workspace
            for monitor in $(xfconf-query -c xfce4-desktop -l | grep -E "screen[0-9]+/monitor[^/]+/workspace[0-9]+/last-image$"); do
                xfconf-query -c xfce4-desktop -p "$monitor" -s "$image_path" 2>/dev/null
                style_prop="${monitor%/last-image}/image-style"
                xfconf-query -c xfce4-desktop -p "$style_prop" -s "$converted_fill" 2>/dev/null
            done
            ;;
        *kde*)
            dbus-send --session --dest=org.kde.plasmashell --type=method_call \
            /PlasmaShell org.kde.PlasmaShell.evaluateScript "string:
            var Desktops = desktops();
            for (i=0;i<Desktops.length;i++) {
                    d = Desktops[i];
                    d.wallpaperPlugin = \"org.kde.image\";
                    d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
                    d.writeConfig(\"Image\", \"file://$image_path\");
                    d.writeConfig(\"FillMode\", $converted_fill);
            }" >/dev/null 2>&1
            ;;
        *pantheon*)
            if command -v set-wallpaper &> /dev/null; then
                set-wallpaper "$image_path"
            else
                gsettings set org.gnome.desktop.background picture-options "$converted_fill"
                gsettings set org.gnome.desktop.background picture-uri "file://$image_path"
            fi
            ;;
        *)
            # Fallback para feh ou nitrogen
            if command -v feh &> /dev/null; then
                case "$fill_type" in
                    "Zoom") feh --bg-fill "$image_path" ;;
                    "Escalonado") feh --bg-scale "$image_path" ;;
                    "Centralizado") feh --bg-center "$image_path" ;;
                    "Ladrilho") feh --bg-tile "$image_path" ;;
                    "Esticado") feh --bg-stretch "$image_path" ;;
                    *) feh --bg-scale "$image_path" ;;
                esac
            elif command -v nitrogen &> /dev/null; then
                case "$fill_type" in
                    "Zoom") nitrogen --set-zoom-fill "$image_path" ;;
                    "Escalonado") nitrogen --set-scaled "$image_path" ;;
                    "Centralizado") nitrogen --set-centered "$image_path" ;;
                    "Ladrilho") nitrogen --set-tiled "$image_path" ;;
                    "Esticado") nitrogen --set-auto "$image_path" ;;
                    *) nitrogen --set-scaled "$image_path" ;;
                esac
            else
                log_message "Ambiente de desktop não suportado e nem feh nem nitrogen foram encontrados."
                return 1
            fi
            ;;
    esac

    return 0
}

# Função para trocar o papel de parede (usado pelo cron)
change_wallpaper() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_message "Erro: Arquivo de configuração não encontrado."
        exit 1
    fi

    source "$CONFIG_FILE"

    # Verifica se as pastas ainda existem
    if [ ! -d "$FOLDERS" ]; then
        log_message "Erro: Pasta de imagens não encontrada: $FOLDERS"
        exit 1
    fi

    # Encontra todas as imagens válidas
    IMAGE_LIST=()
    while IFS= read -r -d $'\0' file; do
        # Verifica se o arquivo realmente existe e é legível
        if [ -r "$file" ]; then
            IMAGE_LIST+=("$file")
        fi
    done < <(find "$FOLDERS" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.webp' \) -print0 2>/dev/null)

    if [ ${#IMAGE_LIST[@]} -eq 0 ]; then
        log_message "Erro: Nenhuma imagem válida encontrada em $FOLDERS"
        exit 1
    fi

    # Seleciona a imagem baseada na ordem configurada
    if [ "$ORDER" == "Aleatória" ]; then
        SELECTED_IMAGE="${IMAGE_LIST[RANDOM % ${#IMAGE_LIST[@]}]}"
    else
        # Ordem sequencial
        current_index=0
        if [ -f "$LAST_IMAGE_FILE" ]; then
            current_index=$(<"$LAST_IMAGE_FILE")
        fi
        current_index=$(( (current_index + 1) % ${#IMAGE_LIST[@]} ))
        SELECTED_IMAGE="${IMAGE_LIST[current_index]}"
        echo "$current_index" > "$LAST_IMAGE_FILE"
    fi

    # Define o papel de parede
    if set_wallpaper "$SELECTED_IMAGE" "$FILL_TYPE"; then
        log_message "Papel de parede alterado com sucesso: $(basename "$SELECTED_IMAGE")"
    else
        log_message "Erro ao definir papel de parede: $SELECTED_IMAGE"
        exit 1
    fi
}

# Função para configurar o agendamento via systemd
setup_systemd_timer() {
    local interval=$1
    local script_path=$(realpath "$0")
    local user_systemd_dir="$HOME/.config/systemd/user"

    # Cria o diretório do systemd do usuário se não existir
    mkdir -p "$user_systemd_dir"

    # Remove timers antigos
    systemctl --user stop wpchanger.timer 2>/dev/null || true
    systemctl --user disable wpchanger.timer 2>/dev/null || true
    systemctl --user stop wpchanger-startup.service 2>/dev/null || true
    systemctl --user disable wpchanger-startup.service 2>/dev/null || true

    # Remove arquivos antigos
    rm -f "$user_systemd_dir/wpchanger.service" "$user_systemd_dir/wpchanger.timer" "$user_systemd_dir/wpchanger-startup.service"

    # Cria o arquivo de serviço
    cat > "$user_systemd_dir/wpchanger.service" << EOL
[Unit]
Description=Wallpaper Changer Service
After=graphical-session.target

[Service]
Type=oneshot
Environment=DISPLAY=:0
ExecStart=$script_path --change
EOL

    if [ "$interval" -gt 0 ]; then
        # Cria o arquivo de timer para troca periódica
        cat > "$user_systemd_dir/wpchanger.timer" << EOL
[Unit]
Description=Wallpaper Changer Timer
Requires=wpchanger.service

[Timer]
OnCalendar=*:0/${interval}
Persistent=true

[Install]
WantedBy=timers.target
EOL

        # Recarrega e ativa o timer
        systemctl --user daemon-reload
        systemctl --user enable wpchanger.timer
        systemctl --user start wpchanger.timer

        log_message "Timer systemd configurado para cada $interval minutos."
    else
        log_message "Troca automática desativada (intervalo = 0)."
    fi

    # Configura inicialização com o sistema se solicitado
    if [ "$STARTUP_OPT" == "TRUE" ]; then
        cat > "$user_systemd_dir/wpchanger-startup.service" << EOL
[Unit]
Description=Wallpaper Changer at Startup
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=oneshot
Environment=DISPLAY=:0
ExecStartPre=/bin/sleep 30
ExecStart=$script_path --change
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOL

        systemctl --user daemon-reload
        systemctl --user enable wpchanger-startup.service

        log_message "Configurado para executar na inicialização do sistema via systemd."
    fi

    # Recarrega o daemon do systemd
    systemctl --user daemon-reload
}

# Função para instalar dependências
install_dependencies() {
    local gui_tool=""

    # Verifica se YAD está disponível
    if command -v yad &> /dev/null; then
        gui_tool="yad"
    elif command -v zenity &> /dev/null; then
        gui_tool="zenity"
    else
        log_message "Tentando instalar YAD..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y yad
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm yad
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y yad
        else
            log_message "Gerenciador de pacotes não suportado. Instale 'yad' ou 'zenity' manualmente."
            exit 1
        fi

        if command -v yad &> /dev/null; then
            gui_tool="yad"
        else
            log_message "Falha ao instalar YAD."
            exit 1
        fi
    fi

    echo "$gui_tool"
}

# Função para exibir janela de configuração
show_config_window() {
    local gui_tool="$1"

    if [ "$gui_tool" == "yad" ]; then
        yad --title="Configurador de Papel de Parede" \
            --form \
            --field="Pastas de Imagens:MDIR" "" \
            --field="Trocar ao iniciar:CHK" FALSE \
            --field="Ordem:CB" "Aleatória!Sequencial" \
            --field="Preenchimento:CB" "Zoom!Escalonado!Centralizado!Ladrilho!Esticado" \
            --field="Intervalo de troca (minutos; 0=não trocar):NUM" "15!0..1440!1" \
            --button="OK:0" --button="Cancelar:1" \
            --width=500 --height=300
    else
        # Fallback para zenity (implementação básica)
        zenity --forms --title="Configurador de Papel de Parede" \
            --text="Configure as opções do papel de parede:" \
            --add-entry="Pasta de Imagens" \
            --add-combo="Ordem" --combo-values="Aleatória|Sequencial" \
            --add-combo="Preenchimento" --combo-values="Zoom|Escalonado|Centralizado|Ladrilho|Esticado" \
            --add-entry="Intervalo (minutos, 0=não trocar)"
    fi
}

# --- Lógica Principal ---

# Verifica se está sendo executado em modo de troca automática
if [ "$1" == "--change" ]; then
    change_wallpaper
    exit 0
fi

log_message "Script iniciado em modo interativo."

# Instala dependências se necessário
GUI_TOOL=$(install_dependencies)
log_message "Usando ferramenta GUI: $GUI_TOOL"

# Exibe a janela de configuração
CONFIG=$(show_config_window "$GUI_TOOL")

# Verifica se o usuário cancelou
if [ $? -ne 0 ]; then
    log_message "Usuário cancelou a configuração."
    exit 0
fi

# Processa a configuração baseada na ferramenta usada
if [ "$GUI_TOOL" == "yad" ]; then
    IFS='|' read -r FOLDERS STARTUP_OPT ORDER FILL_TYPE INTERVAL <<<"$CONFIG"
else
    # Para zenity, o formato é diferente
    IFS='|' read -r FOLDERS ORDER FILL_TYPE INTERVAL <<<"$CONFIG"
    STARTUP_OPT="FALSE"  # zenity não suporta checkbox facilmente
fi

# Validações
if [ -z "$FOLDERS" ]; then
    if [ "$GUI_TOOL" == "yad" ]; then
        yad --title="Erro" --text="Nenhuma pasta de imagem foi selecionada." --timeout=10
    else
        zenity --error --text="Nenhuma pasta de imagem foi selecionada." --timeout=10
    fi
    log_message "Erro: Nenhuma pasta de imagem selecionada."
    exit 1
fi

if [ ! -d "$FOLDERS" ]; then
    if [ "$GUI_TOOL" == "yad" ]; then
        yad --title="Erro" --text="A pasta selecionada não existe: $FOLDERS" --timeout=10
    else
        zenity --error --text="A pasta selecionada não existe: $FOLDERS" --timeout=10
    fi
    log_message "Erro: Pasta não existe: $FOLDERS"
    exit 1
fi

# Verifica se há imagens na pasta
IMAGE_COUNT=$(find "$FOLDERS" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.webp' \) | wc -l)
if [ "$IMAGE_COUNT" -eq 0 ]; then
    if [ "$GUI_TOOL" == "yad" ]; then
        yad --title="Erro" --text="Nenhuma imagem válida encontrada na pasta selecionada." --timeout=10
    else
        zenity --error --text="Nenhuma imagem válida encontrada na pasta selecionada." --timeout=10
    fi
    log_message "Erro: Nenhuma imagem encontrada em $FOLDERS"
    exit 1
fi

# Salva a configuração
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" << EOL
FOLDERS="$FOLDERS"
STARTUP_OPT="$STARTUP_OPT"
ORDER="$ORDER"
FILL_TYPE="$FILL_TYPE"
INTERVAL="$INTERVAL"
EOL

log_message "Configuração salva: Pasta=$FOLDERS, Iniciar=$STARTUP_OPT, Ordem=$ORDER, Preenchimento=$FILL_TYPE, Intervalo=$INTERVAL"

# Configura o agendamento
setup_systemd_timer "$INTERVAL"

# Troca o papel de parede imediatamente
if change_wallpaper; then
    SUCCESS_MSG="Configuração salva e papel de parede alterado com sucesso!\n\nConfiguração:\n• Pasta: $FOLDERS\n• $IMAGE_COUNT imagens encontradas\n• Ordem: $ORDER\n• Preenchimento: $FILL_TYPE\n• Intervalo: $INTERVAL minutos\n• Iniciar com sistema: $STARTUP_OPT\n\nA janela fechará em 10 segundos."

    if [ "$GUI_TOOL" == "yad" ]; then
        yad --title="Sucesso" --text="$SUCCESS_MSG" --timeout=10 --width=400
    else
        zenity --info --text="$SUCCESS_MSG" --timeout=10
    fi

    log_message "Script finalizado com sucesso."
else
    ERROR_MSG="Configuração salva, mas houve erro ao definir o papel de parede.\nVerifique o log em: $LOG_FILE"

    if [ "$GUI_TOOL" == "yad" ]; then
        yad --title="Aviso" --text="$ERROR_MSG" --timeout=10
    else
        zenity --warning --text="$ERROR_MSG" --timeout=10
    fi

    log_message "Script finalizado com erro na definição do papel de parede."
    exit 1
fi

exit 0

