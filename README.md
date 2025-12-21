# V3RTECH Scripts - Automação de Pós-Instalação Linux

> **Versão:** 2.0.0
> **Autor:** V3RTECH Tecnologia, Consultoria e Inovação
> **Website:** [v3rtech.com.br](https://v3rtech.com.br/)

O **V3RTECH Scripts** é uma suíte de automação modular projetada para configurar, otimizar e personalizar distribuições Linux (Debian, Ubuntu, Arch, Fedora). Ele transforma uma instalação "crua" em uma estação de trabalho produtiva, aplicando configurações de sistema, instalando softwares e definindo um ambiente de shell robusto e persistente.

## 🚀 Funcionalidades Principais

* **Multi-Distro:** Compatível com **Debian 12/Sid**, **Ubuntu/Mint/Pop!_OS**, **Fedora** e **Arch Linux**.
* **Instalação Inteligente:** Seleciona automaticamente o melhor método de instalação (Nativo, AUR, Flatpak ou Pipx).
* **Ambiente Persistente:** Configura `aliases` e `PATH` globalmente em `/etc/bash.bashrc`, garantindo que ferramentas personalizadas (como o comando `i`) funcionem para todos os usuários imediatamente após o reboot.
* **Correção Automática:** Scripts de limpeza removem repositórios duplicados gerados por instaladores de terceiros (Chrome, Edge, etc.).
* **Interface Gráfica:** Seleção de apps via checklist (YAD) com logs detalhados e suporte a Wayland.
* **Otimização:** Ajustes automáticos de Kernel (`sysctl`), Logs (`journald`) e Boot (`GRUB`).

## 📋 Como Usar

1.  **Clone o repositório ou baixe o zip:**
    ```bash
    git clone [https://github.com/brunocpt/v3rtech-scripts.git](https://github.com/brunocpt/v3rtech-scripts.git)
    cd v3rtech-scripts
    ```

2.  **Execute o script mestre:**
    ```bash
    chmod +x v3rtech-install.sh
    ./v3rtech-install.sh
    ```

3.  **Siga o fluxo:**
    * O script verificará se está rodando de um USB e se auto-instalará em `/usr/local/share/`.
    * Confirme a detecção de hardware/distro.
    * Selecione os aplicativos na lista gráfica.
    * Aguarde a instalação e reinicie o computador para aplicar as mudanças de PATH e Aliases.

## ⚙️ Personalização

A lista de aplicativos e suas definições de instalação agora são gerenciadas via código para maior robustez.

* **Editar Apps:** Abra o arquivo `lib/apps-data.sh`.
* **Adicionar App:** Use a sintaxe da função `add_app`. Exemplo:
    ```bash
    #       Ativo  Cat      Nome        Desc           Debian    Arch      Fedora    Flatpak ID            Metodo
    add_app "TRUE" "Editor" "MeuApp"    "Editor Top"   "meu-app" "meu-app" "meu-app" "com.meuapp.Editor"   "native"
    ```
* **Aliases:** Edite `configs/aliases.geral` para adicionar seus atalhos personalizados. As mudanças serão refletidas no sistema após rodar o script de configuração.

## 🛠️ Utilitários Inclusos

O sistema instala scripts úteis em `/usr/local/share/scripts/v3rtech-scripts/utils/` e cria links no PATH:

* **`i <pacote>`:** Wrapper inteligente para instalar pacotes. Detecta a distro e usa o acelerador disponível (`apt-fast`, `paru`, `dnf`).
* **`atualiza_scripts.sh`:** Sincroniza seus scripts locais com uma origem de rede ou GitHub, mantendo o sistema atualizado.
* **`ocrbr / ocrauto`:** Ferramentas de OCR para PDFs, com detecção automática de idioma.

## ⚠️ Aviso Legal

Este software altera configurações profundas do sistema (`/etc/bash.bashrc`, `/etc/sysctl.d`, `/etc/apt/sources.list.d`). Embora testado extensivamente em ambientes de produção, **use por sua conta e risco** e sempre faça backup de seus dados antes de rodar em um sistema crítico.