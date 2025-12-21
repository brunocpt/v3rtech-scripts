# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

## [3.0.0] - 2025-12-21
### 💥 Mudanças Críticas (Breaking Changes)
- **Reordenação de Execução:** O script `01-prepara-distro.sh` agora é executado ANTES da confirmação visual (YAD), garantindo que YAD esteja instalado antes de ser usado.
- **Idempotência Verdadeira:** Todos os scripts agora usam marcadores de bloco (`BEGIN`/`END`) para remoção segura de conteúdo anterior, permitindo execução múltipla sem duplicação.

### ✨ Adicionado

#### Core & Infraestrutura
- **Função `clean_path()`** em `core/package-mgr.sh`: Remove entradas duplicadas do PATH usando array associativo.
- **Verificação Crítica de YAD** em `01-prepara-distro.sh`: Se YAD não for instalado na primeira tentativa, tenta instalação alternativa com flags específicas por distro.
- **Script `clean-path-NUCLEAR.sh`**: Utilitário standalone que remove TODAS as linhas de PATH duplicadas e injeta uma única linha limpa (resolve problema de PATH crescimento exponencial).
- **Script `diagnose-path.sh`**: Ferramenta de diagnóstico que encontra todas as linhas que modificam PATH em múltiplos arquivos.

#### Configuração de Ambiente
- **Script `05-setup-sudoers.sh`** (NOVO): Configura sudo sem senha de forma segura, detectando distro e usando grupo correto (sudo/wheel).
- **Script `06-setup-shell-env.sh`** (MELHORADO): Configuração idempotente de `.bashrc` com aliases úteis, funções auxiliares (mkcd, extract, hush) e PATH global.
- **Script `07-setup-user-dirs.sh`** (MELHORADO): 
  - Cria links simbólicos para pastas de rede estratégicas
  - Configura bookmarks GTK para gerenciadores de arquivos (Nautilus, Thunar, etc)
  - Define diretórios XDG padrão
  - Configura FUSE para montagem de sistemas de arquivos
- **Script `08-setup-maintenance.sh`** (NOVO): Scripts de manutenção do sistema:
  - `/usr/local/bin/up` - Atualização multi-distro
  - `/usr/local/bin/upsnapshot` - Manutenção completa com snapshot
  - `/usr/local/bin/fixperm` - Correção de permissões
  - Timer systemd para manutenção automática
  - Otimizações de sysctl e journald

#### Configuração de Desktop
- **Script `04-pack-kde.sh`** (MELHORADO): Pacotes expandidos com plasma-meta, kio-extras, dolphin, konsole, okular, kcalc, kdeconnect, kaccounts-providers.
- **Script `04-pack-gnome.sh`** (MELHORADO): Pacotes expandidos com gnome-shell-extensions, nautilus, evolution, gedit, gnome-calendar.
- **Script `04-pack-xfce.sh`** (MELHORADO): Pacotes expandidos com xfce4-whiskermenu, thunar-media-tags, xfce4-appfinder.
- **Script `04-pack-lxqt.sh`** (NOVO): Suporte completo para LXQT com lxqt-core, pcmanfm-qt, lxqt-panel, lxqt-runner.
- **Script `04-pack-tiling-wm.sh`** (NOVO): Suporte para Tiling Window Managers (i3, sway, etc) com i3-wm, sway, dmenu, rofi.
- **Script `09-setup-fstab-mounts.sh`** (NOVO): Configura mounts de rede (NFS/CIFS) no fstab com função idempotente `add_fstab_mount()`.
- **Script `10-setup-keyboard-shortcuts.sh`** (NOVO): Restaura atalhos de teclado personalizados por ambiente:
  - KDE/Plasma: Restaura de ZIP para `~/.config/k*shortcut*`
  - GNOME/Budgie: Restaura via `dconf` para `/org/gnome/settings-daemon/plugins/media-keys/`
  - XFCE: Restaura XML e reinicia painel com `xfce4-panel -r`
  - LXQT: Restaura de ZIP para `~/.config/lxqt/`
  - Tiling WM: Restaura de ZIP para `~/.config/` (i3, sway, etc)

#### Utilitários
- **Função `restore_zip_config()`** em `core/package-mgr.sh`: Restaura configurações de arquivos ZIP com tratamento de erro robusto.
- **Script `clean-path.sh`** (DEFINITIVO): Remove todas as linhas de PATH e injeta uma única linha limpa (multi-arquivo).
- **Script `03-prepara-configs.sh`** (FINAL): Limpeza automática de PATH duplicado + configuração idempotente com marcadores de bloco.

