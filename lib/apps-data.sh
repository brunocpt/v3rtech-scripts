#!/bin/bash
# ==============================================================================
# Script: lib/apps-data.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Banco de dados centralizado de aplicativos para instalação
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================
#
# Este arquivo contém a definição de todos os aplicativos disponíveis para
# instalação, com suporte a múltiplas distribuições e métodos de instalação.
#
# Usa arrays associativos para armazenar dados de forma robusta.
#
# ==============================================================================

# Habilita expand_aliases para que o comando 'i' funcione
shopt -s expand_aliases

# Arrays Globais para armazenar dados dos apps
declare -A APP_MAP_NATIVE
declare -A APP_MAP_FLATPAK
declare -A APP_MAP_METHOD
declare -A APP_MAP_CATEGORY
declare -A APP_MAP_ACTIVE
declare -A APP_MAP_DESC
declare -a APP_NAMES_ORDERED

# Arrays indexados para compatibilidade com scripts antigos
declare -a APPS_NOME
declare -a APPS_DESCRICAO
declare -a APPS_PKG_DEB
declare -a APPS_PKG_ARCH
declare -a APPS_PKG_FED
declare -a APPS_FLATPAK
declare -a APPS_METODO
declare -a APPS_CATEGORIA
declare -a APPS_ATIVO

# ==============================================================================
# FUNÇÃO: Adicionar um app ao banco de dados
# ==============================================================================

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

    # Determina o pacote nativo baseado na distribuição
    local native_pkg=""
    case "${DISTRO_FAMILY:-debian}" in
        debian|ubuntu|linuxmint|pop|neon|siduction|lingmo) native_pkg="$pkg_deb" ;;
        arch|manjaro|endeavouros|biglinux)                 native_pkg="$pkg_arch" ;;
        fedora|redhat|almalinux|nobara)                    native_pkg="$pkg_fed" ;;
        *)                                                 native_pkg="$pkg_deb" ;;
    esac

    # Armazena em arrays associativos
    APP_MAP_NATIVE["$name"]="$native_pkg"
    APP_MAP_FLATPAK["$name"]="$flatpak_id"
    APP_MAP_METHOD["$name"]="$method"
    APP_MAP_CATEGORY["$name"]="$category"
    APP_MAP_ACTIVE["$name"]="$active"
    APP_MAP_DESC["$name"]="$desc"
    
    # Mantém ordem dos apps
    APP_NAMES_ORDERED+=("$name")

    # Popula arrays indexados para compatibilidade
    APPS_NOME+=("$name")
    APPS_DESCRICAO+=("$desc")
    APPS_PKG_DEB+=("$pkg_deb")
    APPS_PKG_ARCH+=("$pkg_arch")
    APPS_PKG_FED+=("$pkg_fed")
    APPS_FLATPAK+=("$flatpak_id")
    APPS_METODO+=("$method")
    APPS_CATEGORIA+=("$category")
    APPS_ATIVO+=("$active")
}

# --- NAVEGADORES ---
add_app "TRUE" "Internet" "Google Chrome" "Navegador do Google" "google-chrome-stable" "google-chrome" "google-chrome-stable" "com.google.Chrome" "native"
add_app "TRUE" "Internet" "Firefox" "Navegador Mozilla" "firefox" "firefox" "firefox" "org.mozilla.firefox" "native"
add_app "TRUE" "Internet" "Brave" "Navegador Privacidade" "brave-browser" "brave-bin" "brave-browser" "com.brave.Browser" "native"
add_app "TRUE" "Internet" "Zen Browser" "Navegador zen com foco em privacidade e desempenho" "" "zen-browser-bin" "" "app.zen_browser.zen" "native"
add_app "FALSE" "Internet" "Vivaldi" "Navegador Power User" "vivaldi-stable" "vivaldi" "vivaldi" "com.vivaldi.Vivaldi" "native"
add_app "FALSE" "Internet" "Opera" "Navegador com VPN" "" "opera" "" "com.opera.Opera" "native"
add_app "FALSE" "Internet" "Microsoft Edge" "Navegador Microsoft" "microsoft-edge-stable" "microsoft-edge-stable-bin" "microsoft-edge-stable" "com.microsoft.Edge" "native"
add_app "FALSE" "Internet" "BrowserOS" "The Open source agentic browser" "" "browseros-bin" "" "" "native"
add_app "TRUE" "Internet" "Wavebox" "Navegador focado em trabalho" "wavebox" "wavebox" "wavebox" "" "native"
add_app "FALSE" "Internet" "Discord" "Chat e Voz" "discord" "discord" "discord" "com.discordapp.Discord" "flatpak"
add_app "FALSE" "Internet" "MailViewer" "Visualizador EML/MSG" "" "" "" "io.github.alescdb.mailviewer" "flatpak"

