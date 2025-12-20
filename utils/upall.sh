#!/bin/bash
# ============================================================================
#
#          FILE: upall
#
#         USAGE: ./upall
#
#   DESCRIPTION: Script para atualização completa do sistema (pacotes nativos,
#                Flatpak, Snap, Pipx) usando YAD para a interface gráfica.
#
#       OPTIONS: ---
#  REQUIREMENTS: yad, sudo
#          BUGS: ---
#         NOTES: Refatorado para usar YAD e uma única janela de progresso.
#        AUTHOR: Gemini
#      REVISION: 3.0
#
# ============================================================================

# Variáveis globais
LOG_FILE="$HOME/system-update.log"
UPDATE_CMD=""
ID=""
YAD_FIFO="/tmp/yad_fifo_$$"

# Flags para controlar o que será atualizado
DO_SYSTEM_UPDATE=false
DO_FLATPAK_UPDATE=false
DO_SNAP_UPDATE=false
DO_PIPX_UPDATE=false

# Função de limpeza executada ao sair
cleanup() {
    rm -f "$YAD_FIFO"
}
trap cleanup EXIT

# Detecta a distribuição Linux
get_distro() {
    if [ -f /etc/os-release ]; then
        ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
        case $ID in
            arch) UPDATE_CMD="sudo rm -f /var/lib/pacman/db.lck ; yay -Syu --noconfirm ; sudo paccache -r -k3 ; sudo pacman -Rns --noconfirm $(pacman -Qtdq 2>/dev/null)" ;;
            ubuntu|debian|elementary|neon|pop) UPDATE_CMD="sudo DEBIAN_FRONTEND=noninteractive apt update ; sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y ; sudo apt autoremove -y ; sudo apt clean" ;;
            fedora) UPDATE_CMD="sudo dnf upgrade --refresh -y ; sudo dnf autoremove -y ; sudo dnf clean all" ;;
            opensuse*) UPDATE_CMD="sudo zypper refresh && sudo zypper update -y" ;;
            *)
                yad --error --title="Erro" --text="Distribuição '$ID' não suportada."
                exit 1
                ;;
        esac
    else
        yad --error --title="Erro" --text="Não foi possível determinar a distribuição. O arquivo /etc/os-release não existe."
        exit 1
    fi
}

# Permite ao usuário selecionar quais componentes atualizar, com timeout
select_components() {
    local yad_options=()
    local selections_string=""

    # Prepara as opções com base nos pacotes instalados
    yad_options+=(TRUE "Pacotes do Sistema")
    command -v flatpak &> /dev/null && yad_options+=(TRUE "Flatpak")
    command -v snap &> /dev/null && yad_options+=(TRUE "Snap")
    command -v pipx &> /dev/null && yad_options+=(TRUE "Pipx")

    # Exibe a janela de seleção com timeout
    selections_string=$(yad --list --checklist \
        --title="Seleção de Componentes" \
        --text="<big><b>Escolha o que deseja atualizar</b></big>\n\nO processo iniciará automaticamente em 10 segundos com as opções marcadas." \
        --width=400 --height=300 \
        --column="Atualizar:" --column="Componente" \
        "${yad_options[@]}" \
        --button="Iniciar Atualização:0" --button="Cancelar:1" \
        --timeout=10)

    local exit_code=$?

    # Se o usuário cancelou (1) ou fechou a janela (252)
    if [[ $exit_code -eq 1 || $exit_code -eq 252 ]]; then
        return 1
    fi

    # Se o tempo esgotou (70) ou o usuário clicou em OK (0),
    # o script continua. Se o tempo esgotou, $selections_string estará vazio,
    # então processamos as opções padrão.
    if [[ $exit_code -eq 70 ]]; then
        # Timeout: usa as opções padrão (todas marcadas)
        selections_string=$(printf "%s\n" "${yad_options[@]}" | grep "TRUE" -A 1 | grep -v "TRUE" | tr '\n' '|')
    fi

    # Define as flags globais com base na seleção
    echo "$selections_string" | grep -q "Pacotes do Sistema" && DO_SYSTEM_UPDATE=true
    echo "$selections_string" | grep -q "Flatpak" && DO_FLATPAK_UPDATE=true
    echo "$selections_string" | grep -q "Snap" && DO_SNAP_UPDATE=true
    echo "$selections_string" | grep -q "Pipx" && DO_PIPX_UPDATE=true

    # Verifica se nada foi selecionado
    if ! $DO_SYSTEM_UPDATE && ! $DO_FLATPAK_UPDATE && ! $DO_SNAP_UPDATE && ! $DO_PIPX_UPDATE; then
        yad --info --text="Nenhum componente foi selecionado para atualização."
        return 1
    fi

    return 0
}

