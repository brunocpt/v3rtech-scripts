#!/usr/bin/env bash

# ======================================
# GERADOR DE ATALHOS FLATPAK COM LOGS
# ======================================

set -e

VERDE=$(tput setaf 2)
VERMELHO=$(tput setaf 1)
AZUL=$(tput setaf 4)
RESET=$(tput sgr0)

# Verifica se flatpak está instalado
if ! command -v flatpak &>/dev/null; then
  echo "Flatpak não está instalado no sistema."
  exit 1
fi

# Verifica sudo
if ! sudo -n true 2>/dev/null; then
  echo "Será solicitada a senha do sudo para criar os atalhos em /usr/local/bin..."
fi

# Lista aplicativos Flatpak
echo "Listando aplicativos Flatpak instalados..."
mapfile -t app_ids < <(flatpak list --app --columns=application)

if [[ ${#app_ids[@]} -eq 0 ]]; then
  echo "Nenhum aplicativo Flatpak foi encontrado. Abortando."
  exit 1
fi

echo "${#app_ids[@]} aplicativo(s) encontrados."

# Criação de atalhos
for appid in "${app_ids[@]}"; do
  [[ -z "$appid" ]] && continue

  # Extrai nome amigável
  shortname=$(echo "$appid" | awk -F '.' '{print tolower($NF)}')
  destino="/usr/local/bin/$shortname"

  echo "Criando atalho para: $appid → $destino"

  script_content=$(cat <<EOF
#!/usr/bin/env bash
flatpak run $appid "\$@"
EOF
)

  # Criação com logs
  if echo "$script_content" | sudo tee "$destino" >/dev/null; then
    sudo chmod +x "$destino"
    echo "Atalho criado com sucesso: $shortname"
  else
    echo "Falha ao criar atalho para $appid"
  fi
done

echo "Todos os atalhos foram processados!"

