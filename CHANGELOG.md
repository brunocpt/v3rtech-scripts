# Changelog - v3rtech-scripts

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

---


## [3.9.8] - 2026-02-05
### ✨ Adicionado
- **Apps de Produtividade:** Novos aplicativos adicionados à categoria "Escritório" em `lib/apps-data.sh`:
  - **Tesseract OCR:** Motor OCR robusto (inclui suporte completo a PDF/A via OCRmyPDF).
  - **gImageReader:** Interface gráfica completa para o Tesseract OCR (Native).
  - **TextSnatcher:** Ferramenta para extração rápida de texto a partir de imagens (Flatpak).
  - **OCRFeeder:** Suíte completa de análise de layout e OCR (Flatpak).

## [3.9.6] - 2026-01-23
### 🔧 Alterado
- **Wavebox Fix (`lib/logic-apps-reader.sh`):** Implementada correção automática para o problema de GPU compositing.
  - Adiciona a flag `--disable-gpu-compositing` ao arquivo `.desktop` global (`/usr/share/applications/wavebox.desktop`) após a instalação.
  - Garante compatibilidade com drivers NVIDIA.
  - Aplica-se a todas as ações do launcher (New Window, Incognito, etc).


## [3.9.5] - 2026-01-20
### 🔧 Alterado
- **Tradutor de Legendas (`utils/ts.sh`):**
  - **Estabilidade:** Adicionado timeout de 10 segundos nas requisições ao Google Translate para evitar travamentos indefinidos.
  - **Interface:** Removido timeout automático da janela de progresso para evitar fechamento prematuro durante traduções longas.
  - **Autodocumentação:** Adicionado cabeçalho padrão com metadados do script.

## [3.9.4] - 2026-01-20
### ✨ Adicionado
- **Tradutor de Legendas:** Novo utilitário `utils/ts.sh` que traduz legendas SRT para Português Brasileiro usando Google Translate API (sem necessidade de chave de API).
  - Suporta cache de traduções para evitar requisições repetidas.
  - Mantém formatação e timestamps do arquivo original.
  - Interface gráfica simplificada via YAD.

### 🔧 Alterado
- **Whisper Transcriber (`utils/wtt.sh`):**
  - Adicionado suporte a múltiplos formatos de saída (TXT, SRT ou Ambos).
  - Melhorada validação de arquivos de entrada.
  - Logs mais detalhados e interface de progresso aprimorada.
- **Mirror Sync (`utils/cpmirror.sh`):**
  - Mensagens de sincronização mais claras para o usuário ("Gravando dados...").
  - Aumento do timeout para leitura visual.
- **Organizador de Vídeos (`utils/cpv.sh`):**
  - Adicionada regra para ignorar a categoria "Cursos" na organização automática.

## [3.9.3] - 2026-01-15
### ✨ Adicionado
- **SendWorm:** Adicionado "SendWorm" (ferramenta de transferência de arquivos) à categoria Nuvem em `lib/apps-data.sh` (flag "FALSE" padrão).
- **Git Ignore:** Adicionado arquivo de tokens Cloudflare ao `.gitignore` para segurança.

### 🔧 Alterado
- **Dicionários Arch Linux:** Correção nos nomes dos pacotes de dicionários (hunspell, aspell, hyphen) para compatibilidade com Arch Linux em `lib/apps-data.sh`.
- **Reorganização de Apps:** Ajuste na ordem de exibição e categorias de navegadores e ferramentas de desenvolvimento.
- **BrowserOS:** Alterado para "FALSE" (desabilitado) por padrão na lista de instalação.

## [3.9.2] - 2026-01-11
### ✨ Adicionado
- **Correção Automática Pipx:** Novo script `utils/fix_pipx.sh` para detectar e corrigir ambientes virtuais quebrados (comum após atualizações do Python do sistema).
  - Detecta links simbólicos quebrados para o interpretador Python.
  - Executa `pipx reinstall-all` automaticamente se necessário.

## [3.9.1] - 2026-01-09
### ✨ Adicionado
- **BrowserOS:** Adicionado "BrowserOS" (The Open source agentic browser) à lista de aplicativos de Internet em `lib/apps-data.sh`.
- **Backup/Restore:** Suporte a BrowserOS (Nativo e Flatpak) adicionado aos scripts de backup (`utils/configs-zip.sh`) e restauração (`utils/restaura-config.sh`).