# A função principal que executa todas as atualizações selecionadas
run_all_updates() {
    # Redireciona toda a saída deste bloco para o log. O pipe principal cuidará do YAD.
    exec > >(tee -a "$LOG_FILE") 2>&1

    echo "============================================================"
    echo " INÍCIO DA ATUALIZAÇÃO DO SISTEMA - $(date)"
    echo "============================================================"; echo ""

    if $DO_SYSTEM_UPDATE; then
        echo "--- ATUALIZANDO PACOTES DO SISTEMA ($ID) ---"; eval "$UPDATE_CMD"; echo ""
    fi

    if $DO_FLATPAK_UPDATE; then
        echo "--- ATUALIZANDO PACOTES FLATPAK ---"; sudo flatpak repair; sudo flatpak update -y; sudo flatpak uninstall --unused -y
        echo "Limpando cache do Flatpak..."; sudo rm -rfv /var/tmp/flatpak-cache-*; echo ""
    elif command -v flatpak &> /dev/null; then echo "--- Atualização de Flatpak pulada pelo usuário. ---"; echo ""; fi

    if $DO_SNAP_UPDATE; then
        echo "--- ATUALIZANDO PACOTES SNAP ---"; sudo snap refresh; echo ""
    elif command -v snap &> /dev/null; then echo "--- Atualização de Snap pulada pelo usuário. ---"; echo ""; fi

    if $DO_PIPX_UPDATE; then
        echo "--- ATUALIZANDO PACOTES PIPX ---"
        if command -v python3 &> /dev/null; then echo "Verificando atualização do próprio pipx..."; python3 -m pip install --upgrade pipx; fi
        pipx upgrade-all; echo ""
    elif command -v pipx &> /dev/null; then echo "--- Atualização de Pipx pulada pelo usuário. ---"; echo ""; fi

    if $DO_SYSTEM_UPDATE; then
        echo "--- REALIZANDO LIMPEZA PÓS-ATUALIZAÇÃO ---"
        case $ID in
            arch) sudo pacman -Scc --noconfirm ;;
            ubuntu|debian|elementary|neon|pop) sudo apt autoremove -y && sudo apt clean ;;
            fedora) sudo dnf clean all ;;
            opensuse*) sudo zypper clean --all ;;
        esac
        echo "Limpando logs antigos do journal..."; sudo journalctl --vacuum-time=2weeks
    fi

    echo ""; echo "============================================================"
    echo " ATUALIZAÇÃO CONCLUÍDA - $(date)"; echo "============================================================"
}

# Exibe um resumo final do que foi feito
show_summary() {
    local summary_text="<big><b>Atualização Concluída!</b></big>\n\n<b>Resumo das ações executadas:</b>\n"

    $DO_SYSTEM_UPDATE && summary_text+="- Pacotes do sistema atualizados e limpeza realizada.\n"
    $DO_FLATPAK_UPDATE && summary_text+="- Pacotes Flatpak atualizados e limpos.\n"
    $DO_SNAP_UPDATE && summary_text+="- Pacotes Snap atualizados.\n"
    $DO_PIPX_UPDATE && summary_text+="- Pacotes Pipx atualizados.\n"

    summary_text+="\nUm log detalhado foi salvo em:\n<b>$LOG_FILE</b>"

    yad --info --title="Resumo da Atualização" --width=500 \
        --image=dialog-ok-apply \
        --text="$summary_text" \
        --timeout=10 \
        --button="Ok!:0"
}

# --- Execução Principal ---

get_distro
> "$LOG_FILE" # Limpa o log antigo

# Permite ao usuário selecionar os componentes e sai se ele cancelar
select_components || {
    yad --info --title="Atualização Cancelada" --image=dialog-cancel --text="A atualização foi cancelada pelo usuário."
    exit 0
}

# Cria um FIFO (named pipe) para comunicação com o YAD
mkfifo "$YAD_FIFO"

# Inicia a janela de progresso em background, lendo do FIFO
yad --title="Atualização do Sistema em Andamento" \
    --text-info --tail --width=800 --height=600 \
    --button="Cancelar:1" < "$YAD_FIFO" &
YAD_PID=$!

# Executa as atualizações e envia a saída para o FIFO.
# O `tee` é usado para duplicar a saída para o arquivo de log.
# Tudo é executado em um subshell (&) para que o script principal possa continuar.
( run_all_updates | tee -a "$LOG_FILE" > "$YAD_FIFO" ) &
UPDATE_PID=$!

# Aguarda a conclusão do processo de atualização
wait $UPDATE_PID

# Mata a janela do YAD de progresso, pois a tarefa terminou
kill $YAD_PID 2>/dev/null

# Exibe o resumo final
show_summary

exit 0

