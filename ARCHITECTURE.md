# Arquitetura do Sistema - V3RTECH Scripts

Este documento descreve o fluxo técnico e as decisões de design do projeto.

## 🧠 Filosofia de Design

1.  **Idempotência:** Os scripts podem ser rodados múltiplas vezes sem quebrar o sistema. Verificações (`if exists`) são feitas antes de ações destrutivas.
2.  **Abstração:** O código de negócio (instalar app X) não deve saber qual distro está rodando. Isso é delegado ao `core/package-mgr.sh`.
3.  **Modularidade:** Cada etapa do processo é um arquivo isolado em `lib/`. O `v3rtech-install.sh` atua apenas como orquestrador.

## 🔍 Fluxo de Execução (`v3rtech-install.sh`)

1.  **Bootstrap:**
    * Carrega `core/env.sh` (Variáveis e Caminhos).
    * Valida se o usuário NÃO é root (`$EUID -ne 0`).
    * Inicia loop de *Sudo Keep-Alive* em background.
    * **Auto-Instalação:** Se rodando de USB, copia a si mesmo para `/usr/local/share/scripts/v3rtech-scripts`.

2.  **Detecção (`lib/00-detecta-distro.sh`):**
    * Lê `/etc/os-release`.
    * Define `$DISTRO_FAMILY` (debian, arch, fedora), `$PKG_MANAGER` e `$DESKTOP_ENV`.
    * Detecta GPU (`nvidia`, `amd`, `intel`) para aplicar flags de boot posteriormente.

3.  **Preparação (`lib/01-prepara-distro.sh`):**
    * Debian/Ubuntu: Instala/Configura `apt-fast` e PPA.
    * Arch: Instala/Compila `paru` (AUR Helper).
    * Geral: Instala `yad`, `git`, `curl`.

4.  **Dados e Repositórios:**
    * Carrega `data/apps.csv` via `lib/logic-apps-reader.sh`.
    * Executa `lib/02-setup-repos.sh`: Varre a lista de apps marcados como `TRUE`. Se o usuário quer "VS Code", o script adiciona o repo da Microsoft. Se não, ignora.

5.  **Interface Gráfica (`lib/ui-main.sh`):**
    * Exibe checklist via YAD.
    * Ao confirmar, executa loop de instalação chamando a função `install_app_by_name`.
    * Exibe log em tempo real (`tail -f`) em janela dedicada.

6.  **Configuração de Ambiente (`lib/04-pack-*.sh`):**
    * Baseado na variável `$DESKTOP_ENV`, carrega o script específico (ex: `04-pack-gnome.sh`).
    * Aplica `gsettings`, instala extensões e restaura configs específicas de DE.

7.  **Otimizações Gerais (`lib/03-prepara-configs.sh`):**
    * Aplica `sysctl.conf` (swappiness, cache).
    * Configura `journald` (limite de logs).
    * Instala fontes e scripts utilitários em `/usr/local/bin`.
    * Restaura configs de apps gerais (Geany, Cups, etc).
    * Configura Plymouth (Tema de Boot).

8.  **Boot e Kernel (`lib/04-setup-boot.sh`):**
    * Detecta GRUB ou Systemd-boot.
    * Aplica flags de kernel (`quiet`, otimizações NVMe, flags de GPU).
    * Gera initramfs e atualiza bootloader.

9.  **Hooks Finais:**
    * Docker: Configura grupo e daemon.
    * VirtualBox: Instala Extension Pack e configura módulos.

## 📦 Gerenciamento de Pacotes (`core/package-mgr.sh`)

A função `i` (install) é o coração do sistema:

* **Sintaxe:** `i pacote1 pacote2`
* **Lógica:**
    1.  Verifica a distro.
    2.  No Debian: Usa `apt-fast` se disponível, senão `apt`.
    3.  No Arch: Usa `paru` (cobre Repo Oficial + AUR).
    4.  No Fedora: Usa `dnf`.
* **Flatpak:** Função `install_flatpak` gerencia repositórios Flathub e atualizações.

## 📂 Dados (`data/apps.csv`)

O arquivo CSV usa Pipe `|` como separador para permitir descrições com espaços.
A coluna `METODO` define a estratégia de fallback:
* `native`: Tenta repo oficial -> Falha -> Tenta Flatpak.
* `flatpak`: Força Flatpak.
* `pipx`: Usa instalador Python isolado.
