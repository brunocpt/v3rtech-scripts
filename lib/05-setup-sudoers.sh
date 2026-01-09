#!/bin/bash
# ==============================================================================
# Projeto: v3rtech-scripts
# Arquivo: lib/05-setup-sudoers.sh
# Versão: 1.0.0 (Novo)
# Descrição: Configura sudo sem senha de forma idempotente e segura
# Compatível com: Arch, Debian/Ubuntu, Fedora, Solus
# ==============================================================================

log "INFO" "Configurando sudo sem senha para o usuário atual..."

# Valida se o usuário está definido
if [ -z "$REAL_USER" ]; then
    log "WARN" "Variável REAL_USER não definida. Tentando detectar..."
    REAL_USER=$(logname 2>/dev/null || whoami)
fi

# Arquivo de configuração sudoers
SUDOERS_FILE="/etc/sudoers.d/99_v3rtech_nopasswd"

# Detecta a distribuição para determinar o grupo padrão
case "$DISTRO_FAMILY" in
    debian)
        SUDO_GROUP="sudo"
        ;;
    arch)
        SUDO_GROUP="wheel"
        ;;
    fedora)
        SUDO_GROUP="wheel"
        ;;
    *)
        SUDO_GROUP="sudo"
        ;;
esac

# Verifica se o usuário já está no grupo de sudo
if ! id -nG "$REAL_USER" | grep -qw "$SUDO_GROUP"; then
    log "INFO" "Adicionando $REAL_USER ao grupo $SUDO_GROUP..."
    $SUDO usermod -aG "$SUDO_GROUP" "$REAL_USER"
    log "SUCCESS" "Usuário adicionado ao grupo $SUDO_GROUP"
fi

# Cria arquivo sudoers idempotente
log "INFO" "Configurando arquivo sudoers: $SUDOERS_FILE"

# Cria arquivo temporário
SUDOERS_TMP=$($SUDO mktemp)

# Escreve a configuração
cat <<EOF | $SUDO tee "$SUDOERS_TMP" > /dev/null
# ==============================================================================
# Configuração de sudo sem senha - v3rtech-scripts
# Arquivo gerado automaticamente. Não edite manualmente.
# ==============================================================================

# Permite que o usuário execute todos os comandos sem senha
$REAL_USER ALL=(ALL) NOPASSWD: ALL

# Permite que membros do grupo sudo/wheel executem sem senha (fallback)
%$SUDO_GROUP ALL=(ALL) NOPASSWD: ALL
EOF

# Valida o arquivo antes de aplicar
if ! $SUDO visudo -c -f "$SUDOERS_TMP" &>/dev/null; then
    log "ERROR" "Arquivo sudoers inválido. Abortando."
    $SUDO rm -f "$SUDOERS_TMP"
    return 1
fi

# Aplica o arquivo com permissões corretas
$SUDO install -m 0440 -o root -g root "$SUDOERS_TMP" "$SUDOERS_FILE"
$SUDO rm -f "$SUDOERS_TMP"

# Verifica se a configuração está funcionando
if $SUDO visudo -c -q; then
    log "SUCCESS" "Sudo configurado sem senha para $REAL_USER"
else
    log "ERROR" "Falha na validação final do sudoers"
    return 1
fi

# Testa se o sudo realmente não pede senha
if $SUDO -n true 2>/dev/null; then
    log "SUCCESS" "Teste confirmado: sudo não pede senha"
else
    log "WARN" "Sudo pode ainda pedir senha em algumas situações"
fi

log "SUCCESS" "Configuração de sudoers concluída."
