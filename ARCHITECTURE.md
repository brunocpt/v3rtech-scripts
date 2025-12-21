# Arquitetura do V3RTECH Scripts v3.0.0

Este documento descreve o fluxo técnico, a estrutura de dados e as decisões de design do projeto (Versão 3.0+).

## 🧠 Filosofia de Design

**Idempotência Verdadeira:** Os scripts podem ser rodados múltiplas vezes sem quebrar o sistema. Todos os scripts usam marcadores de bloco (`BEGIN`/`END`) para remover conteúdo anterior antes de re-adicionar, garantindo que não há duplicação.

**Dados como Código:** A lista de aplicativos não é um arquivo de texto passivo (CSV), mas sim um script Bash (`lib/apps-data.sh`) carregado dinamicamente. Isso elimina erros de parsing de texto e permite maior flexibilidade.

**Persistência Global:** Configurações de ambiente (PATH, Aliases) são aplicadas em nível de sistema (`/etc/bash.bashrc`) para garantir funcionamento multiusuário e persistência após reinicialização.

**Modularidade Progressiva:** Cada etapa do processo é um arquivo isolado em `lib/`, numerado sequencialmente. O `v3rtech-install.sh` atua apenas como orquestrador.

**Multi-Ambiente:** Suporte completo para múltiplos ambientes de desktop (KDE, GNOME, XFCE, LXQT, Tiling WM) com configurações específicas por ambiente.

## 📂 Estrutura de Diretórios

```
core/                           # Bibliotecas base
├── env.sh                      # Variáveis globais e detecção de usuário
├── logging.sh                  # Funções de log com cores
└── package-mgr.sh              # Gerenciador de pacotes + funções auxiliares

lib/                            # Módulos de lógica principal
├── 00-detecta-distro.sh        # Detecção de distro, GPU e ambiente
├── 01-prepara-distro.sh        # Instalação de dependências + verificação de YAD
├── 02-setup-repos.sh           # Configuração de repositórios
├── 03-prepara-configs.sh       # Configurações globais + limpeza de PATH
├── 04-pack-kde.sh              # Configuração KDE/Plasma
├── 04-pack-gnome.sh            # Configuração GNOME/Budgie
├── 04-pack-xfce.sh             # Configuração XFCE
├── 04-pack-lxqt.sh             # Configuração LXQT (NOVO)
├── 04-pack-tiling-wm.sh        # Configuração Tiling WM (NOVO)
├── 04-setup-boot.sh            # Otimização de boot
├── 05-setup-sudoers.sh         # Configuração de sudo (NOVO)
├── 06-setup-shell-env.sh       # Configuração de shell (MELHORADO)
├── 07-setup-user-dirs.sh       # Diretórios e bookmarks (MELHORADO)
├── 08-setup-maintenance.sh     # Scripts de manutenção (NOVO)
├── 09-setup-fstab-mounts.sh    # Mounts de rede (NOVO)
├── 10-setup-keyboard-shortcuts.sh # Atalhos de teclado (NOVO)
├── 99-limpeza-final.sh         # Limpeza final
├── apps-data.sh                # Banco de dados de apps
├── logic-apps-reader.sh        # Motor de instalação (CORRIGIDO)
├── setup-docker.sh             # Configuração Docker
└── ui-main.sh                  # Interface gráfica

utils/                          # Utilitários do sistema
├── clean-path                  # Limpeza nuclear de PATH (NOVO)
├── diagnose-path.sh            # Diagnóstico de PATH (NOVO)
├── configs-zip.sh              # Backup de configs (CORRIGIDO)
├── restaura-config.sh          # Restauração de configs (CORRIGIDO)
├── atualiza_scripts.sh         # Atualização de scripts
└── ... (outros utilitários)

configs/                        # Arquivos de configuração
├── aliases.geral               # Aliases globais
└── ... (outros configs)

resources/                      # Recursos
├── keyboard-shortcuts/         # Backups de atalhos (NOVO)
└── ... (outros recursos)

v3rtech-install.sh             # Script principal (REORDENADO)
README.md                       # Documentação
CHANGELOG.md                    # Histórico de versões
ARCHITECTURE.md                 # Este arquivo
```

## 🔍 Fluxo de Execução Detalhado

### 1. Bootstrap (`v3rtech-install.sh`)

