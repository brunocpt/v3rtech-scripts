#!/bin/bash

# Verifica se o yt-dlp está disponível
if ! command -v yt-dlp &> /dev/null; then
    yad --error --text="yt-dlp não está instalado. Instale com:\nsudo apt install yt-dlp\nou\npip install yt-dlp" --timeout=5 --button=OK:0
    exit 1
fi

# Verifica se o yad está disponível
if ! command -v yad &> /dev/null; then
    zenity --error --text="yad não está instalado. Instale com:\nsudo apt install yad" --timeout=5
    exit 1
fi

# Caminhos e arquivos padrão
PASTA_PADRAO="/mnt/trabalho/Downloads/Musicas"
LOG_FILE="${HOME}/ytmp3.log"
echo "Log de downloads iniciado em $(date)" > "$LOG_FILE"

# Função para baixar uma playlist
baixar_playlist() {
    local playlist_url="$1"
    local pasta_destino="$2"

    yt-dlp --ignore-errors --format bestaudio --extract-audio --audio-format mp3 --audio-quality 192K \
           --output "${pasta_destino}/%(playlist_title)s/%(playlist_index)02d %(title)s [%(artist)s].%(ext)s" \
           --yes-playlist "$playlist_url" --download-archive "${pasta_destino}/downloaded_files.txt" >> "$LOG_FILE" 2>&1
}

# Solicita as URLs
playlist_urls=$(yad --text-info --editable --width=700 --height=400 \
    --title="URLs das Playlists" \
    --text="Insira cada URL de playlist em uma nova linha.\nExemplo:\nhttps://youtube.com/playlist1\nhttps://youtube.com/playlist2")

if [[ -z "$playlist_urls" ]]; then
    yad --error --text="Nenhuma URL fornecida. Encerrando." --timeout=5 --button=OK:0
    exit 1
fi

# Seleciona a pasta de destino
pasta_destino=$(yad --file --directory --title="Selecione a pasta de destino" \
    --text="Escolha a pasta onde as playlists serão salvas.\nDeixe em branco para usar a pasta padrão:\n$PASTA_PADRAO")

if [[ -z "$pasta_destino" ]]; then
    pasta_destino="$PASTA_PADRAO"
fi

mkdir -p "$pasta_destino" || {
    yad --error --text="Erro ao criar a pasta de destino. Verifique permissões." --timeout=5 --button=OK:0
    exit 1
}

# Inicia os downloads em um grupo de processos isolado
(
    (
        IFS=$'\n' read -rd '' -a urls <<< "$playlist_urls"
        for url in "${urls[@]}"; do
            echo "Iniciando download: $url" >> "$LOG_FILE"
            baixar_playlist "$url" "$pasta_destino"
            echo "Finalizado: $url" >> "$LOG_FILE"
        done
        # Adiciona um marcador de fim para que a janela de progresso feche
        echo "##DOWNLOAD_COMPLETED##" >> "$LOG_FILE"
    ) &
    wait
) &
download_pid=$!
pgid=$(ps -o pgid= "$download_pid" | grep -o '[0-9]*')

# Inicia a barra de progresso em uma subshell para matar os processos filho
(
    tail -n 0 -f "$LOG_FILE" | while read -r line; do
        if [[ "$line" == *"[ExtractAudio] Destination:"* ]]; then
            filename=$(basename "$line" | sed 's/ (.*)//' | sed 's/\[.*\]//')
            song_name=$(echo "$filename" | sed 's/\.mp3$//' | sed 's/^[0-9]\+ - //')
            echo "#Baixando: $song_name"
        elif [[ "$line" == *'##DOWNLOAD_COMPLETED##'* ]]; then
            break # Encerra o loop e a janela do yad
        fi
        echo " "
    done
) | yad --progress --pulsate \
    --title="Baixando playlists..." \
    --text="Download em andamento. Aguarde..." \
    --width=500 --height=100 &
yad_pid=$!

# Aguarda a conclusão do processo de download
wait $download_pid
download_status=$?

# Encerra o yad caso ele ainda esteja rodando
kill -TERM "$yad_pid" 2>/dev/null

# Exibe a mensagem de sucesso ou falha com a configuração de botão correta
if [[ $download_status -eq 0 ]]; then
    yad --info --text="Download concluído com sucesso!" --timeout=5 --button=OK:0
else
    # Se o download falhou ou foi cancelado, encerra o grupo de processos principal
    kill -TERM -"$pgid" 2>/dev/null
    yad --warning --text="Download cancelado pelo usuário." --timeout=5 --button=OK:0
fi

