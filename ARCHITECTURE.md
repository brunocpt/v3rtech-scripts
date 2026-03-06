# Arquitetura - V3RTECH Scripts v6.0.0

Documentação técnica detalhada da arquitetura do projeto.

---

## 📐 Visão Geral da Arquitetura

A V3RTECH Scripts v6.0.0 foi projetada com os seguintes princípios:

1. **Modularidade:** Cada script é independente e autossuficiente
2. **Configuração Centralizada:** Estado compartilhado via arquivo de configuração
3. **Agnóstico de Distribuição:** Suporta múltiplas distribuições Linux
4. **Fácil de Estender:** Estrutura clara para adicionar novos scripts
5. **Segurança:** Validações, backups e tratamento de erros robusto

---

## 🏗️ Estrutura de Camadas

```
┌─────────────────────────────────────────────┐
│        v3rtech-install.sh (Orquestrador)   │
├─────────────────────────────────────────────┤
│     lib/ (Scripts de Instalação/Config)    │
│  - install-*.sh                             │
│  - install-desktop-*.sh                     │
│  - setup-*.sh                               │
│  - cleanup.sh                               │
├─────────────────────────────────────────────┤
│      core/ (Infraestrutura Base)            │
│  - env.sh (Variáveis globais)               │
│  - logging.sh (Log e diálogos)              │
│  - package-mgr.sh (Abstração de pacotes)    │
│  - config.conf (Configuração compartilhada) │
├─────────────────────────────────────────────┤
│   Sistema Operacional (Distro + Desktop)   │
└─────────────────────────────────────────────┘
```

---

## 📁 Estrutura de Diretórios Detalhada

### core/ - Infraestrutura Base

**Responsabilidade:** Fornecer funções e variáveis globais para todos os scripts.

| Arquivo | Propósito | Carregado por |
|---------|----------|---|
| `config.conf` | Armazena estado compartilhado | env.sh |
| `env.sh` | Variáveis globais, caminhos, cores | Todos os scripts |
| `logging.sh` | Funções de log e diálogos | Todos os scripts |
| `package-mgr.sh` | Abstração de gerenciadores de pacotes | Scripts de instalação |

**Ordem de Carregamento:**
```bash
source core/env.sh          # 1º - Variáveis e caminhos
source core/logging.sh      # 2º - Funções de log
source core/package-mgr.sh  # 3º - Gerenciador de pacotes
```

### lib/ - Scripts de Instalação

**Responsabilidade:** Implementar lógica de instalação e configuração.

#### Detecção e Essenciais

- `detect-system.sh` - Detecta distribuição, desktop, GPU, sessão
- `install-essentials.sh` - Instala pacotes obrigatórios

#### Instalação de Apps por Categoria

- `install-apps-internet.sh` - Navegadores, nuvem, comunicação
- `install-apps-office.sh` - Escritório, PDF, OCR
- `install-apps-dev.sh` - IDEs, ferramentas de dev
- `install-apps-multimedia.sh` - Áudio, vídeo, imagem
- `install-apps-design.sh` - Design gráfico
- `install-apps-system.sh` - Utilitários de sistema
- `install-apps-games.sh` - Emuladores e jogos

#### Instalação de Desktops

- `install-desktop-kde.sh` - KDE Plasma
- `install-desktop-gnome.sh` - GNOME
- `install-desktop-xfce.sh` - XFCE
- `install-desktop-deepin.sh` - Deepin
- `install-desktop-cosmic.sh` - Cosmic

#### Instalação Especializada

- `install-docker.sh` - Docker e Docker Compose
- `install-ia-stack.sh` - Stack de IA/ML
- `install-certificates.sh` - Certificados ICP-Brasil
- `install-virtualbox.sh` - VirtualBox

#### Configuração de Sistema

- `setup-system.sh` - PATH, aliases, sudoers, sysctl
- `cleanup.sh` - Limpeza final

### utils/ - Utilitários

**Responsabilidade:** Scripts especializados e ferramentas auxiliares.

Mantém os scripts do projeto original com melhorias:
- Adição de metadados (versão, data, objetivo)
- Comentários explicativos
- Consolidação de scripts similares quando apropriado

### configs/ - Arquivos de Configuração

**Responsabilidade:** Armazenar configurações do sistema.

- `aliases.geral` - Aliases globais de shell
- `cupsd.conf` - Configuração do CUPS
- Outros arquivos de configuração específicos

### resources/ - Recursos