### 🔧 Alterado
- **Padrões de Navegador:** Desabilitada a instalação padrão para Vivaldi, Opera e Microsoft Edge em `lib/apps-data.sh` (flag alterada para "FALSE").
- **Permissões de Arquivo:** Padronização de permissões (remoção de bit executável desnecessário) em diversos scripts nas pastas `lib/` e `utils/`.

## [3.9.0] - 2026-01-05
### ✨ Adicionado
- **Otimização de Armazenamento:** Novo script inteligente `utils/optimize-fstab.sh` integrado ao sistema de manutenção.
  - **Btrfs:** Aplica automaticamente `compress=zstd:3`, `space_cache=v2`, `noatime` e `ssd` (se detectado disco sólido).
  - **Ext4:** Aplica `noatime`, `lazytime` e `commit=60`.
  - **Segurança:** Backup automático (`fstab.bak`) e preservação de UUIDs/Labels.
  - **Auto-elevação:** O script detecta se não é root e solicita `sudo` automaticamente.
- **Trim Automático:** Habilitação do `fstrim.timer` no módulo de manutenção para performance de SSDs.

### 🔧 Alterado
- **Script de Manutenção (`lib/08-setup-maintenance.sh`):** Agora executa o otimizador de fstab e recarrega o systemd automaticamente.

## [3.8.3] - 2026-01-05
### ✨ Adicionado
- **Suporte exFAT:** Adicionado pacote `exfatprogs` ao `lib/14-pack-essential-apps.sh` para suporte nativo a sistema de arquivos exFAT no GNOME Disks e outros utilitários.

### 🔧 Alterado
- **MusicBrainz Picard:** Dependências aprimoradas no `lib/apps-data.sh` incluindo `chromaprint` (fingerprinting), `ffmpeg` e `mp3gain` para funcionalidade completa de tagging e análise de áudio.

## [3.8.2] - 2026-01-04
### 🐛 Corrigido
- **Auto-instalação (Rsync):** Corrigido bug onde a instalação falhava em sistemas limpos (como Arch Linux minimal) devido à falta do `rsync` e da variável `DISTRO_FAMILY` não inicializada no momento da verificação. Adicionada detecção de fallback para garantir a instalação correta do rsync.

### 🔧 Alterado
- **Apps Data:** Alterado método de instalação do "Sejda PDF" de Flatpak para Native/AUR em `lib/apps-data.sh`.

## [3.8.1] - 2026-01-03
### 🔧 Corrigido
- **Permissões de Execução:** Correção massiva de permissões (+x) para scripts utilitários em `utils/` e `resources/` para garantir funcionamento correto em ambientes compartilhados.
- **Estabilização:** Validação final dos scripts `pack-icp-brasil.sh` e `pack-nvidia-wayland.sh`.

---

## [3.8.0] - 2026-01-02
### ✨ Adicionado
- **Suporte ICP-Brasil:** Novo script `utils/pack-icp-brasil.sh` para instalação universal da cadeia de certificados ICP-Brasil.
  - Compatível com Arch, Debian, Ubuntu e Fedora.
  - Instalação automática do Assinador SERPRO e Lacuna WebPKI.
  - Importação automática de certificados para keystores Java.
  - Suporte a diretórios de certificados pessoais personalizados.
- **Suporte NVIDIA Wayland Universal:** Novo script `utils/pack-nvidia-wayland.sh` para instalação robusta de drivers NVIDIA com foco em Wayland.
  - Compatível com Arch, Debian, Ubuntu, Fedora e openSUSE.
  - Detecção automática de GPU, Distro e Bootloader (GRUB, systemd-boot).
  - Configuração automática de parâmetros do Kernel (`nvidia-drm.modeset=1`) e variáveis de ambiente.
  - Configuração de `mkinitcpio` e hooks do Pacman (Arch).
- **Integração Variety Wallpaper:**
  - Instalação automática do Variety no script GNOME.
  - Configuração otimizada `configs/variety.conf` distribuída automaticamente.
- **Extensões GNOME:** Instalação automática de extensões essenciais em `lib/04-pack-gnome.sh`:
  - `dash-to-panel`, `desktop-icons-ng`, `dash-to-dock`, `tray-icons-reloaded`, `appindicator`.

