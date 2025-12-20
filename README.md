# V3RTECH Scripts - Automação de Pós-Instalação Linux

> **Versão:** 1.6.0
> **Autor:** V3RTECH Tecnologia, Consultoria e Inovação
> **Website:** [v3rtech.com.br](https://v3rtech.com.br/)

O **V3RTECH Scripts** é uma suíte de automação modular e inteligente projetada para configurar, otimizar e personalizar distribuições Linux recém-instaladas. Focado em idempotência, segurança e flexibilidade, ele transforma uma instalação "crua" em uma estação de trabalho produtiva em minutos.

## 🚀 Funcionalidades Principais

* **Multi-Distro:** Suporte nativo para **Debian**, **Ubuntu** (e derivados como Mint, Pop!_OS), **Fedora** e **Arch Linux**.
* **Abstração de Pacotes:** Instala softwares automaticamente escolhendo o melhor método: Repositório Nativo (`apt`, `dnf`, `pacman`), **AUR** (`paru`), **Flatpak** ou **Pipx**.
* **Interface Gráfica (GUI):** Seleção de aplicativos via checklist amigável (YAD), com logs de progresso em tempo real ("Matrix style").
* **Gestão de Repositórios:** Adiciona repositórios de terceiros (VS Code, Chrome, Docker, etc.) *on-demand*, apenas se o aplicativo for selecionado.
* **Ambientes Desktop:** Configurações específicas e otimizadas para **GNOME, KDE Plasma, XFCE, Budgie, Deepin, Mate e Cosmic**.
* **Otimização de Boot & Kernel:** Ajustes automáticos de parâmetros de kernel (`sysctl`, `cmdline`) e bootloader (GRUB/Systemd-boot), com detecção de GPU (Nvidia/AMD/Intel).
* **Segurança:** Execução em modo usuário (User-Mode) com abstração de `sudo`, evitando permissões quebradas na `/home`.

## 📋 Pré-requisitos

* Uma instalação limpa de uma distribuição suportada.
* Conexão ativa com a internet.
* Usuário com permissões de `sudo`.

## 🛠️ Instalação e Uso

1.  **Clone o repositório** (ou baixe e extraia o zip):
    ```bash
    git clone [https://github.com/brunocpt/v3rtech-scripts.git](https://github.com/brunocpt/v3rtech-scripts.git)
    cd v3rtech-scripts
    ```

2.  **Execute o script mestre:**
    > ⚠️ **Não execute como root!** O script pedirá sua senha de sudo quando necessário.

    ```bash
    chmod +x v3rtech-install.sh
    ./v3rtech-install.sh
    ```

3.  **Siga o fluxo:**
    * Confirme a detecção do sistema.
    * Selecione os aplicativos na interface gráfica.
    * Aguarde a finalização.

## ⚙️ Personalização

A lista de aplicativos instaláveis não está "chumbada" no código. Ela é gerenciada por um arquivo CSV fácil de editar.

* **Adicionar/Remover Apps:** Edite o arquivo `data/apps.csv`.
* **Formato:**
    `ATIVO|CATEGORIA|NOME|DESCRICAO|PKG_DEBIAN|PKG_ARCH|PKG_FEDORA|FLATPAK_ID|METODO`
* **Arquivos de Configuração:** Coloque seus dotfiles (`.bashrc`, configs do Geany, etc.) na pasta `configs/` e seus zips de backup na mesma pasta seguindo o padrão de nomenclatura (ex: `user-atalhos-kde.zip`).

## 📂 Estrutura do Projeto

* `core/`: Bibliotecas base (logging, gerenciador de pacotes, variáveis).
* `lib/`: Módulos de lógica (detecção, preparação, UI, boot, scripts de DE).
* `data/`: Banco de dados de aplicativos (`apps.csv`).
* `configs/`: Arquivos de configuração pessoais e dotfiles.
* `resources/`: Assets como ícones, fontes e pacotes locais.
* `utils/`: Scripts utilitários que serão instalados no sistema (`up`, `upsnapshot`, etc.).

## ⚠️ Aviso Legal

Este software altera configurações profundas do sistema (Bootloader, Kernel, Drivers). Embora tenha mecanismos de backup e segurança, utilize por sua conta e risco. Recomenda-se testar em máquina virtual antes do uso em produção.

---
© 2025 V3RTECH Tecnologia.
