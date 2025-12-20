# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

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
    - **Budgie:** Substituição do Nautilus pelo Nemo, configs visuais e serviços.
    - **Deepin & Mate:** Instalação base e ativação do `lightdm`.
    - **Cosmic:** Instalação base e configs experimentais.
- **Detecção Automática de DE:** O script mestre agora identifica o ambiente gráfico atual e carrega o módulo de configuração correspondente automaticamente.
- **Plymouth:** Adicionada configuração de tema de boot (BGRT/Spinner) no módulo de configurações gerais.

### Corrigido
- **Ordem de Execução:** O módulo de otimização de Boot (`04-setup-boot.sh`) foi movido para o final do processo para evitar alterações no Kernel caso o usuário cancele a instalação na interface gráfica.

---

## [1.4.0] - 2025-10-25
### Adicionado
- **Módulo de Configurações Gerais (`03-prepara-configs.sh`):**
    - Otimizações de `sysctl` (swappiness, cache pressure).
    - Configuração de `journald` (limite de logs).
    - Restauração de dotfiles (`.bashrc`, aliases).
    - Instalação de fontes e scripts utilitários em `/usr/local/bin`.
    - Restauração de configs de apps (Geany, Cups, Grsync).

### Alterado
- **Script Mestre:** Integração do módulo `03-prepara-configs.sh` ao fluxo principal.

---

## [1.3.0] - 2025-10-24
### Adicionado
- **Interface Gráfica (UI):** Implementação do `lib/ui-main.sh` usando YAD.
    - Checklist interativo para seleção de apps.
    - Janela de log em tempo real ("Matrix style") durante a instalação.
- **Hook do Docker:** Script de pós-configuração (`lib/setup-docker.sh`) para ativar serviços systemd, configurar rotação de logs e adicionar usuário ao grupo docker.

### Removido
- Lógica de loop de instalação interna do script mestre (movida para dentro da UI).

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
    - `package-mgr.sh`: Abstração de instalação (`i`, `up`, `r`) suportando apt, pacman (paru), dnf, flatpak e pipx.
- **Detecção de Distro:** Script `00-detecta-distro.sh` para identificar Debian, Ubuntu, Fedora e Arch.
- **Leitor de CSV:** Script `logic-apps-reader.sh` para processar o banco de dados de aplicativos.