### 🛠️ Corrigido

#### Bugs Críticos
1. **Bug do YAD não instalado** (CRÍTICO):
   - **Problema:** Script tentava usar YAD antes de instalar
   - **Solução:** Reordenado `01-prepara-distro.sh` para ANTES da confirmação visual
   - **Verificação:** Adicionado bloco de verificação crítica com instalação alternativa

2. **Bug de Múltiplos Pacotes** (CRÍTICO):
   - **Problema:** `i "geany geany-plugins"` falhava porque passava como string única
   - **Solução:** Removidas aspas duplas em `logic-apps-reader.sh` linha 105: `i $pkg_native`
   - **Resultado:** Agora suporta múltiplos pacotes corretamente

3. **Bug de Scripts de Desktop não Chamados** (CRÍTICO):
   - **Problema:** Scripts `04-pack-*.sh` não eram chamados para LXQT e Tiling WM
   - **Solução:** Criados scripts faltantes (`04-pack-lxqt.sh`, `04-pack-tiling-wm.sh`)
   - **Verificação:** Estrutura de if/case garante chamada correta por `$DESKTOP_ENV`

4. **Bug de PATH Duplicado Exponencial** (CRÍTICO):
   - **Problema:** PATH crescia exponencialmente a cada novo shell (39 → 44 → 50 entradas)
   - **Causa:** 3 linhas `export PATH="$PATH:..."` em `~/.bashrc` criavam efeito cascata
   - **Solução:** Script `clean-path-NUCLEAR.sh` remove TODAS as linhas e injeta uma única
   - **Prevenção:** `03-prepara-configs.sh` usa marcadores `BEGIN`/`END` para idempotência

5. **Bug de Restauração de Configurações** (MÉDIO):
   - **Problema:** `restaura-config.sh` não restaurava nada, não registrava erros
   - **Causa:** Script só restaurava se aplicativo estava instalado
   - **Solução:** Removida verificação de instalação, tenta restaurar sempre
   - **Resultado:** Agora restaura configurações mesmo sem app instalado

6. **Bug de Arquivo Bash.bashrc Corrompido** (MÉDIO):
   - **Problema:** `06-setup-shell-env.sh` adicionava múltiplas vezes, criando `esac` e `fi` soltos
   - **Solução:** Implementado sistema de marcadores para remoção segura antes de re-adicionar
   - **Idempotência:** Pode ser executado múltiplas vezes com segurança

#### Bugs em Scripts Utilitários
7. **Bug em `configs-zip.sh`** (MÉDIO):
   - Sem verificação de erro no `zip` - agora valida sucesso
   - Faltavam `killall` para 8 aplicativos (Ferdium, Obsidian, VSCode, etc)
   - Tintero sem tratamento nativo - agora suporta ambas versões
   - Mensagem errada para Opera - agora corrigida
   - Variável `$YAD_PID` não escapada - agora usa `"$YAD_PID"`

8. **Bug de Funcionalidades Não Portadas** (MÉDIO):
   - Bookmarks GTK não implementados - adicionados em `07-setup-user-dirs.sh`
   - Mounts de rede não implementados - novo script `09-setup-fstab-mounts.sh`
   - Atalhos de teclado não implementados - novo script `10-setup-keyboard-shortcuts.sh`

### 📋 Melhorias

#### Idempotência
- Todos os scripts agora usam marcadores de bloco (`# === V3RTECH SCRIPTS: ... BEGIN ===` / `END`) para remoção segura
- Função `clean_path()` implementada com array associativo para evitar duplicatas
- Scripts podem ser executados múltiplas vezes com segurança

#### Multi-Distro
- Todas as correções testadas/validadas para Arch, Debian/Ubuntu e Fedora
- Detecção automática de distro em todos os scripts
- Tratamento específico por distro onde necessário

#### Tratamento de Erros
- Adicionadas verificações de sucesso em operações críticas
- Logging detalhado com cores e emojis
- Scripts abortam com mensagem clara em caso de erro

#### Documentação
- Criados documentos detalhados para cada correção
- Guias de diagnóstico e troubleshooting
- Exemplos práticos de uso

### 📁 Estrutura de Diretórios Atualizada