**Responsabilidade:** Armazenar recursos estáticos.

- `atalhos/` - Atalhos de teclado por desktop
- `fonts/` - Fontes customizadas

---

## 🔄 Fluxo de Execução

### Execução de um Script Independente

```
1. Script iniciado
   ↓
2. Carrega core/env.sh
   ├─ Define variáveis globais
   ├─ Detecta caminhos
   └─ Carrega config.conf
   ↓
3. Carrega core/logging.sh
   └─ Inicializa arquivo de log
   ↓
4. Carrega core/package-mgr.sh
   └─ Define funções de instalação
   ↓
5. Se necessário, executa detect-system.sh
   └─ Detecta e salva informações do sistema
   ↓
6. Executa lógica principal do script
   ├─ Coleta inputs do usuário
   ├─ Valida inputs
   └─ Executa instalações/configurações
   ↓
7. Registra resultado em log
   ↓
8. Atualiza config.conf se necessário
   ↓
9. Script finaliza
```

### Execução do Setup Completo

```
1. v3rtech-install.sh iniciado
   ↓
2. Carrega infraestrutura base (core/)
   ↓
3. Exibe menu principal
   ↓
4. Usuário seleciona "Setup Completo"
   ↓
5. Seleciona categorias de apps
   ↓
6. Executa sequência de scripts:
   ├─ install-essentials.sh
   ├─ setup-system.sh
   ├─ install-desktop-*.sh
   ├─ install-apps-*.sh (selecionados)
   ├─ install-docker.sh (opcional)
   ├─ install-ia-stack.sh (opcional)
   ├─ install-certificates.sh (opcional)
   ├─ install-virtualbox.sh (opcional)
   └─ cleanup.sh
   ↓
7. Exibe resumo final
   ↓
8. Retorna ao menu principal
```

---

## 🔐 Arquivo de Configuração (config.conf)

### Localização

```
~/.config/v3rtech-scripts/config.conf
```

### Estrutura

```bash
# Detecção de Sistema
DISTRO_FAMILY="arch|debian|fedora"
DISTRO_NAME="ubuntu|arch|fedora"
PKG_MANAGER="apt|pacman|dnf"
DESKTOP_ENV="kde|gnome|xfce|deepin|cosmic"
SESSION_TYPE="x11|wayland"
GPU_VENDOR="intel|amd|nvidia"
IS_IMMUTABLE="true|false"

# Preferências do Usuário
PREFER_NATIVE="true|false"
INSTALL_CATEGORIES="internet office dev multimedia"

# Exceções
FILEBOT_METHOD="flatpak"
SUBLIMINAL_METHOD="pipx"

# Diretórios
BASE_DIR="/caminho/para/scripts"
CONFIG_HOME="$HOME/.config/v3rtech-scripts"
LOG_DIR="$HOME/.config/v3rtech-scripts/logs"

# Flags de Controle
DRY_RUN=0
AUTO_CONFIRM=0
VERBOSE=0

# Timestamp
LAST_UPDATE="2026-02-23 10:30:45"
```

### Criação e Atualização

- **Criado automaticamente** na primeira execução
- **Atualizado** por função `save_config()` em env.sh
- **Sourced** por todos os scripts para carregar estado
- **Permite** execução independente de scripts

---

## 🎯 Padrões de Design

### 1. Padrão de Função Auxiliar

Cada script de instalação define funções auxiliares para evitar duplicação:

```bash
install_app_smart() {
    local app_name="$1"
    local native_pkg="$2"
    local flatpak_id="$3"
    
    # Tenta nativo primeiro se preferência é nativa
    if [ "$PREFER_NATIVE" = "true" ] && [ -n "$native_pkg" ]; then
        i "$native_pkg" && return 0
    fi
    
    # Fallback para Flatpak
    if [ -n "$flatpak_id" ]; then
        install_flatpak "$flatpak_id" && return 0
    fi
    
    log "ERROR" "Falha ao instalar $app_name"
    return 1
}
```

### 2. Padrão de Idempotência

Scripts usam marcadores para garantir idempotência:

```bash
MARKER_BEGIN="# === V3RTECH: Bloco BEGIN ==="
MARKER_END="# === V3RTECH: Bloco END ==="

# Remove bloco anterior se existir
grep -q "$MARKER_BEGIN" /arquivo && \
    sed -i "/$MARKER_BEGIN/,/$MARKER_END/d" /arquivo

# Adiciona novo bloco
cat << EOF | sudo tee -a /arquivo > /dev/null
$MARKER_BEGIN
# Conteúdo aqui
$MARKER_END
EOF
```