# --- NUVEM E TRANSFERÊNCIA ---
add_app "TRUE" "Nuvem" "Nextcloud" "Sync Nextcloud" "nextcloud-desktop" "nextcloud-client" "nextcloud-client" "com.nextcloud.desktopclient.nextcloud" "native"
add_app "FALSE" "Nuvem" "Packet" "Simple, fast file sharing between Linux and Android" "" "" "" "io.github.nozwock.Packet" "flatpak"
add_app "FALSE" "Nuvem" "SendWorm" "Ferramenta segura e fácil de usar para transferir arquivos rapidamente" "" "" "" "to.bnt.sendworm" "flatpak"
add_app "FALSE" "Nuvem" "Filezilla" "Cliente FTP" "filezilla" "filezilla" "filezilla" "org.filezilla.FileZilla" "native"
add_app "FALSE" "Nuvem" "SendAnywhere" "Compartilhamento de arquivos em tempo real" "sendanywhere" "sendanywhere" "sendanywhere" "" "native"
add_app "TRUE" "Nuvem" "LocalSend" "Compartilhamento de arquivos em tempo real" "" "localsend-bin" "" "org.localsend.localsend_app" "native"

# --- DESENVOLVIMENTO & TERMINAL ---
add_app "TRUE" "Dev" "Antigravity" "Ambiente Google (VSCode)" "antigravity" "antigravity" "antigravity" "" "native"
add_app "TRUE" "Dev" "Docker" "Containers" "docker.io docker-compose" "docker docker-compose" "docker docker-compose-plugin" "" "native"
add_app "TRUE" "Dev" "Guake" "Terminal Drop-down" "guake" "guake" "guake" "" "native"
add_app "TRUE" "Dev" "Geany" "Editor Leve" "geany geany-plugins" "geany geany-plugins" "geany geany-plugins" "" "native"
add_app "TRUE" "Dev" "Git Tools" "Git e GitHub CLI" "git gh" "git github-cli" "git gh" "" "native"
add_app "TRUE" "Dev" "Dev Utils" "JQ, CCache, Duf, Eza" "jq ccache duf eza" "jq ccache duf eza" "jq ccache duf eza" "" "native"
add_app "FALSE" "Dev" "DBeaver" "Cliente SQL" "dbeaver-ce" "dbeaver" "dbeaver" "io.dbeaver.DBeaverCommunity" "native"
add_app "FALSE" "Dev" "Postman" "Plataforma API" "postman" "postman-bin" "postman" "com.getpostman.Postman" "native"
add_app "FALSE" "Dev" "Terminator" "Terminal Avançado" "terminator" "terminator" "terminator" "" "native"
add_app "TRUE" "Dev" "VS Code" "Editor Microsoft" "code" "visual-studio-code-bin" "code" "com.visualstudio.code" "native"

# --- ESCRITÓRIO E PRODUTIVIDADE ---
add_app "TRUE" "Escritório" "LibreOffice" "Suíte Office" "libreoffice libreoffice-l10n-pt-br" "libreoffice-fresh libreoffice-fresh-pt-br" "libreoffice libreoffice-langpack-pt-BR" "org.libreoffice.LibreOffice" "native"
add_app "FALSE" "Escritório" "Obsidian" "Knowledge Base" "" "obsidian" "obsidian" "md.obsidian.Obsidian" "native"
add_app "FALSE" "Escritório" "Calibre" "E-books" "calibre" "calibre" "calibre" "com.calibre_ebook.calibre" "flatpak"
add_app "TRUE" "Escritório" "Zotero" "Gestão Bibliográfica" "" "zotero-bin" "zotero" "org.zotero.Zotero" "flatpak"
add_app "TRUE" "Escritório" "XMind" "Mapas Mentais" "" "xmind" "xmind" "net.xmind.XMind8" "flatpak"
add_app "TRUE" "Escritório" "Camunda Modeler" "Modelagem BPMN" "" "camunda-modeler" "camunda-modeler" "" "native"
add_app "TRUE" "Escritório" "Draw.io" "Diagramas" "drawio" "drawio-desktop" "drawio" "com.jgraph.drawio.desktop" "native"
add_app "TRUE" "Escritório" "Corretores PT-BR" "Dicionários" "aspell-pt-br hunspell-pt-br mythes-pt-br hyphen-pt-br wportuguese" "aspell-pt hunspell-pt-br hyphen-pt_pt" "aspell-pt hunspell-pt mythes-pt hyphen-pt" "" "native"
add_app "FALSE" "Escritório" "PDF Adobe Reader" "Leitor de PDF Adobe Reader" "" "" "" "com.adobe.Reader" "flatpak"

