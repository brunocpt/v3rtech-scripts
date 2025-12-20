#!/usr/bin/env bash
# Universal batch image resizer
# Requisitos: imagemagick instalado (convert, mogrify)
# Uso: ./resize-images.sh <PASTA> <LARGURA> <ALTURA>
# Se não fornecer argumentos, será solicitado interativamente

set -euo pipefail

# ----- Checa dependências -----
if ! command -v mogrify &>/dev/null; then
    echo "Erro: imagemagick (mogrify) não está instalado. Instale com:"
    echo "  sudo apt install imagemagick   # Debian/Ubuntu"
    echo "  sudo pacman -S imagemagick     # Arch"
    echo "  sudo dnf install imagemagick   # Fedora"
    echo "  sudo zypper install imagemagick # openSUSE"
    exit 1
fi

# ----- Ajuda e argumentos -----
show_help() {
    echo
    echo "Uso: $0 <PASTA> <LARGURA> <ALTURA>"
    echo "Redimensiona todas as imagens JPG e PNG em <PASTA> para as dimensões dadas (mantém proporção)."
    echo "Se não fornecer argumentos, o script pedirá os dados."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

FOLDER="${1:-}"
WIDTH="${2:-}"
HEIGHT="${3:-}"

if [[ -z "$FOLDER" || -z "$WIDTH" || -z "$HEIGHT" ]]; then
    echo
    echo "==> Este script altera o tamanho de todas as imagens em uma pasta."
    echo "==> Requer 3 argumentos: <PASTA> <LARGURA> <ALTURA>"
    read -rp "Qual a pasta onde estão as imagens? " FOLDER
    read -rp "Qual a largura máxima desejada (px)? " WIDTH
    read -rp "Qual a altura máxima desejada (px)? " HEIGHT
fi

# Checa existência da pasta
if [[ ! -d "$FOLDER" ]]; then
    echo "Erro: Pasta '$FOLDER' não existe."
    exit 1
fi

cd "$FOLDER"

# Pergunta antes de deletar arquivos
echo
echo "ATENÇÃO: As imagens PNG originais serão convertidas em JPG, e as JPG redimensionadas. Os arquivos originais serão sobrescritos!"
read -rp "Pressione 'C' para cancelar ou qualquer outra tecla para continuar... " resposta
if [[ "${resposta^^}" == "C" ]]; then
    echo "Cancelado."
    exit 0
fi

echo 'Convertendo arquivos PNG para JPG...'
if compgen -G "*.png" > /dev/null; then
    mogrify -format jpg ./*.png
fi

echo 'Redimensionando imagens JPG (isso pode demorar)...'
if compgen -G "*.jpg" > /dev/null; then
    mogrify -resize "${WIDTH}x${HEIGHT}>" ./*.jpg
fi

echo 'Excluindo arquivos PNG originais...'
rm -f ./*.png

echo
echo "Processo finalizado. Todas as JPG redimensionadas estão em '$FOLDER'."

# DICA: para preservar originais, trabalhe em uma pasta cópia!

