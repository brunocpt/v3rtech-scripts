# Arquitetura do Sistema - V3RTECH Scripts

Este documento descreve o fluxo técnico, a estrutura de dados e as decisões de design do projeto (Versão 2.0+).

## 🧠 Filosofia de Design

1.  **Idempotência:** Os scripts podem ser rodados múltiplas vezes sem quebrar o sistema. Verificações (`grep` ou `if exists`) são feitas antes de editar arquivos de configuração ou instalar pacotes.
2.  **Dados como Código:** A lista de aplicativos não é mais um arquivo de texto passivo (CSV), mas sim um script Bash (`lib/apps-data.sh`) carregado dinamicamente. Isso elimina erros de parsing de texto e permite maior flexibilidade.
3.  **Persistência Global:** Configurações de ambiente (PATH, Aliases) são aplicadas em nível de sistema (`/etc/bash.bashrc`) para garantir funcionamento multiusuário e persistência após reinicialização.
4.  **Modularidade:** Cada etapa do processo é um arquivo isolado em `lib/`. O `v3rtech-install.sh` atua apenas como orquestrador.

## 📂 Estrutura de Diretórios

* `core/`: Bibliotecas base (logging, variáveis de ambiente).
* `lib/`: Módulos de lógica principal.
    * `logic-apps-reader.sh`: Motor de instalação e interpretador de dados.
    * `apps-data.sh`: Banco de dados de aplicativos (Hardcoded function calls).
    * `ui-main.sh`: Interface gráfica (YAD).
    * `03-prepara-configs.sh`: Configurador de ambiente e otimizações.
    * `99-limpeza-final.sh`: Removedor de repositórios duplicados.
* `configs/`: Arquivos de configuração (Aliases, Dotfiles, SSH Keys).
* `resources/`: Assets binários (Fontes, Zips de configuração de apps).
* `utils/`: Scripts utilitários instalados no sistema (`atualiza_scripts.sh`, `i`, etc).

## 🔍 Fluxo de Execução

1.  **Bootstrap (`v3rtech-install.sh`):**
    * Valida privilégios de Root (`$EUID -ne 0`).
    * Inicia loop de *Sudo Keep-Alive* em background.
    * **Auto-Instalação:** Se rodando de USB, copia a si mesmo para `/usr/local/share/scripts/v3rtech-scripts` e reinicia a execução de lá.

2.  **Detecção e Preparação:**
    * `00-detecta-distro.sh`: Identifica Distro, GPU e Ambiente Gráfico.
    * `01-prepara-distro.sh`: Instala dependências base (curl, git, yad) e configuradores de repositório.

3.  **Interface e Seleção (`lib/ui-main.sh`):**
    * Carrega `lib/apps-data.sh` para popular a lista visual.
    * Exporta variáveis para corrigir execução do YAD em Wayland (`xhost`, `GDK_BACKEND=x11`).
    * Exibe checklist YAD e retorna a lista de nomes selecionados sanitizada.

4.  **Motor de Instalação (`lib/logic-apps-reader.sh`):**
    * Recebe os nomes selecionados.
    * Carrega `configs/aliases.geral` para habilitar o comando `i` (wrapper inteligente de instalação).
    * Consulta os mapas associativos (`APP_MAP_NATIVE`, `APP_MAP_FLATPAK`) para determinar o método.
    * Executa a instalação com tratamento de erros.

5.  **Configuração de Ambiente (`lib/03-prepara-configs.sh`):**
    * **PATH Global:** Injeta lógica de PATH no `/etc/bash.bashrc` (com proteção anti-duplicação).
    * **Aliases:** Injeta `source .../configs/aliases.geral` no `/etc/bash.bashrc`.
    * **Otimizações:** Aplica `sysctl` (swappiness, cache) e ajustes de `journald`.
    * **Usuário:** Restaura backups de configs (`.zip`) para a `/home` do usuário real.
    * **Permissões:** Garante `chmod +x` em todos os scripts da pasta `utils/`.

6.  **Limpeza Final (`lib/99-limpeza-final.sh`):**
    * Varre `/etc/apt/sources.list.d/`.
    * Detecta e remove arquivos `.list` duplicados gerados automaticamente por instaladores (Chrome, Edge, Vivaldi) se o arquivo moderno `.sources` já existir.

## 📦 Definição de Aplicativos (`lib/apps-data.sh`)

Os aplicativos são definidos através da função `add_app`. Isso permite controle granular sobre o nome do pacote em diferentes distros.

**Sintaxe:**
```bash
add_app "ATIVO" "CATEGORIA" "NOME" "DESCRIÇÃO" "PKG_DEB" "PKG_ARCH" "PKG_FED" "FLATPAK_ID" "METODO"