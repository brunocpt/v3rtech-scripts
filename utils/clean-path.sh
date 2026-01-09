#!/bin/bash
# ==============================================================================
# Script: clean-path-nuclear
# Versão: 3.0.0 (NUCLEAR - Remove TODAS as linhas de PATH)
# Descrição: Remove TODAS as linhas que modificam PATH e injeta uma única linha limpa
# Uso: ./clean-path-nuclear.sh [--dry-run]
# ==============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ==============================================================================
# FUNÇÕES
# ==============================================================================

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_nuclear() {
    echo -e "${MAGENTA}☢${NC} $1"
}

# Função para limpar PATH de entradas repetidas
clean_path() {
    local path_var="$1"
    local cleaned=""
    
    # Declara array associativo para rastrear componentes já vistos
    declare -A seen
    
    # Divide o PATH em componentes e remove duplicatas
    IFS=':' read -ra components <<< "$path_var"
    
    for component in "${components[@]}"; do
        # Pula entradas vazias
        if [ -z "$component" ]; then
            continue
        fi
        
        # Se não foi visto antes, adiciona
        if [ -z "${seen[$component]:-}" ]; then
            if [ -z "$cleaned" ]; then
                cleaned="$component"
            else
                cleaned="$cleaned:$component"
            fi
            seen[$component]=1
        fi
    done
    
    echo "$cleaned"
}

# Função para remover TODAS as linhas de PATH de um arquivo
nuke_path_from_file() {
    local file="$1"
    local is_system="${2:-false}"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    print_info "Processando: $file"
    
    # Conta linhas com PATH ANTES
    local before=$(grep -c "export PATH=\|^PATH=" "$file" 2>/dev/null || echo 0)
    
    if [ "$before" -eq 0 ]; then
        print_success "$file: Nenhuma linha de PATH encontrada"
        return 0
    fi
    
    print_warn "$file: Encontradas $before linhas de PATH - REMOVENDO TODAS..."
    
    # Remove TODAS as linhas que contêm PATH
    if [ "$is_system" = "true" ]; then
        sudo sed -i '/export PATH=/d' "$file"
        sudo sed -i '/^PATH=/d' "$file"
    else
        sed -i '/export PATH=/d' "$file"
        sed -i '/^PATH=/d' "$file"
    fi
    
    # Verifica se foram removidas
    local after=$(grep -c "export PATH=\|^PATH=" "$file" 2>/dev/null || echo 0)
    
    if [ "$after" -eq 0 ]; then
        print_nuclear "$file: $before linhas de PATH REMOVIDAS com sucesso!"
    else
        print_error "$file: Ainda há $after linhas de PATH!"
        return 1
    fi
    
    return 0
}

# ==============================================================================
# MAIN
# ==============================================================================

DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              CLEAN-PATH NUCLEAR v3.0.0                         ║"
echo "║         Remove TODAS as linhas de PATH duplicadas              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

print_info "Analisando PATH do sistema..."
echo ""

# Mostra PATH atual
echo "PATH atual:"
echo "════════════════════════════════════════════════════════════════"
echo "$PATH" | tr ':' '\n' | nl
echo "════════════════════════════════════════════════════════════════"
echo ""

# Conta entradas
ORIGINAL_COUNT=$(echo "$PATH" | tr ':' '\n' | grep -v '^$' | wc -l)
print_info "Total de entradas: $ORIGINAL_COUNT"

# Limpa PATH
CLEANED_PATH=$(clean_path "$PATH")
CLEANED_COUNT=$(echo "$CLEANED_PATH" | tr ':' '\n' | grep -v '^$' | wc -l)

if [ "$ORIGINAL_COUNT" -eq "$CLEANED_COUNT" ]; then
    print_success "PATH sem duplicatas!"
    exit 0
fi

DUPLICATES=$((ORIGINAL_COUNT - CLEANED_COUNT))
print_warn "Encontradas $DUPLICATES entradas duplicadas!"
echo ""

# Mostra PATH limpo
echo "PATH após limpeza:"
echo "════════════════════════════════════════════════════════════════"
echo "$CLEANED_PATH" | tr ':' '\n' | nl
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$DRY_RUN" = true ]; then
    print_info "Modo --dry-run: nenhuma alteração foi feita."
    exit 0
fi

# Pergunta confirmação
print_warn "AVISO: Este script vai REMOVER TODAS as linhas de PATH dos seus arquivos de inicialização!"
print_warn "Depois vai injetar uma única linha limpa."
echo ""
read -p "Tem certeza que deseja continuar? (s/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    print_warn "Operação cancelada."
    exit 0
fi

# ==============================================================================
# APLICAR ALTERAÇÕES NUCLEARES
# ==============================================================================

echo ""
print_nuclear "INICIANDO OPERAÇÃO NUCLEAR..."
echo ""

# 1. Atualiza o PATH da sessão atual
export PATH="$CLEANED_PATH"
print_success "PATH da sessão atual atualizado"

# 2. NUKE /etc/bash.bashrc
if [ -f /etc/bash.bashrc ]; then
    nuke_path_from_file "/etc/bash.bashrc" "true" || true
fi

# 3. NUKE ~/.bashrc
if [ -f ~/.bashrc ]; then
    nuke_path_from_file ~/.bashrc "false" || true
fi

# 4. NUKE ~/.bash_profile
if [ -f ~/.bash_profile ]; then
    nuke_path_from_file ~/.bash_profile "false" || true
fi

# 5. NUKE ~/.profile
if [ -f ~/.profile ]; then
    nuke_path_from_file ~/.profile "false" || true
fi

# 6. NUKE ~/.zshrc
if [ -f ~/.zshrc ]; then
    nuke_path_from_file ~/.zshrc "false" || true
fi

echo ""
print_info "Injetando nova linha de PATH limpa..."

# Injeta a nova linha limpa em ~/.bashrc
if [ -f ~/.bashrc ]; then
    {
        echo ""
        echo "# === V3RTECH SCRIPTS: Clean PATH ==="
        echo "export PATH=\"$CLEANED_PATH\""
        echo "# === END ==="
    } >> ~/.bashrc
    print_success "Linha de PATH limpa injetada em ~/.bashrc"
fi

echo ""
print_nuclear "OPERAÇÃO NUCLEAR CONCLUÍDA!"
echo ""
print_success "PATH limpo com sucesso!"
print_info "Reinicie o terminal para aplicar as alterações."
print_info "Ou execute: exec bash"
echo ""

# Mostra o novo PATH que será usado
echo "Novo PATH que será usado:"
echo "════════════════════════════════════════════════════════════════"
echo "$CLEANED_PATH" | tr ':' '\n' | nl
echo "════════════════════════════════════════════════════════════════"