```
v3rtech-scripts/
├── core/
│   ├── env.sh
│   ├── logging.sh
│   └── package-mgr.sh (com clean_path() e restore_zip_config())
├── lib/
│   ├── 00-detecta-distro.sh
│   ├── 01-prepara-distro.sh (com verificação crítica de YAD)
│   ├── 02-setup-repos.sh
│   ├── 03-prepara-configs.sh (com clean_path() e marcadores)
│   ├── 04-pack-kde.sh (melhorado)
│   ├── 04-pack-gnome.sh (melhorado)
│   ├── 04-pack-xfce.sh (melhorado)
│   ├── 04-pack-lxqt.sh (NOVO)
│   ├── 04-pack-tiling-wm.sh (NOVO)
│   ├── 04-setup-boot.sh
│   ├── 05-setup-sudoers.sh (NOVO)
│   ├── 06-setup-shell-env.sh (melhorado)
│   ├── 07-setup-user-dirs.sh (melhorado)
│   ├── 08-setup-maintenance.sh (NOVO)
│   ├── 09-setup-fstab-mounts.sh (NOVO)
│   ├── 10-setup-keyboard-shortcuts.sh (NOVO)
│   ├── 99-limpeza-final.sh
│   ├── apps-data.sh
│   ├── logic-apps-reader.sh (corrigido)
│   ├── setup-docker.sh
│   └── ui-main.sh
├── utils/
│   ├── restaura-config.sh (corrigido)
│   ├── configs-zip.sh (corrigido)
│   ├── clean-path (NOVO - utilitário nuclear)
│   ├── diagnose-path.sh (NOVO - diagnóstico)
│   └── ... (outros utilitários)
├── configs/
│   ├── aliases.geral
│   └── ... (arquivos de configuração)
├── resources/
│   ├── keyboard-shortcuts/ (NOVO - para backups de atalhos)
│   └── ... (outros recursos)
├── v3rtech-install.sh (reordenado)
├── README.md
├── CHANGELOG.md (este arquivo)
└── ARCHITECTURE.md
```

### 🧪 Testes Realizados

- ✅ Arch Linux com KDE (ambiente de teste principal)
- ✅ Múltiplas execuções do script (idempotência)
- ✅ PATH com 39 entradas duplicadas → limpeza bem-sucedida
- ✅ Instalação de múltiplos pacotes (ex: `geany geany-plugins`)
- ✅ Restauração de configurações sem app instalado
- ✅ Limpeza de bash.bashrc corrompido

### 📝 Notas de Migração

Para usuários atualizando de versões anteriores:

1. **Backup Recomendado:**
   ```bash
   cp ~/.bashrc ~/.bashrc.backup
   cp /etc/bash.bashrc /etc/bash.bashrc.backup
   ```

2. **Limpar PATH Duplicado (se necessário):**
   ```bash
   ./utils/clean-path --dry-run
   ./utils/clean-path
   ```

3. **Executar Script Atualizado:**
   ```bash
   ./v3rtech-install.sh
   ```

4. **Verificar Integridade:**
   ```bash
   ./utils/diagnose-path.sh
   echo $PATH | tr ':' '\n' | sort | uniq -d  # Deve estar vazio
   ```

---

## [2.0.0] - 2025-12-20
### 💥 Mudanças de Arquitetura (Breaking Changes)
- **Migração de Banco de Dados:** Substituição do arquivo `data/apps.csv` pelo script nativo `lib/apps-data.sh`.
    - *Motivo:* Eliminar falhas de parsing de texto/quebras de linha, permitir comentários no código e facilitar a manutenção.
- **Estrutura de Diretórios:** Padronização do diretório de configurações para `configs/` (plural) em todo o projeto.
- **Lógica de Instalação:** A função `sys_install` foi completamente depreciada em favor do alias `i` e da função `install_app_by_name`.

### ✨ Adicionado
- **Persistência Global de Ambiente:** O script `03-prepara-configs.sh` agora injeta configurações de `PATH` e carregarmento de `aliases` diretamente em `/etc/bash.bashrc`. Isso garante que o comando `i` e outros utilitários funcionem para todos os usuários e persistam após o reboot.
- **Script de Limpeza Final (`99-limpeza-final.sh`):** Novo módulo executado ao final da instalação para detectar e remover repositórios duplicados (ex: `.list` vs `.sources`) gerados automaticamente por instaladores de pacotes como Edge, Vivaldi e VS Code.
- **Suporte a Debian Sid/Forky:** Atualização dos nomes de pacotes no banco de dados para compatibilidade com o ramo instável (ex: `7zip` em vez de `p7zip-full`, `docker-compose-plugin` em vez de `docker-compose`).
- **Suporte a Wayland:** Implementada exportação de `GDK_BACKEND=x11` e `xhost` para permitir que o script (rodando como root) exiba janelas gráficas (YAD) em sessões Wayland (KDE/GNOME modernos).

