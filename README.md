# V3RTECH Scripts - Automação de Pós-Instalação Linux

> **Versão:** 3.9.4
> **Autor:** V3RTECH Tecnologia, Consultoria e Inovação
> **Website:** [v3rtech.com.br](https://v3rtech.com.br/)

O **V3RTECH Scripts** é uma suíte de automação modular projetada para configurar, otimizar e personalizar distribuições Linux (Debian, Ubuntu, Arch, Fedora). Ele transforma uma instalação "crua" em uma estação de trabalho produtiva, aplicando configurações de sistema, instalando softwares, definindo um ambiente de shell robusto e persistente, e restaurando preferências personalizadas.

## 🚀 Funcionalidades Principais

**Compatibilidade e Detecção**
- **Multi-Distro:** Compatível com Debian 12/Sid, Ubuntu/Mint/Pop!_OS, Fedora e Arch Linux
- **Multi-Ambiente:** Suporte para KDE/Plasma, GNOME/Budgie, XFCE, Mate, Deepin, Cosmic, LXQT e Tiling Window Managers (i3, sway, etc)
- **Detecção Automática:** Identifica distro, ambiente de desktop e GPU para aplicar configurações específicas

**Instalação e Configuração**
- **Instalação Inteligente:** Seleciona automaticamente o melhor método (Nativo, AUR, Flatpak, Pipx)
- **Interface Gráfica:** Seleção de apps via checklist (YAD) com logs detalhados
- **Ambiente Persistente:** Configura aliases e PATH globalmente em `/etc/bash.bashrc`
- **Idempotência Verdadeira:** Todos os scripts usam marcadores de bloco, permitindo execução múltipla sem duplicação

**Configuração de Desktop**
- **Bookmarks GTK:** Mapeia pastas estratégicas em gerenciadores de arquivos (Nautilus, Thunar, etc)
- **Links Simbólicos:** Cria atalhos para pastas de rede e diretórios importantes
- **Atalhos de Teclado:** Restaura configurações personalizadas por ambiente (KDE, GNOME, XFCE, LXQT, Tiling WM)
- **Mounts de Rede:** Configura compartilhamentos NFS/CIFS no fstab automaticamente

**Otimização e Manutenção**
- **Limpeza Automática:** Remove repositórios duplicados gerados por instaladores de terceiros
- **Otimização de Sistema:** Ajustes automáticos de Kernel (sysctl), Logs (journald) e Boot (GRUB)
- **Scripts de Manutenção:** Utilitários para atualização, snapshot e correção de permissões
- **Limpeza de PATH:** Ferramenta nuclear para resolver PATH duplicado exponencialmente

**Suporte Avançado**
- **Wayland:** Suporte completo para sessões Wayland (KDE/GNOME modernos)
- **Sudo Sem Senha:** Configuração segura com detecção de grupo por distro
- **FUSE:** Configuração automática para montagem de sistemas de arquivos
- **Docker:** Instalação e configuração com suporte a docker-compose
- **ICP-Brasil:** Instalação automática de certificados, drivers de token e assinadores digitais
- **NVIDIA:** Instalação robusta de drivers proprietários com foco em Wayland
- **IA Local:** Instalação facilitada do OpenAI Whisper com aceleração de GPU

## 📋 Como Usar

### Instalação Rápida

```bash
# Clone o repositório
git clone https://github.com/brunocpt/v3rtech-scripts.git
cd v3rtech-scripts

# Execute o script mestre
chmod +x v3rtech-install.sh
./v3rtech-install.sh
```

### Fluxo de Execução

1. **Detecção:** O script detecta distro, ambiente de desktop e GPU
2. **Confirmação:** Exibe diálogo para confirmar detecção antes de prosseguir
3. **Preparação:** Instala dependências essenciais (YAD, git, curl, etc)
4. **Configuração:** Aplica configurações de sistema (PATH, aliases, sudoers, etc)
5. **Instalação:** Seleciona e instala aplicativos via interface gráfica
6. **Personalização:** Restaura bookmarks, atalhos de teclado e mounts de rede
7. **Otimização:** Aplica otimizações de kernel, boot e logs
8. **Limpeza:** Remove repositórios duplicados

### Pós-Instalação

Após a execução, reinicie o terminal ou shell para aplicar as mudanças:

```bash
# Reiniciar shell
exec bash

# Verificar PATH
echo $PATH | tr ':' '\n' | sort | uniq -d  # Deve estar vazio

# Testar comando de instalação
i --help
```

## ⚙️ Personalização

### Editar Lista de Aplicativos

```bash
nano lib/apps-data.sh
```

Sintaxe para adicionar um novo aplicativo:

```bash
#       Ativo  Categoria  Nome        Descrição      Debian    Arch      Fedora    Flatpak ID            Método
add_app "TRUE" "Editor"   "MeuApp"    "Editor Top"   "meu-app" "meu-app" "meu-app" "com.meuapp.Editor"   "native"
```

### Configurar Aliases Personalizados

```bash
nano configs/aliases.geral
```

Adicione seus aliases:

```bash
alias meu-alias='comando-longo-aqui'
alias outro='outro-comando'
```

### Configurar Mounts de Rede

```bash
nano lib/09-setup-fstab-mounts.sh
```

Descomente e ajuste os exemplos:

```bash
# NFS
add_fstab_mount "192.168.1.100:/volume1/trabalho" "/mnt/trabalho" "nfs" "defaults,vers=3,soft,timeo=10,retrans=3" "0" "0"

# CIFS/Samba
add_fstab_mount "//192.168.1.100/compartilhado" "/mnt/samba" "cifs" "username=user,password=pass,uid=1000,gid=1000" "0" "0"
```

### Restaurar Atalhos de Teclado

1. Crie pasta de backups:
```bash
mkdir -p /usr/local/share/scripts/v3rtech-scripts/resources/keyboard-shortcuts
```

2. Coloque seus backups de atalhos (ZIP files):
   - `${USER}-atalhos-kde.zip` (para KDE)
   - `${USER}-atalhos-gnome.zip` (para GNOME)
   - `${USER}-atalhos-xfce.zip` (para XFCE)
   - `${USER}-atalhos-lxqt.zip` (para LXQT)
   - `${USER}-atalhos-tiling.zip` (para Tiling WM)

3. O script restaurará automaticamente na próxima execução

## 🛠️ Utilitários Inclusos

O sistema instala scripts úteis em `/usr/local/share/scripts/v3rtech-scripts/utils/` e cria links no PATH:

**Instalação e Pacotes**
- **`i <pacote>`:** Wrapper inteligente para instalar pacotes. Detecta a distro e usa o acelerador disponível (apt-fast, paru, dnf)
- **`atualiza_scripts.sh`:** Sincroniza scripts locais com origem de rede ou GitHub

**Configuração e Backup**
- **`configs-zip.sh`:** Cria backups ZIP de configurações de aplicativos
- **`restaura-config.sh`:** Restaura configurações de backup ZIP

**Manutenção de Sistema**
- **`up`:** Atualização inteligente multi-distro (apt/pacman/dnf)
- **`upsnapshot`:** Manutenção completa com snapshot (se disponível)
- **`fixperm`:** Corrige permissões de arquivos e diretórios

**Diagnóstico e Limpeza**
- **`clean-path`:** Remove entradas duplicadas do PATH (modo nuclear)
- **`diagnose-path.sh`:** Encontra todas as linhas que modificam PATH

**OCR e Processamento**
- **`ocrbr`:** Ferramenta de OCR para PDFs em português
- **`ocrauto`:** OCR com detecção automática de idioma
- **`video-converter-gui.sh`:** Interface gráfica para conversão de vídeo (FFmpeg)
- **`extrai-legendas.sh`:** Extração automática de legendas de vídeos

**Certificados e Drivers**
- **`pack-icp-brasil.sh`:** Instalador universal de certificados ICP-Brasil e Assinador SERPRO
- **`pack-nvidia-wayland.sh`:** Instalador de drivers NVIDIA com otimização Wayland

**Reparos e Otimização**
- **`fix_pipx.sh`:** Repara ambientes virtuais Python quebrados
- **`optimize-fstab.sh`:** Otimização para SSDs e Btrfs/Ext4 (compressão, noatime)

## 📁 Estrutura de Diretórios

```
v3rtech-scripts/
├── core/                          # Bibliotecas base
│   ├── env.sh                     # Variáveis globais
│   ├── logging.sh                 # Funções de log
│   └── package-mgr.sh             # Gerenciador de pacotes
├── lib/                           # Scripts de configuração
│   ├── 00-detecta-distro.sh       # Detecção de sistema
│   ├── 01-prepara-distro.sh       # Preparação de distro
│   ├── 02-setup-repos.sh          # Configuração de repositórios
│   ├── 03-prepara-configs.sh      # Configurações globais
│   ├── 04-pack-*.sh               # Configuração por ambiente
│   ├── 04-setup-boot.sh           # Otimização de boot
│   ├── 05-setup-sudoers.sh        # Configuração de sudo
│   ├── 06-setup-shell-env.sh      # Configuração de shell
│   ├── 07-setup-user-dirs.sh      # Diretórios e bookmarks
│   ├── 08-setup-maintenance.sh    # Scripts de manutenção
│   ├── 09-setup-fstab-mounts.sh   # Mounts de rede
│   ├── 10-setup-keyboard-shortcuts.sh # Atalhos de teclado
│   ├── 99-limpeza-final.sh        # Limpeza final
│   ├── apps-data.sh               # Banco de dados de apps
│   ├── logic-apps-reader.sh       # Motor de instalação
│   ├── setup-docker.sh            # Configuração Docker
│   └── ui-main.sh                 # Interface gráfica
├── utils/                         # Utilitários
│   ├── clean-path                 # Limpeza de PATH
│   ├── diagnose-path.sh           # Diagnóstico de PATH
│   ├── configs-zip.sh             # Backup de configs
│   ├── restaura-config.sh         # Restauração de configs
│   └── ... (outros utilitários)
├── configs/                       # Arquivos de configuração
│   ├── aliases.geral              # Aliases globais
│   └── ... (outros configs)
├── resources/                     # Recursos
│   ├── keyboard-shortcuts/        # Backups de atalhos
│   └── ... (outros recursos)
├── v3rtech-install.sh             # Script principal
├── README.md                      # Este arquivo
├── CHANGELOG.md                   # Histórico de versões
└── ARCHITECTURE.md                # Documentação técnica
```

## 🔧 Troubleshooting

### PATH com Entradas Duplicadas

Se o PATH estiver crescendo exponencialmente:

```bash
# Diagnosticar
./utils/diagnose-path.sh

# Limpar (modo preview)
./utils/clean-path --dry-run

# Limpar (aplicar mudanças)
./utils/clean-path
```

### Bookmarks não Aparecem

1. Reinicie o gerenciador de arquivos
2. Verifique permissões:
```bash
chmod 644 ~/.local/share/gtk-3.0/bookmarks
```

### Mounts não Aparecem Após Reboot

1. Verifique fstab:
```bash
cat /etc/fstab | grep -E "nfs|cifs"
```

2. Teste manualmente:
```bash
sudo mount -a
```

3. Verifique conectividade de rede

### Atalhos Não Restaurados

1. Verifique se o ZIP existe:
```bash
ls /usr/local/share/scripts/v3rtech-scripts/resources/keyboard-shortcuts/
```

2. Verifique logs:
```bash
grep "atalhos" ~/.local/share/v3rtech-scripts.log
```

## 📊 Compatibilidade

| Distro | Status | Testado |
|--------|--------|---------|
| Arch Linux | ✅ Completo | Sim |
| Debian 12 | ✅ Completo | Sim |
| Ubuntu 22.04+ | ✅ Completo | Sim |
| Fedora 38+ | ✅ Completo | Sim |
| Linux Mint | ✅ Completo | Sim |

| Ambiente | Status | Testado |
|----------|--------|---------|
| KDE/Plasma | ✅ Completo | Sim |
| GNOME | ✅ Completo | Sim |
| XFCE | ✅ Completo | Sim |
| LXQT | ✅ Completo | Sim |
| Tiling WM (i3, sway) | ✅ Completo | Sim |
| Mate | ✅ Completo | Sim |
| Deepin | ✅ Completo | Sim |
| Cosmic | ✅ Completo | Sim |

## ⚠️ Aviso Legal

Este software altera configurações profundas do sistema (`/etc/bash.bashrc`, `/etc/sysctl.d`, `/etc/apt/sources.list.d`, `/etc/fstab`). Embora testado extensivamente em ambientes de produção, **use por sua conta e risco** e sempre faça backup de seus dados antes de rodar em um sistema crítico.

## 📝 Licença

Este projeto é mantido por V3RTECH Tecnologia, Consultoria e Inovação.

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor, abra uma issue ou pull request com suas sugestões e melhorias.

## 📞 Suporte

Para dúvidas ou problemas, acesse [v3rtech.com.br](https://v3rtech.com.br/) ou abra uma issue no repositório.

---

**Versão:** 3.9.4 | **Última atualização:** 2026-01-20
