#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/apps-data.sh
# Versão: 2.1.0 (Full Database + Debian Sid Fixes)
# Descrição: Banco de dados centralizado. Contém todos os apps do CSV original.
# Formato: add_app "ATIVO" "CATEGORIA" "NOME" "DESC" "PKG_DEB" "PKG_ARCH" "PKG_FED" "FLATPAK" "METODO"
# ==============================================================================

# --- NAVEGADORES ---
add_app "TRUE" "Internet" "Wavebox" "Navegador focado em trabalho" "wavebox" "wavebox" "wavebox" "" "native"
add_app "TRUE" "Internet" "Google Chrome" "Navegador do Google" "google-chrome-stable" "google-chrome" "google-chrome-stable" "com.google.Chrome" "native"
add_app "TRUE" "Internet" "Firefox" "Navegador Mozilla" "firefox" "firefox" "firefox" "org.mozilla.firefox" "native"
add_app "TRUE" "Internet" "Brave" "Navegador Privacidade" "brave-browser" "brave-bin" "brave-browser" "com.brave.Browser" "native"
add_app "TRUE" "Internet" "Vivaldi" "Navegador Power User" "vivaldi-stable" "vivaldi" "vivaldi" "com.vivaldi.Vivaldi" "native"
add_app "TRUE" "Internet" "Opera" "Navegador com VPN" "" "opera" "" "com.opera.Opera" "native"
add_app "TRUE" "Internet" "Microsoft Edge" "Navegador Microsoft" "microsoft-edge-stable" "microsoft-edge-stable-bin" "microsoft-edge-stable" "com.microsoft.Edge" "native"

# --- NUVEM E TRANSFERÊNCIA ---
add_app "TRUE" "Nuvem" "Nextcloud" "Sync Nextcloud" "nextcloud-desktop" "nextcloud-client" "nextcloud-client" "com.nextcloud.desktopclient.nextcloud" "native"
add_app "FALSE" "Nuvem" "Filezilla" "Cliente FTP" "filezilla" "filezilla" "filezilla" "org.filezilla.FileZilla" "native"

# --- COMUNICAÇÃO ---
add_app "FALSE" "Comunicação" "Discord" "Chat e Voz" "discord" "discord" "discord" "com.discordapp.Discord" "flatpak"
add_app "FALSE" "Comunicação" "MailViewer" "Visualizador EML/MSG" "" "" "" "io.github.alescdb.mailviewer" "flatpak"

# --- DESENVOLVIMENTO & TERMINAL ---
add_app "FALSE" "Dev" "VS Code" "Editor Microsoft" "code" "visual-studio-code-bin" "code" "com.visualstudio.code" "native"
add_app "TRUE" "Dev" "Antigravity" "Ambiente Google (VSCode)" "antigravity" "antigravity" "antigravity" "" "native"
add_app "TRUE" "Dev" "Docker" "Containers" "docker.io docker-compose" "docker docker-compose" "docker docker-compose-plugin" "" "native"
add_app "FALSE" "Dev" "DBeaver" "Cliente SQL" "dbeaver-ce" "dbeaver" "dbeaver" "io.dbeaver.DBeaverCommunity" "native"
add_app "FALSE" "Dev" "Postman" "Plataforma API" "postman" "postman-bin" "postman" "com.getpostman.Postman" "native"
add_app "FALSE" "Dev" "Terminator" "Terminal Avançado" "terminator" "terminator" "terminator" "" "native"
add_app "TRUE" "Dev" "Guake" "Terminal Drop-down" "guake" "guake" "guake" "" "native"
add_app "TRUE" "Dev" "Geany" "Editor Leve" "geany geany-plugins" "geany geany-plugins" "geany geany-plugins" "" "native"
add_app "TRUE" "Dev" "Git Tools" "Git e GitHub CLI" "git gh" "git github-cli" "git gh" "" "native"
add_app "TRUE" "Dev" "Dev Utils" "JQ, CCache, Duf, Eza" "jq ccache duf eza" "jq ccache duf eza" "jq ccache duf eza" "" "native"

