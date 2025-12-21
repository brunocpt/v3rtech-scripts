#!/bin/bash
# Script para instalar vários apps através de Flatpak, com seleção de conjuntos de pacotes pelo usuário

# Título e descrição
TITLE="Instalador de Meta Flatpaks"
TEXT="Selecione os conjuntos de pacotes que deseja instalar:"

# Interface com YAD
SELECIONADOS=$(yad --title="$TITLE" \
  --form --separator=";" \
  --width=400 --height=330 \
  --center \
  --text="$TEXT" \
  --field="Selecionar todos:CHK" \
  --field="Internet - Pacotes de internet:CHK" \
  --field="Office - Pacotes de escritório:CHK" \
  --field="Multimídia - Áudio, vídeo e imagem:CHK" \
  --field="Games - Jogos em Flatpak:CHK" \
  --field="Devs - Aplicativos para desenvolvedores:CHK" \
  --field="System - Aplicativos para o sistema:CHK" \
)

# Cancela se o usuário fechar
[ $? -ne 0 ] && exit 1

IFS=";" read -r todos internet office multimidia games devs devops system <<< "$SELECIONADOS"

# Se "Selecionar todos" estiver ativo, força todas as opções para "TRUE"
if [[ "$todos" == "TRUE" ]]; then
  internet="TRUE"
  office="TRUE"
  multimidia="TRUE"
  games="TRUE"
  devs="TRUE"
  system="TRUE"
fi

# Lista de scripts e caminhos (sem .sh nos scripts de /Geral)
declare -A SCRIPT_PATHS=(
  [internet]="/usr/local/share/scripts/v3rtech-scripts/utils/fpk-internet.sh"
  [office]="/usr/local/share/scripts/v3rtech-scripts/utils/fpk-office.sh"
  [multimidia]="/usr/local/share/scripts/v3rtech-scripts/utils/fpk-multimidia.sh"
  [games]="/usr/local/share/scripts/v3rtech-scripts/utils/fpk-games.sh"
  [devs]="/usr/local/share/scripts/v3rtech-scripts/utils/fpk-devs.sh"
  [system]="/usr/local/share/scripts/v3rtech-scripts/utils/fpk-system.sh"
)

# Comandos a executar
COMANDOS=()
for key in "${!SCRIPT_PATHS[@]}"; do
  if [[ "${!key}" == "TRUE" ]]; then
    COMANDOS+=("echo '▶ Executando: ${SCRIPT_PATHS[$key]}'")
    COMANDOS+=("[ -x \"${SCRIPT_PATHS[$key]}\" ] && \"${SCRIPT_PATHS[$key]}\" || echo '❌ Script não encontrado ou sem permissão: ${SCRIPT_PATHS[$key]}'")
  fi
done

# Garante que há comandos a executar
if [ ${#COMANDOS[@]} -eq 0 ]; then
  yad --error --text="Nenhum pacote selecionado para instalação." --center
  exit 1
fi

# Salva os comandos em um script temporário
SCRIPT_TEMP=$(mktemp)
{
  echo "#!/bin/bash"
  echo "echo '===== Início da instalação dos Meta Flatpaks ====='"
  for cmd in "${COMANDOS[@]}"; do
    echo "$cmd"
  done

  echo "echo '===== Criando atalhos para aplicativos Flatpak instalados...'"
  echo "[ -x /usr/local/share/scripts/v3rtech-scripts/utils/fpk-gera-atalhos.sh ] && /usr/local/share/scripts/v3rtech-scripts/utils/fpk-gera-atalhos.sh || echo 'Script de geração de atalhos não encontrado ou sem permissão.'"

  echo "echo '===== Removendo atalhos órfãos de aplicativos Flatpak desinstalados...'"
  echo "[ -x /usr/local/share/scripts/v3rtech-scripts/utils/fpk-limpa-atalhos-orfãos.sh ] && /usr/local/share/scripts/v3rtech-scripts/utils/fpk-limpa-atalhos-orfãos.sh || echo 'Script de limpeza de atalhos órfãos não encontrado ou sem permissão.'"

  echo "echo '===== Instalação concluída. Fechando em 10 segundos...'"
  echo "sleep 10"
} > "$SCRIPT_TEMP"

chmod +x "$SCRIPT_TEMP"

# Executa os scripts selecionados em um terminal gráfico compatível
if command -v konsole &> /dev/null; then
  konsole --new-tab -e bash "$SCRIPT_TEMP"
elif command -v xfce4-terminal &> /dev/null; then
  xfce4-terminal --hide-menubar --title="Instalação de Meta Flatpaks" --command="bash $SCRIPT_TEMP"
elif command -v gnome-terminal &> /dev/null; then
  gnome-terminal --title="Instalação de Meta Flatpaks" -- bash "$SCRIPT_TEMP"
elif command -v gnome-console &> /dev/null; then
  gnome-console --title="Instalação de Meta Flatpaks" -- bash "$SCRIPT_TEMP"
elif command -v pantheon-terminal &> /dev/null; then
  pantheon-terminal --title="Instalação de Meta Flatpaks" -- bash "$SCRIPT_TEMP"
elif command -v terminator &> /dev/null; then
  terminator -e bash "$SCRIPT_TEMP"
elif command -v tilda &> /dev/null; then
  tilda -e bash "$SCRIPT_TEMP"
elif command -v tilix &> /dev/null; then
  tilix -e bash "$SCRIPT_TEMP"
elif command -v guake &> /dev/null; then
  guake -e bash "$SCRIPT_TEMP"
elif command -v cosmic-term &> /dev/null; then
  cosmic-term -e bash "$SCRIPT_TEMP"
elif command -v xterm &> /dev/null; then
  xterm -title "Instalação de Meta Flatpaks" -e bash "$SCRIPT_TEMP"
else
  yad --error --title="Erro" --text="Nenhum terminal compatível encontrado.\nInstale Konsole, GNOME Terminal, Xfce4-terminal, Tilix ou XTerm."
  exit 1
fi