```bash
# Validação de privilégios
if [ "$EUID" -ne 0 ]; then
    echo "Este script deve ser executado como root"
    exit 1
fi

# Inicia loop de Sudo Keep-Alive em background
# (mantém sudo ativo durante toda a execução)

# Auto-instalação (se rodando de USB)
if [ -r /proc/cmdline ] && grep -q "boot=live" /proc/cmdline; then
    cp -r "$(pwd)" /usr/local/share/scripts/v3rtech-scripts
    exec /usr/local/share/scripts/v3rtech-scripts/v3rtech-install.sh
fi
```

### 2. Detecção e Preparação

**Passo 00: Detecção de Sistema** (`00-detecta-distro.sh`)
- Identifica distribuição (`DISTRO_FAMILY`: arch, debian, fedora)
- Detecta GPU (`GPU_VENDOR`: intel, amd, nvidia)
- Detecta ambiente (`DESKTOP_ENV`: kde, gnome, xfce, lxqt, tiling-wm)
- Exporta variáveis globais

**Passo 01: Preparação de Distro** (`01-prepara-distro.sh`)
- Instala dependências base (curl, git, yad, etc)
- **NOVO:** Verifica se YAD foi instalado com sucesso
- **NOVO:** Se falhar, tenta instalação alternativa com flags específicas
- Configura repositórios base por distro

### 3. Confirmação de Detecção

**NOVO em v3.0.0:** Após preparação, exibe diálogo YAD para confirmar detecção:
```
┌─────────────────────────────────────────┐
│ Confirmação de Sistema                  │
├─────────────────────────────────────────┤
│ Distro: Arch Linux                      │
│ Ambiente: KDE/Plasma                    │
│ GPU: Intel                              │
│                                         │
│ Está correto? [Não (Sair)] [Sim (Cont)]│
└─────────────────────────────────────────┘
```

### 4. Configuração de Repositórios e Ambiente

**Passo 02: Setup de Repositórios** (`02-setup-repos.sh`)
- Adiciona repositórios condicionais (apenas se app selecionado)
- Suporte a chaves GPG modernas
- Formato `deb822` (.sources) para Debian/Ubuntu

**Passo 03: Preparação de Configurações** (`03-prepara-configs.sh`)
- **NOVO:** Limpeza automática de PATH duplicado
- Injeta PATH global com marcadores `BEGIN`/`END`
- Injeta carregamento de aliases com marcadores
- Aplica otimizações de kernel (sysctl)
- Configura journald para limitar logs

### 5. Configuração de Desktop

**Passo 04: Instalação de Pacotes do Ambiente** (`04-pack-*.sh`)
- Detecta `$DESKTOP_ENV` e carrega script correspondente
- **NOVO:** Suporte para LXQT e Tiling WM
- Instala pacotes específicos do ambiente
- Aplica configurações visuais

**Passo 04b: Otimização de Boot** (`04-setup-boot.sh`)
- Detecta bootloader (GRUB vs Systemd-boot)
- Aplica flags de kernel
- Detecta GPU para parâmetros específicos

### 6. Configuração de Usuário

**Passo 05: Configuração de Sudo** (`05-setup-sudoers.sh` - NOVO)
- Configura sudo sem senha de forma segura
- Detecta grupo correto (sudo/wheel) por distro
- Valida arquivo sudoers antes de aplicar

**Passo 06: Configuração de Shell** (`06-setup-shell-env.sh` - MELHORADO)
- Cria/atualiza `.bashrc` com aliases úteis
- Adiciona funções auxiliares (mkcd, extract, hush)
- Exporta variáveis de ambiente (EDITOR, XDG_DATA_DIRS)
- **NOVO:** Verdadeiramente idempotente com marcadores

**Passo 07: Configuração de Diretórios** (`07-setup-user-dirs.sh` - MELHORADO)
- Cria links simbólicos para pastas de rede
- **NOVO:** Configura bookmarks GTK para gerenciadores de arquivos
- Define diretórios XDG padrão
- Configura FUSE para montagem de sistemas de arquivos

**Passo 08: Scripts de Manutenção** (`08-setup-maintenance.sh` - NOVO)
- Instala script `/usr/local/bin/up` (atualização multi-distro)
- Instala script `/usr/local/bin/upsnapshot` (manutenção com snapshot)
- Instala script `/usr/local/bin/fixperm` (correção de permissões)
- Cria timer systemd para manutenção automática

**Passo 09: Mounts de Rede** (`09-setup-fstab-mounts.sh` - NOVO)
- Adiciona mounts NFS/CIFS ao fstab
- Função `add_fstab_mount()` é idempotente
- Instala ferramentas de rede (nfs-utils, cifs-utils)