### 🔧 Alterado
- **VLC no Arch Linux:** Instalação agora inclui `vlc-plugins-all` para suporte completo a codecs.
- **Correções de Caminhos:** Atualizado caminho `RC_EXCLUDE` em `configs/aliases.geral`.
- **Licenciamento Filebot:** Simplificação da lógica de aplicação de licença.
- **Limpeza GNOME:** Removida lógica legada de restauração de configs do Wavebox e Zotero.


### 🐛 Corrigido
- **Permissões de Execução:** Scripts na pasta `utils/` (`clean-path.sh`, `video-converter-gui.sh`, etc) agora têm permissão de execução (+x) por padrão.

---

## [3.7.0] - 2025-12-26
### ✨ Adicionado
- **Geany como App Essencial:** O editor Geany e seus plugins agora são instalados como parte do pacote de aplicativos essenciais em `lib/14-pack-essential-apps.sh` (Debian e Arch).

### 🔧 Alterado
- **Caminho de Chave SSH:** Atualizado o caminho da chave SSH em `configs/aliases.geral` para o novo padrão de diretórios.
- **Segurança no Script de Atualização:** `utils/atualiza_scripts.sh` agora aplica permissões mais restritivas (chmod 400/700) e garante ownership correto para o diretório de chaves copiadas.

## [3.6.0] - 2025-12-22
### 🐛 Corrigido
- **Falhas de Instalação em Debian:** Corrigido problema crítico onde aplicativos via repositórios de terceiros não eram encontrados e instalações via Flatpak falhavam em cascata.
  - *Causa:* Repositórios não eram adicionados antes da tentativa de instalação, e o Flatpak não estava configurado (faltava Flathub e overrides).
  - *Solução:* Reordenamento da sequência de execução e criação de novos scripts dedicados.

### ✨ Adicionado
- **Script `lib/03-setup-flatpak.sh`:** Novo módulo dedicado à configuração completa do Flatpak.
  - Verifica se o Flatpak está instalado (e instala se necessário).
  - Adiciona o repositório Flathub.
  - Aplica overrides globais para acesso ao sistema de arquivos.
  - Executa ANTES de qualquer tentativa de instalação de apps Flatpak.
- **Suporte a Repositório Mozilla Firefox:** Adicionado repositório oficial do Mozilla ao script lib/02-setup-repos.sh.

### 🔧 Alterado
- **Sequência de Instalação Principal (v3rtech-install.sh):**
  - Repositórios de terceiros agora são adicionados ANTES do carregamento do banco de dados de apps.
  - Configuração do Flatpak agora é executada IMEDIATAMENTE APÓS os repositórios.
  - Banco de dados de apps é carregado APÓS todas as fontes estarem configuradas.
- **Função `install_flatpak()` em `core/package-mgr.sh`:**
  - Removida lógica de instalação de Flatpak e configuração de Flathub.
  - Simplificada para apenas instalar o app especificado.

  
## [3.5.0] - 2025-12-21 (Sessão 5 - Boot Options Multi-Distro)

### ✨ Adicionado

#### Boot Options Multi-Distro
- **Configuração de Boot Options** em `03-prepara-configs.sh`:
  - **Debian/Ubuntu:** Configuração GRUB com opções otimizadas
  - **Arch Linux:** Configuração systemd-boot com opções otimizadas
  - **Fedora:** Configuração GRUB2 com opções otimizadas
  - **Opções Aplicadas:**
    - `quiet` - Suprime mensagens de boot
    - `splash` - Mostra splash screen
    - `loglevel=0` - Suprime logs do kernel
    - `systemd.show_status=false` - Suprime status do systemd
    - `rd.udev.log_level=0` - Suprime logs do udev
    - `zswap.enabled=1` - Ativa compressão de swap
  - Backup automático de `/etc/default/grub`
  - Regeneração automática de configuração de boot

### 🔧 Corrigido

#### Bug 19: Plymouth Não Instalado em Arch/Fedora
- **Problema:** Script só instalava Plymouth para Debian/Ubuntu
- **Solução:** Implementada função `install_plymouth()` com suporte multi-distro
- **Impacto:** Agora Plymouth funciona em todas as distribuições suportadas

