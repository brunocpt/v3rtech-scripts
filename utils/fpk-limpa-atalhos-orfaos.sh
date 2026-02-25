#!/usr/bin/env bash
# ==============================================================================
# Script: fpk-limpa-atalhos-orfaos.sh
# Versão: 4.0.5
# Data: 2026-02-24
# Objetivo: Limpeza de atalhos em /usr/local/bin de apps Flatpak desinstalados
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

set -e

VERDE=$(tput setaf 2)
AMARELO=$(tput setaf 3)
VERMELHO=$(tput setaf 1)
RESET=$(tput sgr0)
ATALHOHOME="/usr/local/bin"

# Lista de app IDs instalados
mapfile -t FLATPAKS < <(flatpak list --app --columns=application)

# Varre os atalhos
for file in $ATALHOHOME/*; do
  [[ ! -x "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  # Procura linhas com flatpak run
  appid=$(grep -Eo 'flatpak run [a-zA-Z0-9._-]+' "$file" 2>/dev/null | awk '{print $3}' | head -n1)

  if [[ -n "$appid" ]]; then
    if printf "%s\n" "${FLATPAKS[@]}" | grep -Fxq "$appid"; then
      echo "Mantido: $(basename "$file") (appid ainda instalado)"
    else
      sudo rm -f "$file"
      echo "Removido atalho órfão: $(basename "$file") (appid: $appid)"
    fi
  fi
done

echo "Limpeza concluída."