# --- PDF E OCR ---
add_app "TRUE" "Escritório" "Sejda PDF" "Editor PDF Desktop" "" "sejda-desktop" "sejda-desktop" "com.sejda.Sejda" "native"
add_app "TRUE" "Escritório" "Tesseract OCR" "Motor OCR" "python3-fpdf python3-uharfbuzz jbig2enc python3-pydantic ghostscript jbig2dec tesseract-ocr tesseract-ocr-por tesseract-ocr-eng ocrmypdf" "python-fpdf2 python-uharfbuzz jbig2enc python-pydantic ghostscript jbig2dec tesseract tesseract-data-por tesseract-data-eng ocrmypdf" "python3-fpdf python3-uharfbuzz jbig2enc python3-pydantic ghostscript jbig2dec tesseract tesseract-langpack-por ocrmypdf" "" "native"
add_app "FALSE" "Escritório" "gImageReader" "Front-end to tesseract-ocr" "gimagereader" "gimagereader-qt" "gimagereader" "io.github.manisandro.gImageReader" "native"
add_app "FALSE" "Escritório" "OCRFeeder" "A aplicação completa de OCR" "" "" "" "org.gnome.OCRFeeder" "flatpak"
add_app "FALSE" "Escritório" "TextSnatcher" "Snatch Text with just a Drag" "" "" "" "com.github.rajsolai.textsnatcher" "flatpak"

# --- DESIGN & IMAGEM ---
add_app "TRUE" "Design" "Inkscape" "Vetorial" "inkscape" "inkscape" "inkscape" "org.inkscape.Inkscape" "native"
add_app "TRUE" "Design" "GIMP" "Imagens" "gimp" "gimp" "gimp" "org.gimp.GIMP" "native"
add_app "FALSE" "Design" "Upscayl" "Upscaling IA" "" "upscayl-bin" "upscayl" "org.upscayl.Upscayl" "native"
add_app "FALSE" "Design" "Penpot" "Prototipagem" "" "" "" "com.authormore.penpotdesktop" "flatpak"
add_app "FALSE" "Design" "FreeCAD" "Modelagem 3D" "freecad" "freecad" "freecad" "org.freecad.FreeCAD" "native"
add_app "FALSE" "Design" "Scribus" "Desktop Publishing" "scribus" "scribus" "scribus" "net.scribus.Scribus" "native"
add_app "FALSE" "Design" "WebP Converter" "Conversor WebP" "" "" "" "io.itsterminal.WebPConverter" "flatpak"
add_app "TRUE" "Design" "ImageMagick" "Manipulação CLI" "imagemagick" "imagemagick" "imagemagick" "" "native"

# --- MULTIMÍDIA ---
add_app "TRUE" "Multimídia" "VLC" "Player" "vlc" "vlc vlc-plugins-all" "vlc" "org.videolan.VLC" "native"
add_app "TRUE" "Multimídia" "OBS Studio" "Streaming" "obs-studio" "obs-studio" "obs-studio" "com.obsproject.Studio" "native"
add_app "FALSE" "Multimídia" "Spotify" "Música" "spotify-client" "spotify" "spotify-client" "com.spotify.Client" "flatpak"
add_app "TRUE" "Multimídia" "Filebot" "Organizador" "" "" "" "net.filebot.FileBot" "flatpak"
add_app "FALSE" "Multimídia" "MuseAmp" "Player estilo Winamp" "" "" "" "io.github.tapscodes.MuseAmp" "flatpak"
add_app "TRUE" "Multimídia" "MusicBrainz Picard" "Tagger de Música" "picard libchromaprint-tools mp3gain ffmpeg" "picard chromaprint ffmpeg mp3gain puddletag" "picard chromaprint-tools mp3gain ffmpeg" "org.musicbrainz.Picard" "native"
add_app "FALSE" "Multimídia" "Avidemux" "Editor de Vídeo" "avidemux" "avidemux-qt" "avidemux" "org.avidemux.Avidemux" "native"
add_app "TRUE" "Multimídia" "MKVToolNix" "Ferramentas MKV" "mkvtoolnix" "mkvtoolnix-cli mkvtoolnix-gui" "mkvtoolnix" "org.bunkus.mkvtoolnix-gui" "native"
add_app "TRUE" "Multimídia" "YT-DLP" "Downloader de Vídeos" "yt-dlp" "yt-dlp" "yt-dlp" "yt-dlp" "native"