#### Bug 20: Boot Options Não Configuradas em Debian/Ubuntu/Fedora
- **Problema:** Boot options só eram configuradas no Arch Linux
- **Solução:** Implementadas funções `configure_grub_boot_options()` e `configure_grub2_boot_options()`
- **Impacto:** Agora boot é otimizado em todas as distribuições

---

## [3.4.0] - 2025-12-21 (Sessão 4 - Certificados Digitais)

### ✨ Adicionado

#### Certificados Digitais e ICP-Brasil
- **Script `12-pack-certificates.sh`** (NOVO): Instalação de certificados digitais e ferramentas ICP-Brasil com:
  - Instalação de certificados (suporta .crt, .pem, .cer)
  - Ferramentas de token/smartcard (pcsc-lite, opensc)
  - Assinador SERPRO (Debian/Ubuntu e Arch)
  - PyHanko para assinatura de PDFs (opcional)
  - Pós-instalação (pcscd)
  - Suporte multi-distro (Arch, Debian, Fedora)
- **Script `test-pack-certificates-STANDALONE.sh`** (NOVO): Versão standalone para testes independentes com:
  - Menu interativo
  - Modo linha de comando
  - Diagnóstico automático
  - Sem dependências externas

---

## [3.3.0] - 2025-12-21 (Sessão 3 - Whisper e Filebot Finalizados)

### ✨ Adicionado

#### Whisper - Instalação Especializada
- **Script `11-setup-whisper.sh`** (NOVO): Instalação profissional de OpenAI Whisper com:
  - Detecção automática de GPU (NVIDIA, AMD, CPU)
  - Limpeza de instalações anteriores
  - Injeção de CUDA para NVIDIA
  - Link simbólico em `/usr/bin/whisper`
  - Suporte multi-distro

#### Filebot - Configuração Pós-Instalação
- **Função `post_install_filebot()`**: Configuração automática após instalação:
  - Aplicação de licença via stdin
  - Configuração de OpenSubtitles v2
  - Configuração de credenciais OpenSubtitles
  - Arquivo `configs/filebot-osdb.conf` para credenciais seguras

#### Flatpak - Configurações Globais
- **Função `configure_flatpak_global()`**: Permissões padrão para todos os Flatpaks:
  - Acesso a temas do sistema
  - Acesso a configurações GTK
  - Acesso a pastas de trabalho
  - Acesso a scripts locais
  - Permissões de bus (notificações, tray)

### 🔧 Corrigido

#### Bug 17: Licença do Filebot Não Aplicada
- **Problema:** Comando `--license /arquivo` não funcionava
- **Solução:** Usar `cat arquivo | flatpak run ... --license`
- **Impacto:** Licença agora é aplicada corretamente

#### Bug 18: Whisper Não Instalado Corretamente
- **Problema:** Instalação simplista sem suporte a GPU
- **Solução:** Script especializado com detecção de GPU e injeção de CUDA
- **Impacto:** Whisper agora funciona com aceleração de GPU

---

## [3.2.0] - 2025-12-21 (Sessão 2 - Correções Finais)

### ✨ Adicionado

#### Desktop Entries
- **Integração em `03-prepara-configs.sh`**: Criação automática de `.desktop` files para:
  - Instalador de Metapacks Flatpaks
  - Copiador de Pastas (cpa)
  - Copiador de Playlists (cpplay)
  - Atualizador de Aplicativos (upall)
  - Whisper Transcriber (wtt)
  - Extrai Legendas
  - Conversor de Vídeos
  - Restaurador de Configurações
  - Backup de Configurações

#### Mounts de Rede Dinâmicos
- **Extração dinâmica de pontos de montagem** do arquivo `fstab.lan`
- **Criação automática de diretórios** baseado em mounts
- **Suporte a hostnames** em vez de IPs (via `configs/hosts`)
- **Flexibilidade:** Adicionar novo mount apenas editando `fstab.lan`

#### Proteção contra Loops de Symlinks
- **Função `create_safe_symlink()`**: Detecção de loops circulares
- **Resolução de caminhos reais** antes de criar links
- **Avisos informativos** se loop for detectado

### 🔧 Corrigido

#### Bug 8: Cópia Incompleta de Arquivos
- **Problema:** `cp -r "$DIR/"*` não copia arquivos ocultos
- **Solução:** Usar `rsync -av --delete` com mirror
- **Impacto:** Todos os arquivos (incluindo configs) são copiados

