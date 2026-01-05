#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/03-setup-flatpak.sh
# Versão: 1.0.0
# Descrição: Configura o Flatpak, adiciona o repositório Flathub e aplica
#            overrides globais para acesso ao sistema de arquivos.
# ==============================================================================

log_header "Configurando Flatpak"

# --- 1. Instala o Flatpak se não estiver presente ---
if ! command -v flatpak &> /dev/null; then
    log "INFO" "Flatpak não encontrado. Instalando via gerenciador de pacotes nativo..."
    if ! i flatpak; then
        log "ERROR" "Falha ao instalar o Flatpak. Abortando configuração."
        return 1
    fi
else
    log "SUCCESS" "Flatpak já está instalado."
fi

# --- 2. Adiciona o repositório Flathub ---
log "INFO" "Adicionando repositório Flathub..."
if ! flatpak remotes | grep -q "flathub"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Repositório Flathub adicionado com sucesso."
    else
        log "ERROR" "Falha ao adicionar o repositório Flathub."
        return 1
    fi
else
    log "INFO" "Repositório Flathub já existe."
fi

# --- 3. Aplica Overrides Globais ---
log "INFO" "Aplicando overrides globais para acesso ao sistema de arquivos..."

# Concede acesso a temas, ícones e ao diretório /mnt
# Isso permite que os apps Flatpak se integrem melhor ao sistema e acessem montagens de rede.
if sudo flatpak override --filesystem=xdg-config/gtk-3.0 && \
   sudo flatpak override --filesystem=xdg-config/gtk-4.0 && \
   sudo flatpak override --filesystem=~/.themes && \
   sudo flatpak override --filesystem=~/.icons && \
   sudo flatpak override --filesystem=/mnt && \
   sudo flatpak override --filesystem=host-etc;
   # O host-etc é necessário para apps como o Assinador SERPRO acessarem os certificados
then
    log "SUCCESS" "Overrides globais do Flatpak aplicados com sucesso."
else
    log "ERROR" "Falha ao aplicar overrides do Flatpak."
    return 1
fi

log_header "Configuração do Flatpak concluída com sucesso."