**Passo 10: Atalhos de Teclado** (`10-setup-keyboard-shortcuts.sh` - NOVO)
- Restaura atalhos por ambiente:
  - KDE: Extrai de ZIP para `~/.config/k*shortcut*`
  - GNOME: Carrega via `dconf`
  - XFCE: Extrai XML e reinicia painel
  - LXQT: Extrai de ZIP para `~/.config/lxqt/`
  - Tiling WM: Extrai de ZIP para `~/.config/`

### 7. Interface e Seleção de Apps

**Motor de Interface** (`ui-main.sh`)
- Carrega `lib/apps-data.sh` para popular lista
- Exporta variáveis para Wayland (`xhost`, `GDK_BACKEND=x11`)
- Exibe checklist YAD
- Retorna lista sanitizada de nomes selecionados

### 8. Instalação de Aplicativos

**Motor de Instalação** (`logic-apps-reader.sh` - CORRIGIDO)
- Recebe nomes selecionados
- **CORRIGIDO:** Suporta múltiplos pacotes por linha (sem aspas duplas)
- Carrega `configs/aliases.geral` para habilitar comando `i`
- Consulta mapas associativos para determinar método
- Executa instalação com tratamento de erros

### 9. Limpeza Final

**Passo 99: Limpeza Final** (`99-limpeza-final.sh`)
- Varre `/etc/apt/sources.list.d/`
- Remove `.list` duplicados se `.sources` existe
- Detecta e remove repositórios duplicados

## 📦 Definição de Aplicativos (`lib/apps-data.sh`)

Os aplicativos são definidos através da função `add_app`:

```bash
add_app "ATIVO" "CATEGORIA" "NOME" "DESCRIÇÃO" "PKG_DEB" "PKG_ARCH" "PKG_FED" "FLATPAK_ID" "METODO"
```

**Parâmetros:**
- `ATIVO`: "TRUE" ou "FALSE" (padrão na interface)
- `CATEGORIA`: Categoria de exibição (Dev, Multimedia, Office, etc)
- `NOME`: Nome exibido na interface
- `DESCRIÇÃO`: Descrição breve
- `PKG_DEB`: Nome do pacote em Debian/Ubuntu
- `PKG_ARCH`: Nome do pacote em Arch Linux
- `PKG_FED`: Nome do pacote em Fedora
- `FLATPAK_ID`: ID do Flatpak (se disponível)
- `METODO`: "native", "flatpak", "aur", "pipx"

**Exemplo:**
```bash
add_app "TRUE" "Dev" "Geany" "Editor Leve" "geany geany-plugins" "geany geany-plugins" "geany geany-plugins" "" "native"
```

## 🔄 Fluxo de Instalação de Pacotes

```
1. Usuário seleciona apps na interface YAD
2. logic-apps-reader.sh recebe nomes selecionados
3. Para cada app:
   a. Consulta APP_MAP_NATIVE[app] para pacotes nativos
   b. Consulta APP_MAP_FLATPAK[app] para Flatpak ID
   c. Determina método de instalação (native/flatpak/aur/pipx)
   d. Executa instalação via função i()
   e. Registra sucesso/falha no log
4. Após todas as instalações, executa limpeza final
```

## 🛡️ Tratamento de Erros

**Estratégia de Erro:**
- Scripts usam `set -euo pipefail` para falhar rápido
- Funções retornam código de erro apropriado
- Logs detalhados com cores para facilitar diagnóstico
- Verificações de pré-condição antes de operações críticas

**Exemplo:**
```bash
if ! command -v yad &>/dev/null; then
    log "ERROR" "YAD não foi instalado com sucesso"
    # Tenta instalação alternativa
    # Se falhar novamente, aborta com die
fi
```

## 🔐 Idempotência Implementada

**Marcadores de Bloco:**
```bash
# === V3RTECH SCRIPTS: Global PATH BEGIN ===
if [ -d "$UTILS_DIR" ]; then
    case ":$PATH:" in
        *:"$UTILS_DIR":*) ;;
        *) export PATH="$PATH:$UTILS_DIR" ;;
    esac
fi
# === V3RTECH SCRIPTS: Global PATH END ===
```

**Remoção Segura:**
```bash
# Remove bloco anterior antes de re-adicionar
sed -i '/# === V3RTECH SCRIPTS: Global PATH BEGIN ===/,/# === V3RTECH SCRIPTS: Global PATH END ===/d' "$file"
```