#### Bug 9: Diretórios Hardcoded
- **Problema:** Diretórios de rede criados manualmente no script
- **Solução:** Extração dinâmica do arquivo `fstab.lan`
- **Impacto:** Fácil adicionar/remover mounts

#### Bug 10: Expansão de Brace com Sudo
- **Problema:** `$SUDO mkdir -p /mnt/{a,b,c}` não funciona
- **Solução:** Usar `$SUDO bash -c 'mkdir -p /mnt/{a,b,c}'`
- **Impacto:** Diretórios criados corretamente

#### Bug 11: Bookmarks Não Copiados
- **Problema:** Script criava bookmarks hardcoded em vez de copiar arquivo
- **Solução:** Copiar arquivo `configs/bookmarks` se existir
- **Impacto:** Bookmarks personalizados agora são aplicados

#### Bug 12: Variável `$INSTALL_TARGET` Não Definida
- **Problema:** Variável local não acessível em outros scripts
- **Solução:** Usar `$BASE_DIR` que é exportada globalmente
- **Impacto:** Scripts agora encontram arquivos de configuração

#### Bug 13: Loop de Symlinks
- **Problema:** Link simbólico apontando para dentro de si mesmo
- **Solução:** Detecção de loops antes de criar links
- **Impacto:** Navegadores de arquivos não mais travam

#### Bug 14: PATH Duplicado Exponencialmente
- **Problema:** Múltiplas linhas `export PATH=` causavam crescimento exponencial
- **Solução:** Função `clean_path()` com marcadores de bloco
- **Impacto:** PATH limpo e idempotente

#### Bug 15: Restauração de Configurações Não Funcionava
- **Problema:** Script não extraía ZIPs de backup
- **Solução:** Adicionar verificação de arquivo e tratamento de erro
- **Impacto:** Configurações agora são restauradas corretamente

#### Bug 16: Arquivo Bash.bashrc Corrompido
- **Problema:** Múltiplas execuções criavam duplicatas de blocos
- **Solução:** Usar marcadores de bloco para remoção precisa
- **Impacto:** Bash.bashrc agora é idempotente

### 📊 Funcionalidades Adicionadas

- Rsync mirror para sincronização completa
- Extração dinâmica de mounts de rede
- Desktop entries para scripts utilitários
- Pós-instalação automática de Filebot
- Configurações globais de Flatpak
- Proteção contra loops de symlinks
- Arquivo de credenciais seguro para OpenSubtitles
- Suporte a hostnames em vez de IPs

---

## [3.1.0] - 2025-12-21 (Sessão 1 - Correções Iniciais)

### ✨ Adicionado

#### Novos Scripts
- **05-setup-sudoers.sh** (NOVO): Configuração de sudo sem senha
- **06-setup-shell-env.sh** (NOVO): Configuração de shell e aliases
- **07-setup-user-dirs.sh** (NOVO): Configuração de diretórios do usuário
- **08-setup-maintenance.sh** (NOVO): Scripts de manutenção e timers
- **09-setup-fstab-mounts.sh** (NOVO): Configuração de mounts de rede
- **10-setup-keyboard-shortcuts.sh** (NOVO): Restauração de atalhos de teclado

#### Ambientes de Desktop Suportados
- **04-pack-lxqt.sh** (NOVO): Suporte a LXQT
- **04-pack-tiling-wm.sh** (NOVO): Suporte a Tiling Window Managers

#### Funcionalidades Portadas
- Configuração de sudo sem senha (idempotente)
- Aliases globais com proteção contra duplicação
- Criação de diretórios de trabalho
- Links simbólicos para pastas de rede
- Bookmarks GTK para navegadores
- Scripts de manutenção e timers systemd
- Restauração de atalhos de teclado (KDE, GNOME, XFCE, LXQT, Tiling WM)
- Configuração de FUSE para montagem de sistemas de arquivos

### 🔧 Corrigido

#### Bug 1: YAD Não Instalado
- **Problema:** Script tentava usar YAD antes de instalar
- **Solução:** Mover `01-prepara-distro.sh` ANTES da confirmação visual
- **Impacto:** YAD agora está disponível quando necessário

