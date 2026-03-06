# Changelog - V3RTECH Scripts

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

---

## [6.0.0] - 2026-03-06

### ✨ Paralelismo e Orquestração de Performance (e Hotfix de Instalação)

- **core/package-mgr.sh:**
    - **Bug Fix:** Corrigida falha na instalação de múltiplos pacotes (ex: `libreoffice-fresh`) no Arch Linux. As funções `i()`, `r()` e `is_installed()` agora tratam corretamente strings com espaços, dividindo-as em argumentos individuais para o `paru`/`pacman`.
- **utils/cpv.sh (v6.0.0) & utils/cpd.sh (v5.0.0):** 
    - Implementação de **Transferência Paralela** utilizando `GNU Parallel`.
    - Substituição do `rsync` sequencial por múltiplas threads (`THREADS=4`) para otimizar a largura de banda em redes locais (SMB/LAN).
    - Orquestração completa: `cpv.sh` agora executa o `fbr` (renomeação) antes de iniciar a transferência.
    - Sistema de `LOCK` para evitar execuções simultâneas.
    - Logs detalhados em `~/logs/` com timestamp.
- **lib/install-essentials.sh:** Adicionado `parallel` como dependência essencial para suportar os novos motores de transferência.
- **Sincronização Global v6.0.0:** Suite completa sincronizada para a nova versão maior para refletir a mudança de paradigma na movimentação de dados.

---

## [4.8.0] - 2026-02-25

### ✨ Melhorias e Novidades

- **lib/setup-system.sh:** Atualizada para `4.8.0` — adicionada a criação de `desktop entries` para utilitários do diretório `utils/`; introduzida a variável `UTILS_DIR` e a função `create_desktop_entries` que gera arquivos `.desktop` idempotentes em `~/.local/share/applications`.
- **lib/install-desktop-kde.sh:** Expansão das listas de pacotes KDE (`kde-applications`, `kde-utilities`) em múltiplas distribuições e pequenas correções de formatação no script.
- **Geral:** Ajuste nas mensagens finais de `setup-system.sh` e sincronização do versionamento do script para `4.8.0`.

---

## [4.7.0] - 2026-02-25

### ✨ Consolidação de Loop e Segurança de Variáveis

- **Varredura de Segurança GPU (Interativo/Final):**
  - Implementada uma varredura final exaustiva em `internet.sh` que detecta todos os apps baseados em Chromium instalados (nativos ou Flatpak) e aplica o patch de GPU de forma independente.
  - O sistema agora é inteligente o suficiente para aplicar o fix mesmo se o app já estiver instalado antes da execução do script.
  - Hooks de atualização (`pacman`, `apt`, `dnf`) e `systemd-timers` (Flatpak) refinados para maior persistência.

- **Check de Robustez `declare -p`:**
  - Todos os scripts de instalação de aplicativos (`lib/install-apps-*.sh`) agora utilizam o comando `declare -p` antes de acessar variáveis de seleção. Isso evita erros de "unbound variable" se o arquivo de configuração estiver incompleto.

- **Sincronização Global v4.7.0:**
  - Toda a suite foi sincronizada para a versão `4.7.0` e data `2026-02-25`.

---


## [4.6.0] - 2026-02-25

### ✨ Consolidação de Motor e Sincronização Global

- **Motor de Instalação Consolidado (v4.6.0):**
  - Unificação da lógica de instalação robusta (com tratamento de erro `10` para "já instalado") para os scripts de **Internet** e **Multimídia**.
  - **GPU Compositing Fix v4.6.0:** Otimização do sistema de correção de renderização GPU, agora integrado ao motor modular.
  - **Correção de Mismatch:** Corrigido o erro onde a lógica de Internet havia sido aplicada no arquivo de Multimídia. Restaurada a lógica original de Multimídia (VLC, OBS, Spotify) e pós-instalação do Filebot, mas utilizando o novo motor consolidado.

- **Sincronização de Versionamento:**
  - Toda a suite `v3rtech-scripts` (incluindo `core/`, `lib/` e `utils/`) foi sincronizada para a versão **4.6.0** e data **2026-02-25**, garantindo uniformidade em todo o ecossistema.
  - Atualização global de cabeçalhos e documentação (`README.md`, `ARCHITECTURE.md`).

---

## [4.0.6] - 2026-02-24

### ✨ Refatoração e Melhorias

- **utils/configs-zip.sh:** Removida a opção `SYSTEM_SETTINGS` da `APP_LIST` e sua respectiva lógica de backup, simplificando o escopo do utilitário de backup de configurações.
- **v3rtech-install.sh:** Movida a verificação e instalação automática de dependências críticas (`rsync`, `yad`) para o topo do script. Isso garante que as ferramentas necessárias estejam presentes antes de qualquer lógica operacional, corrigindo o fluxo onde o `rsync` só era verificado durante a configuração inicial.
- **v3rtech-install.sh:** Sincronização da versão para v4.0.6.

