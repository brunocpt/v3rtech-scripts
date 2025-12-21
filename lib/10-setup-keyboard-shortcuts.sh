#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/10-setup-keyboard-shortcuts.sh
# Versão: 1.0.0 (Novo)
# Descrição: Restaura atalhos de teclado personalizados por ambiente de desktop
# Compatível com: KDE/Plasma, GNOME/Budgie, XFCE, Tiling WM
# ==============================================================================

log "INFO" "Restaurando atalhos de teclado personalizados..."

# Valida se o usuário está definido
if [ -z "$REAL_USER" ] || [ -z "$REAL_HOME" ]; then
    log "WARN" "Variáveis REAL_USER ou REAL_HOME não definidas"
    return 1
fi

# Valida se DESKTOP_ENV está definido
if [ -z "$DESKTOP_ENV" ]; then
    log "WARN" "Variável DESKTOP_ENV não definida. Pulando restauração de atalhos."
    return 0
fi

# Diretório de backup de atalhos
SHORTCUTS_BACKUP_DIR="/usr/local/share/scripts/v3rtech-scripts/backups"

# ==============================================================================
# 1. KDE/PLASMA
# ==============================================================================

if [ "$DESKTOP_ENV" = "kde" ]; then
    log "INFO" "Restaurando atalhos de teclado para KDE/Plasma..."
    
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-kde.zip"
    
    if [ -f "$SHORTCUTS_ZIP" ]; then
        log "INFO" "Encontrado backup de atalhos KDE: $SHORTCUTS_ZIP"
        
        # Extrai para ~/.config/
        if unzip -o "$SHORTCUTS_ZIP" -d "$REAL_HOME/.config/" 2>/dev/null; then
            # Ajusta permissões
            $SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/k"*"shortcut"* 2>/dev/null || true
            
            log "SUCCESS" "Atalhos de teclado restaurados para KDE/Plasma"
        else
            log "ERROR" "Falha ao extrair backup de atalhos KDE"
        fi
    else
        log "WARN" "Backup de atalhos KDE não encontrado: $SHORTCUTS_ZIP"
        log "INFO" "Atalhos padrão do KDE serão usados"
    fi

# ==============================================================================
# 2. GNOME/BUDGIE
# ==============================================================================

elif [ "$DESKTOP_ENV" = "gnome" ] || [ "$DESKTOP_ENV" = "budgie" ]; then
    log "INFO" "Restaurando atalhos de teclado para GNOME/Budgie..."
    
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-gnome.zip"
    
    if [ -f "$SHORTCUTS_ZIP" ]; then
        log "INFO" "Encontrado backup de atalhos GNOME: $SHORTCUTS_ZIP"
        
        # Extrai arquivo dconf
        if unzip -p "$SHORTCUTS_ZIP" "custom-keybindings.dconf" 2>/dev/null | \
           $SUDO -u "$REAL_USER" dconf load /org/gnome/settings-daemon/plugins/media-keys/ 2>/dev/null; then
            log "SUCCESS" "Atalhos de teclado restaurados para GNOME/Budgie"
        else
            log "ERROR" "Falha ao restaurar atalhos GNOME via dconf"
        fi
    else
        log "WARN" "Backup de atalhos GNOME não encontrado: $SHORTCUTS_ZIP"
        log "INFO" "Atalhos padrão do GNOME serão usados"
    fi

# ==============================================================================
# 3. XFCE
# ==============================================================================

elif [ "$DESKTOP_ENV" = "xfce" ]; then
    log "INFO" "Restaurando atalhos de teclado para XFCE..."
    
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-xfce.zip"
    
    if [ -f "$SHORTCUTS_ZIP" ]; then
        log "INFO" "Encontrado backup de atalhos XFCE: $SHORTCUTS_ZIP"
        
        # Extrai para ~/.config/xfce4/xfconf/xfce-perchannel-xml/
        mkdir -p "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
        
        if unzip -o "$SHORTCUTS_ZIP" -d "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>/dev/null; then
            # Ajusta permissões
            $SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/xfce4/" 2>/dev/null || true
            
            # Reinicia o painel XFCE para aplicar mudanças
            $SUDO -u "$REAL_USER" xfce4-panel -r 2>/dev/null || true
            
            log "SUCCESS" "Atalhos de teclado restaurados para XFCE"
        else
            log "ERROR" "Falha ao extrair backup de atalhos XFCE"
        fi
    else
        log "WARN" "Backup de atalhos XFCE não encontrado: $SHORTCUTS_ZIP"
        log "INFO" "Atalhos padrão do XFCE serão usados"
    fi

# ==============================================================================
# 4. LXQT
# ==============================================================================

elif [ "$DESKTOP_ENV" = "lxqt" ]; then
    log "INFO" "Restaurando atalhos de teclado para LXQT..."
    
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-lxqt.zip"
    
    if [ -f "$SHORTCUTS_ZIP" ]; then
        log "INFO" "Encontrado backup de atalhos LXQT: $SHORTCUTS_ZIP"
        
        # Extrai para ~/.config/lxqt/
        mkdir -p "$REAL_HOME/.config/lxqt/"
        
        if unzip -o "$SHORTCUTS_ZIP" -d "$REAL_HOME/.config/lxqt/" 2>/dev/null; then
            # Ajusta permissões
            $SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/lxqt/" 2>/dev/null || true
            
            log "SUCCESS" "Atalhos de teclado restaurados para LXQT"
        else
            log "ERROR" "Falha ao extrair backup de atalhos LXQT"
        fi
    else
        log "WARN" "Backup de atalhos LXQT não encontrado: $SHORTCUTS_ZIP"
        log "INFO" "Atalhos padrão do LXQT serão usados"
    fi

# ==============================================================================
# 5. TILING WINDOW MANAGERS (i3, sway, etc)
# ==============================================================================

elif [ "$DESKTOP_ENV" = "tiling-wm" ]; then
    log "INFO" "Restaurando configurações para Tiling Window Manager..."
    
    SHORTCUTS_ZIP="$SHORTCUTS_BACKUP_DIR/${REAL_USER}-atalhos-tiling.zip"
    
    if [ -f "$SHORTCUTS_ZIP" ]; then
        log "INFO" "Encontrado backup de configurações Tiling WM: $SHORTCUTS_ZIP"
        
        # Extrai para ~/.config/
        if unzip -o "$SHORTCUTS_ZIP" -d "$REAL_HOME/.config/" 2>/dev/null; then
            # Ajusta permissões
            $SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/" 2>/dev/null || true
            
            log "SUCCESS" "Configurações restauradas para Tiling WM"
        else
            log "ERROR" "Falha ao extrair backup de configurações Tiling WM"
        fi
    else
        log "WARN" "Backup de configurações Tiling WM não encontrado: $SHORTCUTS_ZIP"
        log "INFO" "Configurações padrão do Tiling WM serão usadas"
    fi

# ==============================================================================
# 6. AMBIENTE DESCONHECIDO
# ==============================================================================

else
    log "WARN" "Ambiente de desktop não suportado para restauração de atalhos: $DESKTOP_ENV"
    log "INFO" "Atalhos padrão do ambiente serão usados"
fi

# ==============================================================================
# 7. PERMISSÕES FINAIS
# ==============================================================================

log "INFO" "Ajustando permissões finais..."

# Garante que o usuário é proprietário de suas configurações
$SUDO chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/" 2>/dev/null || true

log "SUCCESS" "Permissões ajustadas"

log "SUCCESS" "Restauração de atalhos de teclado concluída."