# --- JOGOS ---
add_app "FALSE" "Jogos" "Steam" "Loja de Jogos" "steam" "steam" "steam" "com.valvesoftware.Steam" "native"
add_app "FALSE" "Jogos" "Bottles" "Wine Manager" "" "" "" "com.usebottles.bottles" "flatpak"
add_app "FALSE" "Jogos" "Extreme Tux Racer" "Corrida" "extremetuxracer" "extremetuxracer" "extremetuxracer" "" "native"
add_app "FALSE" "Jogos" "SuperTuxKart" "Kart" "supertuxkart" "supertuxkart" "supertuxkart" "net.supertuxkart.SuperTuxKart" "native"
add_app "FALSE" "Jogos" "Chromium BSU" "Arcade Space Shooter" "chromium-bsu" "chromium-bsu" "chromium-bsu" "" "native"
add_app "FALSE" "Jogos" "Tiny Wii Backup" "Backup Manager Wii" "" "" "" "it.mq1.TinyWiiBackupManager" "flatpak"

# --- UTILITÁRIOS E SISTEMA ---
add_app "FALSE" "Sistema" "Gparted" "Partições" "gparted" "gparted" "gparted" "org.gnome.PartitionEditor" "native"
add_app "FALSE" "Sistema" "Remmina" "Acesso Remoto" "remmina" "remmina" "remmina" "org.remmina.Remmina" "native"
add_app "FALSE" "Sistema" "FlameShot" "Screenshot" "flameshot" "flameshot" "flameshot" "org.flameshot.Flameshot" "native"
add_app "TRUE" "Sistema" "ZRAM" "Compressão RAM" "zram-tools" "zram-generator" "zram-generator" "" "native"
add_app "FALSE" "Utilitários" "ISO Image Writer" "Gravador USB" "" "" "" "org.kde.isoimagewriter" "flatpak"
add_app "FALSE" "Utilitários" "Letterpress" "Conversor ASCII" "" "" "" "io.gitlab.gregorni.Letterpress" "flatpak"
add_app "FALSE" "Utilitários" "SaveDesktop" "Salvar estado janelas" "" "" "" "io.github.vikdevelop.SaveDesktop" "flatpak"
add_app "TRUE" "Utilitários" "7Zip e Rar" "Compactação" "7zip 7zip-rar unrar arj" "7zip unrar arj" "p7zip p7zip-plugins unrar arj" "" "native"
add_app "TRUE" "Utilitários" "Grsync" "Rsync GUI" "grsync" "grsync" "grsync" "" "native"
add_app "FALSE" "Utilitários" "Ventoy" "Criador USB Bootável" "" "ventoy-bin" "" "ventoy" "native"

# --- IMPRESSÃO & DRIVERS ---
add_app "TRUE" "Impressão" "CUPS Base" "Sistema de Impressão" "cups cups-backend-bjnp" "cups" "cups" "" "native"
add_app "TRUE" "Impressão" "Drivers HP" "Drivers para HP" "hplip" "hplip" "hplip" "" "native"
add_app "TRUE" "Impressão" "Drivers Epson" "Drivers para Epson" "printer-driver-escpr escputil" "epson-inkjet-printer-escpr" "epson-inkjet-printer-escpr" "" "native"
add_app "TRUE" "Impressão" "Gutenprint" "Drivers Genéricos" "printer-driver-gutenprint" "gutenprint" "gutenprint" "" "native"

# --- IA E CLI ---
#add_app "FALSE" "IA" "OpenAI Whisper" "Reconhecimento de Fala" "" "" "" "openai-whisper" "pipx"  =====> Instalado pelo install-ia-stack.sh
add_app "TRUE" "IA" "Subliminal" "Baixador de Legendas" "" "" "" "subliminal" "pipx"
add_app "TRUE" "IA" "Trans" "Tradutor de Texto" "" "" "" "translate-shell googletrans" "pipx"

log "SUCCESS" "Banco de dados de aplicativos carregado"