# --- ESCRITÓRIO E PRODUTIVIDADE ---
add_app "TRUE" "Escritório" "LibreOffice" "Suíte Office" "libreoffice libreoffice-l10n-pt-br" "libreoffice-fresh libreoffice-fresh-pt-br" "libreoffice libreoffice-langpack-pt-BR" "org.libreoffice.LibreOffice" "native"
add_app "TRUE" "Escritório" "Obsidian" "Knowledge Base" "" "obsidian" "obsidian" "md.obsidian.Obsidian" "flatpak"
add_app "TRUE" "Escritório" "Calibre" "E-books" "calibre" "calibre" "calibre" "com.calibre_ebook.calibre" "native"
add_app "TRUE" "Escritório" "Zotero" "Gestão Bibliográfica" "" "zotero-bin" "zotero" "org.zotero.Zotero" "flatpak"
add_app "TRUE" "Escritório" "XMind" "Mapas Mentais" "" "xmind" "xmind" "net.xmind.XMind8" "flatpak"
add_app "TRUE" "Escritório" "Camunda Modeler" "Modelagem BPMN" "" "camunda-modeler" "camunda-modeler" "" "native"
add_app "TRUE" "Escritório" "Draw.io" "Diagramas" "drawio" "drawio-desktop" "drawio" "com.jgraph.drawio.desktop" "native"
# FIX: Garante 'aspell-pt-br' pois 'aspell-pt' pode falhar
add_app "TRUE" "Escritório" "Corretores PT-BR" "Dicionários" "aspell-pt-br hunspell-pt-br mythes-pt-br hyphen-pt-br wportuguese" "aspell-pt hunspell-pt mythes-pt hyphen-pt" "aspell-pt hunspell-pt mythes-pt hyphen-pt" "" "native"

# --- PDF E OCR ---
add_app "TRUE" "Escritório" "Sejda PDF" "Editor PDF Desktop" "" "sejda-desktop" "sejda-desktop" "com.sejda.Sejda" "flatpak"
add_app "TRUE" "Escritório" "OCRmyPDF" "OCR em PDFs" "ocrmypdf ghostscript jbig2dec" "ocrmypdf ghostscript jbig2dec" "ocrmypdf ghostscript jbig2dec" "" "native"
add_app "TRUE" "Escritório" "Tesseract OCR" "Motor OCR" "tesseract-ocr tesseract-ocr-por tesseract-ocr-eng" "tesseract tesseract-data-por tesseract-data-eng" "tesseract tesseract-langpack-por" "" "native"

# --- DESIGN & IMAGEM ---
add_app "TRUE" "Design" "Inkscape" "Vetorial" "inkscape" "inkscape" "inkscape" "org.inkscape.Inkscape" "native"
add_app "TRUE" "Design" "GIMP" "Imagens" "gimp" "gimp" "gimp" "org.gimp.GIMP" "native"
add_app "FALSE" "Design" "Upscayl" "Upscaling IA" "" "upscayl-bin" "upscayl" "org.upscayl.Upscayl" "flatpak"
add_app "FALSE" "Design" "Penpot" "Prototipagem" "" "" "" "com.authormore.penpotdesktop" "flatpak"
add_app "FALSE" "Design" "FreeCAD" "Modelagem 3D" "freecad" "freecad" "freecad" "org.freecad.FreeCAD" "native"
add_app "FALSE" "Design" "Scribus" "Desktop Publishing" "scribus" "scribus" "scribus" "net.scribus.Scribus" "native"
add_app "FALSE" "Design" "WebP Converter" "Conversor WebP" "" "" "" "io.itsterminal.WebPConverter" "flatpak"
add_app "TRUE" "Design" "ImageMagick" "Manipulação CLI" "imagemagick" "imagemagick" "imagemagick" "" "native"

# --- MULTIMÍDIA ---
add_app "TRUE" "Multimídia" "VLC" "Player" "vlc" "vlc" "vlc" "org.videolan.VLC" "native"
add_app "TRUE" "Multimídia" "OBS Studio" "Streaming" "obs-studio" "obs-studio" "obs-studio" "com.obsproject.Studio" "native"
add_app "FALSE" "Multimídia" "Spotify" "Música" "spotify-client" "spotify" "spotify-client" "com.spotify.Client" "flatpak"
add_app "TRUE" "Multimídia" "Filebot" "Organizador" "" "" "" "net.filebot.FileBot" "flatpak"
add_app "FALSE" "Multimídia" "MuseAmp" "Player estilo Winamp" "" "" "" "io.github.tapscodes.MuseAmp" "flatpak"
add_app "TRUE" "Multimídia" "MusicBrainz Picard" "Tagger de Música" "picard" "picard" "picard" "org.musicbrainz.Picard" "native"
add_app "TRUE" "Multimídia" "Avidemux" "Editor de Vídeo" "avidemux" "avidemux-qt" "avidemux" "org.avidemux.Avidemux" "native"
add_app "TRUE" "Multimídia" "MKVToolNix" "Ferramentas MKV" "mkvtoolnix" "mkvtoolnix-cli mkvtoolnix-gui" "mkvtoolnix" "org.bunkus.mkvtoolnix-gui" "native"