**Verificação Antes de Adicionar:**
```bash
if ! grep -q "# === V3RTECH SCRIPTS: Global PATH BEGIN ===" "$file"; then
    # Adiciona novo bloco
fi
```

## 🔍 Detecção de Distro

**Arquivo:** `00-detecta-distro.sh`

```bash
# Detecta família de distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        arch) DISTRO_FAMILY="arch" ;;
        debian|ubuntu|mint) DISTRO_FAMILY="debian" ;;
        fedora|rhel|centos) DISTRO_FAMILY="fedora" ;;
    esac
fi

# Detecta GPU
if lspci | grep -i nvidia &>/dev/null; then
    GPU_VENDOR="nvidia"
elif lspci | grep -i amd &>/dev/null; then
    GPU_VENDOR="amd"
else
    GPU_VENDOR="intel"
fi

# Detecta ambiente de desktop
DESKTOP_ENV=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
```

## 🧹 Limpeza de PATH (Novo em v3.0.0)

**Problema:** PATH crescia exponencialmente com múltiplas execuções.

**Solução:** Função `clean_path()` com array associativo:

```bash
clean_path() {
    local path_var="$1"
    local cleaned=""
    declare -A seen
    
    IFS=':' read -ra components <<< "$path_var"
    for component in "${components[@]}"; do
        if [ -z "$component" ]; then continue; fi
        if [ -z "${seen[$component]:-}" ]; then
            cleaned="${cleaned:+$cleaned:}$component"
            seen[$component]=1
        fi
    done
    
    echo "$cleaned"
}
```

**Uso:**
```bash
CLEANED_PATH=$(clean_path "$PATH")
export PATH="$CLEANED_PATH"
```

## 📊 Variáveis Globais Principais

| Variável | Origem | Uso |
|----------|--------|-----|
| `DISTRO_FAMILY` | `00-detecta-distro.sh` | Seleção de pacotes |
| `DESKTOP_ENV` | `00-detecta-distro.sh` | Seleção de pack-*.sh |
| `GPU_VENDOR` | `00-detecta-distro.sh` | Parâmetros de kernel |
| `REAL_USER` | `core/env.sh` | Propriedade de arquivos |
| `REAL_HOME` | `core/env.sh` | Diretório do usuário |
| `SUDO` | `core/env.sh` | Execução com privilégios |
| `INSTALL_TARGET` | `03-prepara-configs.sh` | Caminho de instalação |

## 🔗 Dependências Entre Scripts

```
v3rtech-install.sh
├── 00-detecta-distro.sh (define DISTRO_FAMILY, DESKTOP_ENV, GPU_VENDOR)
├── 01-prepara-distro.sh (instala YAD, git, curl)
├── 02-setup-repos.sh (usa DISTRO_FAMILY)
├── 03-prepara-configs.sh (usa DISTRO_FAMILY)
├── 04-pack-${DESKTOP_ENV}.sh (usa DESKTOP_ENV)
├── 04-setup-boot.sh (usa GPU_VENDOR)
├── 05-setup-sudoers.sh (usa DISTRO_FAMILY, REAL_USER)
├── 06-setup-shell-env.sh (usa REAL_USER, REAL_HOME)
├── 07-setup-user-dirs.sh (usa REAL_USER, REAL_HOME)
├── 08-setup-maintenance.sh (usa DISTRO_FAMILY)
├── 09-setup-fstab-mounts.sh (usa REAL_USER)
├── 10-setup-keyboard-shortcuts.sh (usa DESKTOP_ENV, REAL_USER, REAL_HOME)
├── ui-main.sh (carrega apps-data.sh, exibe YAD)
├── logic-apps-reader.sh (instala apps selecionados)
└── 99-limpeza-final.sh (limpeza final)
```

## 📈 Melhorias em v3.0.0

| Aspecto | Antes | Depois |
|---------|-------|--------|
| YAD não instalado | ❌ Trava | ✅ Verifica e instala |
| Múltiplos pacotes | ❌ Falha | ✅ Funciona |
| PATH duplicado | ❌ Cresce | ✅ Limpeza automática |
| Restauração de configs | ❌ Não funciona | ✅ Funciona |
| Bookmarks GTK | ❌ Não existe | ✅ Implementado |
| Mounts de rede | ❌ Não existe | ✅ Implementado |
| Atalhos de teclado | ❌ Não existe | ✅ Implementado |
| Idempotência | ⚠️ Parcial | ✅ Verdadeira |
| Ambientes suportados | 3 | 5 |

---

**Versão:** 3.0.0 | **Última atualização:** 2025-12-21