### 3. Padrão de Tratamento de Erros

Diferencia erros críticos de não-críticos:

```bash
# Erro crítico - para execução
if [ ! -f "$CONFIG_FILE" ]; then
    die "Arquivo de configuração não encontrado"
fi

# Erro não-crítico - continua
i "pacote-opcional" || log "WARN" "Falha ao instalar pacote-opcional"
```

### 4. Padrão de Logging

Todos os eventos são registrados:

```bash
log "STEP" "Iniciando instalação..."
log "INFO" "Instalando pacote..."
log "WARN" "Aviso: algo pode dar errado"
log "ERROR" "Erro ao instalar"
log "SUCCESS" "Instalação concluída"
log "DEBUG" "Informação de debug (se VERBOSE=1)"
```

---

## 🔌 Extensibilidade

### Adicionar Novo Script de Instalação

1. Crie arquivo em `lib/install-apps-categoria.sh`
2. Copie template básico
3. Implemente lógica de instalação
4. Adicione ao menu do v3rtech-install.sh

### Adicionar Novo Desktop

1. Crie arquivo em `lib/install-desktop-novodesktop.sh`
2. Implemente instalação de pacotes
3. Adicione detecção em detect-system.sh
4. Adicione ao menu do v3rtech-install.sh

### Adicionar Nova Distribuição

1. Atualize detect-system.sh para detectar nova distro
2. Atualize package-mgr.sh com gerenciador de pacotes
3. Atualize todos os scripts de instalação com pacotes para nova distro
4. Teste em ambiente virtual

---

## 🧪 Testes

### Teste Manual de Script

```bash
# Teste em modo dry-run (simula sem executar)
DRY_RUN=1 ./lib/install-essentials.sh

# Teste com modo verbose
VERBOSE=1 ./lib/install-essentials.sh

# Teste com auto-confirm
AUTO_CONFIRM=1 ./lib/install-essentials.sh
```

### Teste em Distribuição Virtual

```bash
# Arch Linux
docker run -it archlinux bash

# Debian
docker run -it debian bash

# Fedora
docker run -it fedora bash
```

---

## 📊 Dependências Entre Scripts

```
v3rtech-install.sh
├── detect-system.sh (obrigatório)
├── install-essentials.sh (obrigatório)
├── setup-system.sh (recomendado)
├── install-desktop-*.sh (opcional)
├── install-apps-*.sh (opcional)
├── install-docker.sh (opcional)
├── install-ia-stack.sh (opcional)
├── install-certificates.sh (opcional)
├── install-virtualbox.sh (opcional)
└── cleanup.sh (recomendado)
```

**Nota:** Cada script é independente e pode ser executado isoladamente.

---

## 🔒 Segurança

### Validações

- Verifica se está rodando como root (não permitido)
- Valida sintaxe de sudoers antes de aplicar
- Valida arquivo de configuração
- Verifica integridade de downloads

### Proteção de Dados

- Cria backups de arquivos críticos
- Usa permissões restritas (700) para diretório de config
- Não armazena senhas em texto plano
- Valida entrada do usuário

### Privilégios

- Usa sudo apenas quando necessário
- Configura sudo sem senha de forma segura
- Respeita permissões de arquivo

---

## 🚀 Performance

### Otimizações

- Carregamento lazy de scripts
- Cache de detecção de sistema
- Parallelização onde possível
- Uso de apt-fast para Debian (se disponível)

### Benchmarks

| Operação | Tempo |
|----------|-------|
| Detecção de sistema | ~1s |
| Instalação de essenciais | ~5-10min |
| Setup completo | ~30-60min |

---

## 📈 Escalabilidade

A arquitetura suporta:

- **Múltiplos usuários:** Cada usuário tem seu próprio config.conf
- **Múltiplas máquinas:** Scripts podem ser distribuídos via Ansible
- **Customização:** Fácil adicionar novos scripts e categorias
- **Manutenção:** Estrutura clara facilita manutenção

---

## 🔄 Versionamento

- **Versão:** Segue Semantic Versioning (MAJOR.MINOR.PATCH)
- **Compatibilidade:** v4.0.0 é compatível com v4.x.x
- **Migração:** Documentada em CHANGELOG.md

---

**Última Atualização:** 2026-03-06