---

## [4.0.5] - 2026-02-24

### ✨ Refatoração e Melhorias

- **lib/install-essentials.sh:** Adicionados `zip` e `unzip` à lista de pacotes essenciais em todas as distribuições suportadas. Removidos drivers redundantes de impressão Samsung (`samsung-ml2160`).
- **lib/setup-system.sh:** Corrigida expansão de variáveis no bloco de configuração do `/etc/bash.bashrc`. Agora `$UTILS_DIR` e `$CONFIGS_DIR` são corretamente interpolados no shell persistente.
- **lib/apps-data.sh:** Limpeza do banco de dados de aplicativos. `OpenAI Whisper` removido (agora gerenciado pelo `install-ia-stack.sh`) e `YT-DLP` removido da seção de IA.
- **utils/restaura-config.sh:** Removida lógica legada para restauração de `KWALLET` e `SYSTEM_SETTINGS`, simplificando o script.

---

## [4.0.4] - 2026-02-24

### ✨ Refatoração e Melhorias

- **lib/setup-system.sh:** Refinado o processo de atualização do `systemd-boot`. Ajustada a lógica de edição do `cmdline` para evitar avisos desnecessários e garantido que o `bootctl update` seja executado sempre que o diretório `/etc/kernel/` for detectado, independentemente da presença do arquivo `cmdline`.
- **core/package-mgr.sh:** Ajustes e finalização da abstração do gerenciador de pacotes para maior robustez.
- **Geral:** Limpeza de scripts legados e atualização do `.gitignore`.
- **v3rtech-install.sh:** Sincronização da versão para v4.0.4.

---

## [4.0.3] - 2026-02-24

### ✨ Melhorias e Estabilização

- **v3rtech-install.sh:** Refinado fluxo de instalação inicial e configuração automática de diretório de destino.
- **utils/fpk-internet.sh:** Adicionada verificação inteligente de navegadores (Vivaldi, Brave, Opera, Firefox). O script agora detecta se uma versão nativa já está instalada antes de baixar o Flatpak, evitando redundâncias.
- **utils/up-sources.sh:** Melhorada a segurança e automação na edição de repositórios do Debian, utilizando `sudo tee` e garantindo permissões corretas.
- **Geral:** Padronização do uso de `sudo` em scripts críticos e correção de permissões de execução em diversos utilitários.
- **core/env.sh:** Melhoria na robustez da detecção do diretório base e proteção de variáveis de ambiente.

---

## [4.0.2] - 2026-02-23

### 🐧 Correções (Hotfix)

- **core/env.sh:** Corrigido problema onde variáveis críticas (BASE_DIR, LIB_DIR, etc) eram sobrescritas pelo config.conf. Agora as variáveis detectadas dinamicamente são protegidas contra sobrescrita.
- **core/env.sh:** Adicionada melhor detecção de caminho do projeto usando BASH_SOURCE para funcionar com symlinks.
- **lib/detect-system.sh:** Corrigidos caminhos relativos para funcionar quando o script é chamado de forma indireta.
- **core/env.sh:** Adicionadas mensagens de erro mais detalhadas para facilitar diagnóstico de problemas.

---

## [4.0.0] - 2026-02-23

### ✨ Novo (Refatoração Completa)

#### Arquitetura
- **Modularidade Total:** Cada script é 100% independente e pode ser executado isoladamente
- **Arquivo de Configuração Compartilhado:** `~/.config/v3rtech-scripts/config.conf` centraliza estado
- **Infraestrutura Base Melhorada:** core/env.sh, core/logging.sh, core/package-mgr.sh
- **Detecção de Sistema Automática:** Detecta distribuição, desktop, GPU, sessão gráfica

#### Scripts Principais
- **v3rtech-install.sh:** Script-mestre orquestrador com menu interativo
- **lib/detect-system.sh:** Detecção automática de ambiente
- **lib/install-essentials.sh:** Instalação de pacotes obrigatórios
- **lib/install-apps-*.sh:** Scripts independentes por categoria (Internet, Escritório, Dev, Multimídia, Design, Sistema, Jogos)
- **lib/install-desktop-*.sh:** Instalação de ambientes desktop (KDE, GNOME, XFCE, Deepin, Cosmic)
- **lib/install-docker.sh:** Docker e Docker Compose
- **lib/install-ia-stack.sh:** Stack completo de IA/ML
- **lib/install-certificates.sh:** Certificados ICP-Brasil
- **lib/install-virtualbox.sh:** VirtualBox
- **lib/setup-system.sh:** Configuração de sistema (PATH, aliases, sudoers)
- **lib/cleanup.sh:** Limpeza final do sistema