### 🛠️ Corrigido
- **Bug de Interface (YAD):** Corrigido erro onde apenas o primeiro aplicativo da lista era instalado. Implementada sanitização de quebras de linha (`tr '\n' '|'`) no retorno da seleção gráfica.
- **Expansão de Aliases:** Scripts `logic-apps-reader.sh` e `ui-main.sh` agora forçam `shopt -s expand_aliases` e carregam `configs/aliases.geral` para reconhecer o comando de instalação `i` internamente.
- **Script de Atualização (`utils/atualiza_scripts.sh`):** Refatorado para suportar a nova estrutura de pastas (`configs`, `utils`) e adicionado fallback automático para GitHub caso a montagem de rede local não esteja disponível.

---

## [1.6.0] - 2025-10-25
### Adicionado
- **Auto-Instalação (Persistência):** O script mestre agora detecta se está rodando de uma mídia removível (USB) e se copia automaticamente para `/usr/local/share/scripts/v3rtech-scripts` antes de prosseguir.
- **Hook de Virtualização:** Novo módulo `lib/13-pack-vm.sh` que instala e configura o VirtualBox, Extension Pack (com aceite de licença automático no Debian) e adiciona o usuário ao grupo `vboxusers`.
- **Validação de Distro:** Adicionado diálogo YAD para confirmação explícita do usuário sobre a detecção do sistema (Distro/Ambiente/GPU) antes de iniciar as modificações.

### Alterado
- **Fluxo do Script Mestre:** O script `v3rtech-install.sh` foi reordenado para chamar o hook de VM ao final e realizar a auto-cópia no início.

---

## [1.5.0] - 2025-10-25
### Adicionado
- **Módulos de Ambiente Desktop:** Criação de scripts dedicados (`lib/04-pack-*.sh`) para configurar ambientes específicos:
    - **GNOME:** Configurações do GSettings, Wavebox e Zotero.
    - **KDE Plasma:** Instalação de plugins Dolphin, Ark, Kate e restauração de configs do Falkon.
    - **XFCE:** Configuração via `xfconf-query`, helpers.rc e plugins Thunar.
- **Detecção de Ambiente:** O script `00-detecta-distro.sh` agora identifica `$XDG_CURRENT_DESKTOP` para carregar o módulo de configuração correto.

---

## [1.2.0] - 2025-10-24
### Adicionado
- **Módulo de Otimização de Boot (`04-setup-boot.sh`):**
    - Detecção de Bootloader (GRUB vs Systemd-boot).
    - Aplicação de flags de Kernel (`quiet`, `loglevel=0`, `ipv6.disable=1`).
    - Detecção de GPU (Intel/AMD/Nvidia) para aplicação de parâmetros específicos (`nvidia-drm.modeset=1`).
    - Backup automático de configurações de boot antes da edição.

---

## [1.1.0] - 2025-10-23
### Adicionado
- **Gestão de Repositórios (`02-setup-repos.sh`):**
    - Lógica condicional: Adiciona repositórios (VS Code, Chrome, Wavebox) *apenas* se o app estiver marcado para instalação.
    - Suporte a chaves GPG modernas e formato `deb822` (.sources) para Debian/Ubuntu.
    - Configuração de RPM Fusion para Fedora.
- **Banco de Dados CSV:** Expansão do `data/apps.csv` para incluir categorias de Impressão, Design, Multimídia e ferramentas de Desenvolvimento.

---

## [1.0.0] - 2025-10-23
### Inicialização
- **Arquitetura Modular:** Definição da estrutura de pastas (`core/`, `lib/`, `data/`, `configs/`).
- **Core:** Implementação das bibliotecas base:
    - `logging.sh`: Cores e formatação de logs.
    - `env.sh`: Variáveis globais e detecção de usuário.
    - `package-mgr.sh`: Abstração de gerenciadores de pacotes (`apt`, `dnf`, `pacman`).