# --- JOGOS ---
# FIX: 'steam-installer' substituído por 'steam' (meta-pacote non-free correto)
add_app "FALSE" "Jogos" "Steam" "Loja de Jogos" "steam" "steam" "steam" "com.valvesoftware.Steam" "native"
add_app "FALSE" "Jogos" "Bottles" "Wine Manager" "" "" "" "com.usebottles.bottles" "flatpak"
add_app "FALSE" "Jogos" "Extreme Tux Racer" "Corrida" "extremetuxracer" "extremetuxracer" "extremetuxracer" "" "native"
add_app "FALSE" "Jogos" "SuperTuxKart" "Kart" "supertuxkart" "supertuxkart" "supertuxkart" "net.supertuxkart.SuperTuxKart" "native"
add_app "FALSE" "Jogos" "Chromium BSU" "Arcade Space Shooter" "chromium-bsu" "chromium-bsu" "chromium-bsu" "" "native"
add_app "FALSE" "Jogos" "Tiny Wii Backup" "Backup Manager Wii" "" "" "" "it.mq1.TinyWiiBackupManager" "flatpak"

# --- UTILITÁRIOS E SISTEMA ---
add_app "TRUE" "Sistema" "Gparted" "Partições" "gparted" "gparted" "gparted" "org.gnome.PartitionEditor" "native"
add_app "TRUE" "Sistema" "Remmina" "Acesso Remoto" "remmina" "remmina" "remmina" "org.remmina.Remmina" "native"
add_app "TRUE" "Sistema" "FlameShot" "Screenshot" "flameshot" "flameshot" "flameshot" "org.flameshot.Flameshot" "native"
add_app "TRUE" "Sistema" "ZRAM" "Compressão RAM" "zram-tools" "zram-generator" "zram-generator" "" "native"
add_app "FALSE" "Utils" "ISO Image Writer" "Gravador USB" "" "" "" "org.kde.isoimagewriter" "flatpak"
add_app "FALSE" "Utils" "Letterpress" "Conversor ASCII" "" "" "" "io.gitlab.gregorni.Letterpress" "flatpak"
add_app "FALSE" "Utils" "SaveDesktop" "Salvar estado janelas" "" "" "" "io.github.vikdevelop.SaveDesktop" "flatpak"
add_app "TRUE" "Utils" "7Zip e Rar" "Compactação" "7zip 7zip-rar unrar arj" "p7zip unrar arj" "p7zip p7zip-plugins unrar arj" "" "native"
add_app "TRUE" "Utils" "Grsync" "Rsync GUI" "grsync" "grsync" "grsync" "" "native"

# --- IMPRESSÃO & DRIVERS ---
add_app "TRUE" "Impressão" "CUPS Base" "Sistema de Impressão" "cups cups-backend-bjnp" "cups" "cups" "" "native"
add_app "TRUE" "Impressão" "Drivers HP" "Drivers para HP" "hplip" "hplip" "hplip" "" "native"
add_app "TRUE" "Impressão" "Drivers Epson" "Drivers para Epson" "printer-driver-escpr escputil" "epson-inkjet-printer-escpr" "epson-inkjet-printer-escpr" "" "native"
add_app "TRUE" "Impressão" "Gutenprint" "Drivers Genéricos" "printer-driver-gutenprint" "gutenprint" "gutenprint" "" "native"

# --- IA E CLI ---
add_app "TRUE" "IA" "OpenAI Whisper" "Reconhecimento de Fala" "" "" "" "openai-whisper" "pipx"
add_app "TRUE" "IA" "Subliminal" "Baixador de Legendas" "" "" "" "subliminal" "pipx"
add_app "FALSE" "IA" "YT-DLP" "Downloader de Vídeos" "yt-dlp" "yt-dlp" "yt-dlp" "yt-dlp" "native"

# --- CUSTOM SCRIPTS ---
add_app "FALSE" "Utils" "Ventoy" "Criador USB Bootável" "" "" "" "ventoy" "custom"
