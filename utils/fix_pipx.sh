#!/usr/bin/env bash

# ==============================================================================
# Script: fix_pipx.sh
# Versão: 4.0.5
# Data: 2026-02-24
# Objetivo: Verificar e reparar ambientes virtuais do pipx (links quebrados)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# Define o caminho padrão dos venvs do pipx
PIPX_DIR="$HOME/.local/share/pipx/venvs"

echo "🔍 Verificando integridade dos ambientes pipx em: $PIPX_DIR"

# Verifica se o diretório existe
if [ ! -d "$PIPX_DIR" ]; then
    echo "❌ Diretório do pipx não encontrado. Nada para fazer."
    exit 0
fi

# Procura por links simbólicos quebrados (xtype l)
# Focamos especificamente no binário python dentro dos venvs
BROKEN_LINKS=$(find "$PIPX_DIR" -maxdepth 3 -name "python" -xtype l)

if [ -n "$BROKEN_LINKS" ]; then
    echo "⚠️  Links quebrados detectados:"
    echo "$BROKEN_LINKS"
    echo ""
    echo "⚙️  Iniciando a correção automática (pipx reinstall-all)..."
    
    # Executa a reinstalação
    if pipx reinstall-all; then
        echo "✅ Todos os pacotes foram reinstalados com sucesso!"
    else
        echo "❌ Erro ao tentar reinstalar os pacotes."
        exit 1
    fi
else
    echo "✅ Nenhum link quebrado encontrado. Seus ambientes estão íntegros."
fi