#### Bug 2: Scripts de Desktop Não Chamados
- **Problema:** Scripts como `04-pack-kde.sh` não eram executados
- **Solução:** Verificar existência de arquivo antes de carregar
- **Impacto:** Ambientes de desktop agora são configurados

#### Bug 3: Pacotes Múltiplos Não Instalados
- **Problema:** `geany geany-plugins` era tratado como um pacote único
- **Solução:** Remover aspas para permitir expansão de espaços
- **Impacto:** Múltiplos pacotes agora são instalados corretamente

#### Bug 4: Função `restore_zip_config` Não Definida
- **Problema:** Função usada mas nunca implementada
- **Solução:** Implementar função em `core/package-mgr.sh`
- **Impacto:** Restauração de configurações agora funciona

#### Bug 5: Pacotes Incompletos
- **Problema:** Scripts de desktop com lista mínima de pacotes
- **Solução:** Expandir lista com pacotes essenciais
- **Impacto:** Ambientes agora têm todas as ferramentas necessárias

#### Bug 6: Bash.bashrc Duplicado
- **Problema:** Múltiplas execuções criavam duplicatas
- **Solução:** Usar marcadores de bloco para remoção precisa
- **Impacto:** Bash.bashrc agora é idempotente

#### Bug 7: Funcionalidades Não Portadas
- **Problema:** Funcionalidades dos scripts antigos não foram integradas
- **Solução:** Criar novos scripts para cada funcionalidade
- **Impacto:** Todas as funcionalidades antigas agora estão disponíveis

### 📊 Funcionalidades Adicionadas

- Instalação idempotente de YAD
- Suporte a múltiplos pacotes por linha
- Restauração de configurações com backup
- Configuração de sudo sem senha
- Aliases globais
- Diretórios de trabalho
- Links simbólicos para rede
- Bookmarks GTK
- Scripts de manutenção
- Atalhos de teclado por ambiente
- Suporte a LXQT e Tiling WM

---

## [3.0.0] - 2025-12-21 (Análise Inicial)

### 📋 Resumo

Análise completa do projeto v3rtech-scripts para identificação de bugs e oportunidades de melhoria. Documentação de arquitetura, fluxo de execução e padrões de código.

### ✨ Documentação Criada

- **ARCHITECTURE.md**: Documentação técnica detalhada
- **README.md**: Guia de uso e funcionalidades
- **CHANGELOG.md**: Histórico de mudanças

---

## [2.0.0] - 2025-12-20

### 💥 Mudanças de Arquitetura (Breaking Changes)

- **Migração de Banco de Dados:** Substituição do arquivo `data/apps.csv` pelo script nativo `lib/apps-data.sh`.
  - *Motivo:* Eliminar falhas de parsing de texto/quebras de linha, permitir comentários no código e facilitar a manutenção.
- **Estrutura de Diretórios:** Padronização do diretório de configurações para `configs/` (plural) em todo o projeto.
- **Lógica de Instalação:** A função `sys_install` foi completamente depreciada em favor do alias `i` e da função `install_app_by_name`.

### ✨ Adicionado

- **Persistência Global de Ambiente:** O script `03-prepara-configs.sh` agora injeta configurações de `PATH` e carregamento de `aliases` diretamente em `/etc/bash.bashrc`. Isso garante que o comando `i` e outros utilitários funcionem para todos os usuários e persistam após o reboot.
- **Script de Limpeza Final (`99-limpeza-final.sh`):** Novo módulo executado ao final da instalação para detectar e remover repositórios duplicados (ex: `.list` vs `.sources`) gerados automaticamente por instaladores de pacotes como Edge, Vivaldi e VS Code.
- **Suporte a Debian Sid/Forky:** Atualização dos nomes de pacotes no banco de dados para compatibilidade com o ramo instável (ex: `7zip` em vez de `p7zip-full`, `docker-compose-plugin` em vez de `docker-compose`).
- **Suporte a Wayland:** Implementada exportação de `GDK_BACKEND=x11` e `xhost` para permitir que o script (rodando como root) exiba janelas gráficas (YAD) em sessões Wayland (KDE/GNOME modernos).

### 🛠️ Corrigido

