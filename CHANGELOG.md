# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

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