#### Recursos
- **Suporte a Distribuições Imutáveis:** Detecção automática de Silverblue, Kinoite, etc
- **Pergunta Global Única:** Nativo vs Flatpak perguntado uma única vez
- **Inputs Antecipados:** Todos os inputs solicitados no início, sem interrupções
- **Logging Colorido:** Terminal com cores ANSI + arquivo de log
- **Tratamento de Erros Inteligente:** Diferencia erros críticos de não-críticos
- **Idempotência:** Scripts podem ser executados múltiplas vezes com segurança
- **Comentários Detalhados:** Código bem documentado

#### Distribuições Suportadas
- ✅ Arch Linux (com Paru/Yay)
- ✅ Debian/Ubuntu (com apt-fast opcional)
- ✅ Fedora (com DNF)
- ✅ Distribuições Imutáveis (Silverblue, Kinoite, Aeon, etc)

#### Ambientes Desktop Suportados
- ✅ KDE Plasma
- ✅ GNOME
- ✅ XFCE
- ✅ Deepin
- ✅ Cosmic

### ✨ Melhorias

- Estrutura de diretórios mais intuitiva
- Separação clara entre core, lib e utils
- Funções de logging padronizadas
- Abstração de gerenciadores de pacotes
- Suporte a Flatpak e Pipx como alternativas
- Configuração de CUPS automática
- Detecção de GPU (Intel, AMD, NVIDIA)
- Detecção de sessão gráfica (X11, Wayland)

### 🔄 Mudanças

- Removido suporte a LXQT, Mate e Tiling WM (conforme solicitado)
- Numeração de scripts removida (04-pack-kde.sh → install-desktop-kde.sh)
- Arquivo de configuração centralizado em ~/.config/v3rtech-scripts/
- Logs salvos em ~/.config/v3rtech-scripts/logs/
- Sudo sem senha configurado de forma segura

### 📚 Documentação

- README.md completo com guia de uso
- ARCHITECTURE.md com detalhes técnicos
- CHANGELOG.md (este arquivo)
- Comentários detalhados em todos os scripts

### 🔧 Compatibilidade

- Python 3.8+
- Bash 4.0+
- Zenity ou YAD para diálogos gráficos
- Curl, Git, Sudo (instalados automaticamente se necessário)

---

## [3.x] - Versões Anteriores

As versões anteriores (3.x) estão disponíveis no branch `legacy`.

Principais características da v3:
- Scripts numerados (00-, 01-, 04-, etc)
- Configuração espalhada em vários arquivos
- Dependências entre scripts
- Inputs durante a execução
- Suporte a LXQT, Mate, Tiling WM

---

## 📝 Notas de Migração (v3 → v4)

Se você está migrando da v3 para v4:

1. **Backup de Configurações:** Faça backup de suas configurações antes de atualizar
2. **Novo Arquivo de Config:** A v4 usa `~/.config/v3rtech-scripts/config.conf`
3. **Novos Nomes de Scripts:** Scripts foram renomeados (sem numeração)
4. **Independência:** Cada script agora é completamente independente
5. **Compatibilidade:** A v4 é retrocompatível com a maioria dos recursos da v3

---

## 🔮 Planejado para Futuras Versões

- [ ] Suporte a mais distribuições (openSUSE, Solus, etc)
- [ ] Interface gráfica completa (além de menu de texto)
- [ ] Instalação de temas e ícones customizados
- [ ] Configuração de atalhos de teclado por desktop
- [ ] Suporte a snapd como alternativa
- [ ] Rollback automático em caso de falha
- [ ] Modo offline com cache de pacotes
- [ ] Integração com Ansible para deployments em massa
- [ ] Suporte a containers (Podman, LXC)
- [ ] Configuração de VPN automática

---

## 🐛 Bugs Conhecidos

Nenhum bug conhecido na v4.0.0.

Se encontrar algum bug, por favor abra uma issue no repositório.

---

## 📊 Estatísticas

- **Versão:** 6.0.0
- **Data de Lançamento:** 2026-02-23
- **Scripts Principais:** 20+
- **Funções Auxiliares:** 50+
- **Linhas de Código:** 3000+
- **Distribuições Suportadas:** 4+ (Arch, Debian, Ubuntu, Fedora)
- **Ambientes Desktop:** 5 (KDE, GNOME, XFCE, Deepin, Cosmic)

---

## 👨‍💻 Autor

**V3RTECH Tecnologia, Consultoria e Inovação**

Website: https://v3rtech.com.br/

---

## 📄 Licença

MIT License - Veja LICENSE para detalhes

---

**Última Atualização:** 2026-03-06