- **Bug de Interface (YAD):** Corrigido erro onde apenas o primeiro aplicativo da lista era instalado. Implementada sanitização de quebras de linha (`tr '\n' '|'`) no retorno da seleção gráfica.
- **Expansão de Aliases:** Scripts `logic-apps-reader.sh` e `ui-main.sh` agora forçam `shopt -s expand_aliases` e carregam `configs/aliases.geral` para reconhecer o comando de instalação `i` internamente.
- **Script de Atualização (`utils/atualiza_scripts.sh`):** Refatorado para suportar a nova estrutura de pastas (`configs`, `utils`) e adicionado fallback automático para GitHub caso a montagem de rede local não esteja disponível.

---

## [1.6.0] - 2025-10-25

### ✨ Adicionado

- **Auto-Instalação (Persistência):** O script mestre agora detecta se está rodando de uma mídia removível (USB) e se copia automaticamente para `/usr/local/share/scripts/v3rtech-scripts` antes de prosseguir.
- **Hook de Virtualização:** Novo módulo `lib/13-pack-vm.sh` que instala e configura o VirtualBox, Extension Pack (com aceite de licença automático no Debian) e adiciona o usuário ao grupo `vboxusers`.
- **Validação de Distro:** Adicionado diálogo YAD para confirmação explícita do usuário sobre a detecção do sistema (Distro/Ambiente/GPU) antes de iniciar as modificações.

### 🔄 Alterado

- **Fluxo do Script Mestre:** O script `v3rtech-install.sh` foi reordenado para chamar o hook de VM ao final e realizar a auto-cópia no início.

---

## [1.5.0] - 2025-10-25

### ✨ Adicionado

- **Módulos de Ambiente Desktop:** Criação de scripts dedicados (`lib/04-pack-*.sh`) para configurar ambientes específicos:
  - **GNOME:** Configurações do GSettings, Wavebox e Zotero.
  - **KDE Plasma:** Instalação de plugins Dolphin, Ark, Kate e restauração de configs do Falkon.
  - **XFCE:** Configuração via `xfconf-query`, helpers.rc e plugins Thunar.
- **Detecção de Ambiente:** O script `00-detecta-distro.sh` agora identifica `$XDG_CURRENT_DESKTOP` para carregar o módulo de configuração correto.

---

## [1.2.0] - 2025-10-24

### ✨ Adicionado

- **Módulo de Otimização de Boot (`04-setup-boot.sh`):**
  - Detecção de Bootloader (GRUB vs Systemd-boot).
  - Aplicação de flags de Kernel (`quiet`, `loglevel=0`, `ipv6.disable=1`).
  - Detecção de GPU (Intel/AMD/Nvidia) para aplicação de parâmetros específicos (`nvidia-drm.modeset=1`).
  - Backup automático de configurações de boot antes da edição.

---

## [1.1.0] - 2025-10-23

### ✨ Adicionado

- **Gestão de Repositórios (`02-setup-repos.sh`):**
  - Lógica condicional: Adiciona repositórios (VS Code, Chrome, Wavebox) *apenas* se o app estiver marcado para instalação.
  - Suporte a chaves GPG modernas e formato `deb822` (.sources) para Debian/Ubuntu.
  - Configuração de RPM Fusion para Fedora.
- **Banco de Dados CSV:** Expansão do `data/apps.csv` para incluir categorias de Impressão, Design, Multimídia e ferramentas de Desenvolvimento.

---

## [1.0.0] - 2025-10-23

### 🎯 Inicialização

- **Arquitetura Modular:** Definição da estrutura de pastas (`core/`, `lib/`, `data/`, `configs/`).
- **Core:** Implementação das bibliotecas base:
  - `logging.sh`: Cores e formatação de logs.
  - `env.sh`: Variáveis globais e detecção de usuário.
  - `package-mgr.sh`: Abstração de gerenciadores de pacotes (`apt`, `dnf`, `pacman`).

---

## 📊 Estatísticas Finais

| Métrica | Total |
|---------|-------|
| Bugs Corrigidos | **22** |
| Novos Scripts | **15** |
| Scripts Melhorados | **15** |
| Novas Funcionalidades | **26** |
| Documentos Criados | **14** |
| Versões Lançadas | **9** |

---

**Versão Atual:** 3.9.6  
**Status:** ✅ Estável  
**Última Atualização:** 2026-01-23  
**Desenvolvedor:** Bruno (v3rtech)
