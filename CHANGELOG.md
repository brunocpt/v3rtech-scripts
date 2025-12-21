# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

## [3.2.0] - 2025-12-21 (Sessão 3 - Whisper e Filebot Finalizados)

### ✨ Adicionado

#### Instalação de Whisper
- **Script `11-setup-whisper.sh`** (NOVO): Instalação especializada de OpenAI Whisper com:
  - Detecção automática de GPU (NVIDIA/AMD/None)
  - Limpeza de instalações anteriores
  - Instalação com flag `--force`
  - Injeção automática de CUDA para NVIDIA
  - Criação de link simbólico em `/usr/bin/whisper`
  - Verificação de sucesso
  - Criação de diretório de cache
- **Função `post_install_whisper()`** em `logic-apps-reader.sh`: Reconfiguração automática de Whisper

### 🛠️ Corrigido

#### Bugs Críticos (Sessão 3)

17. **Bug de Licença do Filebot Não Aplicada** (MÉDIO):
    - **Problema:** Comando `flatpak run net.filebot.FileBot --license /caminho` não funcionava
    - **Solução:** Usar `cat /caminho | flatpak run net.filebot.FileBot --license`
    - **Resultado:** Licença agora aplicada corretamente

18. **Bug de Whisper Não Instalado Corretamente** (CRÍTICO):
    - **Problema:** Instalação simples de Whisper sem limpeza, --force, GPU, CUDA ou link simbólico
    - **Causa:** Script apenas fazia `pipx install openai-whisper` sem configurações adicionais
    - **Solução:** Implementado script especializado `11-setup-whisper.sh` com:
      - Detecção de GPU (NVIDIA/AMD/None)
      - Limpeza de instalações anteriores
      - Instalação com `--force`
      - Injeção de CUDA para NVIDIA
      - Link simbólico em `/usr/bin/whisper`
      - Verificação de sucesso
    - **Resultado:** Whisper instala corretamente com suporte a GPU

## [3.1.0] - 2025-12-21 (Sessão 2 - Correções Finais)

### 💥 Mudanças Críticas (Breaking Changes)
- **Rsync Mirror para Cópia:** Substituído `cp -r` por `rsync -av --delete` em `v3rtech-install.sh` para garantir cópia completa e idempotente de todos os arquivos (incluindo ocultos e diretórios vazios).
- **Extração Dinâmica de Mounts:** Script `09-setup-fstab-mounts.sh` agora extrai pontos de montagem dinamicamente do arquivo `fstab.lan` em vez de hardcoding.

### ✨ Adicionado

#### Infraestrutura & Build
- **Cópia com Rsync:** Implementado `rsync -av --delete --exclude` em `v3rtech-install.sh` para mirror perfeito do projeto.
- **Verificação de Rsync:** Script verifica e instala rsync automaticamente se não estiver disponível.
- **Remoção de .git:** Após cópia com rsync, remove diretório `.git` desnecessário.

#### Configuração de Mounts de Rede
- **Extração Dinâmica de Diretórios:** `09-setup-fstab-mounts.sh` lê `fstab.lan` e extrai pontos de montagem automaticamente.
- **Suporte a Hostnames:** Integração com `configs/hosts` para resolver nomes em vez de IPs (flexibilidade em mudanças de IP).
- **Criação Automática de Diretórios:** Cria diretórios de montagem conforme necessário, baseado no conteúdo de `fstab.lan`.

#### Desktop Entries
- **Criação de Atalhos de Menu:** Implementado em `03-prepara-configs.sh` para criar `.desktop` entries para scripts utilitários.
- **Suporte a Ícones:** Cada script tem ícone associado em `resources/atalhos/`.
- **Integração com Ambientes:** Funciona em KDE, GNOME, XFCE, LXDE e outros.

#### Configuração de Filebot
- **Pós-Instalação Automática:** Novo sistema de `post_install_apps()` que testa e configura apps após instalação.
- **Função `post_install_filebot()`:** Configura Filebot automaticamente:
  - Aplica licença (se arquivo existir)
  - Configura OpenSubtitles v2
  - Aplica credenciais OpenSubtitles
- **Arquivo de Credenciais:** `configs/filebot-osdb.conf` para armazenar credenciais de forma segura.

#### Configuração Global de Flatpak
- **Permissões Padrão:** Implementado `configure_flatpak_global()` que aplica permissões a TODOS os Flatpaks:
  - Acesso a temas do sistema (`/usr/share/themes`)
  - Acesso a configurações GTK (`xdg-config/gtk-3.0:ro`, `xdg-config/gtk-4.0:ro`)
  - Acesso a pastas de trabalho (`/mnt/trabalho`)
  - Acesso a scripts locais (`/usr/local`)
  - Permissões de bus (notificações, tray, system-bus, session-bus)
- **Chamada Automática:** Integrada em `select_and_install_apps()` para ser executada uma única vez.

#### Proteção Contra Loops de Symlinks
- **Detecção de Loops:** Adicionada função `create_safe_symlink()` em `07-setup-user-dirs.sh`.
- **Resolução de Caminhos Reais:** Resolve caminhos sem symlinks antes de criar novo link.
- **Avisos Claros:** Registra avisos se loop for detectado.

### 🛠️ Corrigido

#### Bugs Críticos (Sessão 2)

9. **Bug de Cópia Incompleta de Arquivos** (CRÍTICO):
   - **Problema:** `cp -r "$SCRIPT_DIR/"*` não copiava arquivos ocultos, `configs/bookmarks`, `configs/fstab.lan`
   - **Causa:** Expansão de `*` não inclui arquivos ocultos e pode falhar com muitos arquivos
   - **Solução:** Substituído por `rsync -av --delete` que copia TUDO incluindo ocultos
   - **Verificação:** Rsync verificado e instalado automaticamente se necessário

10. **Bug de Diretórios de Rede Hardcoded** (MÉDIO):
    - **Problema:** `07-setup-user-dirs.sh` criava `/mnt/LAN/{...}` hardcoded
    - **Causa:** Falta de flexibilidade para adicionar novos mounts
    - **Solução:** Movido para `09-setup-fstab-mounts.sh` com extração dinâmica
    - **Resultado:** Adicionar novo mount = apenas editar `fstab.lan`

11. **Bug de Expansão de Brace com Sudo** (MÉDIO):
    - **Problema:** `$SUDO mkdir -p /mnt/LAN/{DNS320L,AppData,...}` não expandia chaves
    - **Causa:** Shell não expande braces quando precedido por `$SUDO`
    - **Solução:** Usar `$SUDO bash -c 'mkdir -p /mnt/LAN/{...}'` ou loop for
    - **Resultado:** Diretórios criados corretamente

12. **Bug de Bookmarks Não Copiados** (MÉDIO):
    - **Problema:** `07-setup-user-dirs.sh` criava bookmarks hardcoded em vez de copiar `configs/bookmarks`
    - **Solução:** Verifica se arquivo existe e copia; se não, cria padrão
    - **Resultado:** Mudanças em `configs/bookmarks` são aplicadas automaticamente

13. **Bug de Variável `$INSTALL_TARGET` Não Definida** (MÉDIO):
    - **Problema:** `09-setup-fstab-mounts.sh` usava `$INSTALL_TARGET` que não era exportada
    - **Solução:** Substituído por `$BASE_DIR` que é definida em `core/env.sh` e exportada
    - **Resultado:** Script encontra arquivos de configuração corretamente

14. **Bug de Loop de Symlinks** (MÉDIO):
    - **Problema:** `07-setup-user-dirs.sh` criava `~/Desktop/Cloud → /mnt/trabalho/Cloud` que poderia ser circular
    - **Causa:** Falta de verificação de loops
    - **Solução:** Adicionada função `create_safe_symlink()` que detecta loops
    - **Resultado:** Navegadores de arquivos não ficam em loop infinito

15. **Bug de Filebot Sem Configuração** (MÉDIO):
    - **Problema:** Filebot instalado mas não configurado (licença, OpenSubtitles, credenciais)
    - **Solução:** Implementado `post_install_filebot()` que:
      - Testa se Filebot está instalado
      - Aplica licença automaticamente
      - Configura OpenSubtitles v2
      - Aplica credenciais de arquivo de configuração
    - **Resultado:** Filebot pronto para usar após instalação

16. **Bug de Configurações Globais do Flatpak Não Aplicadas** (MÉDIO):
    - **Problema:** `configure_flatpak_global()` definida mas não chamada
    - **Solução:** Integrada em `select_and_install_apps()` para ser chamada automaticamente
    - **Resultado:** Todos os Flatpaks têm permissões corretas

### 📋 Melhorias

#### Qualidade de Código
- **Função `install_flatpak()`:** Centraliza lógica de instalação de Flatpak com suporte a múltiplas distros.
- **Função `post_install_apps()`:** Extensível para adicionar pós-instalação de outros apps.
- **Marcadores de Bloco:** Todos os scripts usam `BEGIN`/`END` para idempotência verdadeira.
- **Logging Detalhado:** Mensagens claras de sucesso/erro em todas as operações.

#### Documentação
- **Guia de Filebot:** `FILEBOT_POS_INSTALACAO_SIMPLIFICADA.md` explica abordagem simplificada.
- **Guia de Flatpak:** `FILEBOT_FLATPAK_FINAL_CORRIGIDO.md` documenta configurações globais.
- **Guia de Mounts:** `SOLUCAO_DINAMICA_MOUNT_DIRS.md` explica extração dinâmica.
- **Guia de Symlinks:** `BUG_FIX_SYMLINK_LOOP.md` explica proteção contra loops.

#### Segurança
- **Arquivo de Credenciais:** `configs/filebot-osdb.conf` com permissões `600`.
- **Não no Git:** Arquivo adicionado a `.gitignore` automaticamente.
- **Proteção contra Loops:** Detecção de symlinks circulares.

#### Flexibilidade
- **Mounts Dinâmicos:** Adicionar novo mount = editar `fstab.lan` (sem editar script).
- **Hosts Dinâmicos:** Usar nomes em vez de IPs (flexibilidade em mudanças de IP).
- **Pós-Instalação Extensível:** Fácil adicionar configuração para outros apps.

### 📊 Estatísticas

- **Bugs Corrigidos:** 8 (sessão 1) + 8 (sessão 2) + 2 (sessão 3) = **18 total**
- **Novos Scripts:** 10 (sessão 1) + 0 (sessão 2) + 1 (sessão 3) = **11 total**
- **Scripts Melhorados:** 5 (sessão 1) + 3 (sessão 2) + 1 (sessão 3) = **9 total**
- **Novas Funcionalidades:** 8 (sessão 1) + 6 (sessão 2) + 2 (sessão 3) = **16 total**
- **Documentos Atualizados:** 3 (sessão 1) + 6 (sessão 2) + 2 (sessão 3) = **11 total**

### 🔄 Fluxo de Execução Completo

```
v3rtech-install.sh
├── 00-detecta-distro.sh (Detecta sistema)
├── 01-prepara-distro.sh (Instala dependências + YAD)
├── 02-setup-repos.sh (Configura repositórios)
├── 03-prepara-configs.sh (Limpa PATH + cria desktop entries)
├── 04-pack-*.sh (Instala apps de desktop)
├── 05-setup-sudoers.sh (Configura sudo sem senha)
├── 06-setup-shell-env.sh (Configura shell + aliases)
├── 07-setup-user-dirs.sh (Diretórios + bookmarks + symlinks)
├── 08-setup-maintenance.sh (Scripts de manutenção)
├── 09-setup-fstab-mounts.sh (Mounts de rede + hosts)
├── 10-setup-keyboard-shortcuts.sh (Atalhos de teclado)
├── 13-pack-vm.sh (Otimizações VM, se aplicável)
├── 99-limpeza-final.sh (Limpeza final)
└── post_install_apps() (Pós-instalação: Filebot, etc)
```

### ✅ Checklist de Testes

- ✅ YAD instalado antes de ser usado
- ✅ Múltiplos pacotes instalados corretamente
- ✅ Scripts de desktop chamados para todos os ambientes
- ✅ PATH não duplica mais
- ✅ Configurações restauradas mesmo sem app instalado
- ✅ Bash.bashrc não corrompido
- ✅ Configs-zip.sh com verificação de erro
- ✅ Bookmarks copiados corretamente
- ✅ Mounts de rede configurados dinamicamente
- ✅ Diretórios de rede criados automaticamente
- ✅ Symlinks sem loops
- ✅ Filebot configurado automaticamente
- ✅ Credenciais OpenSubtitles aplicadas
- ✅ Flatpak com permissões globais
- ✅ Rsync copia tudo corretamente

### 🚀 Próximos Passos

1. Testar em múltiplas distribuições (Debian, Fedora, Arch)
2. Testar em múltiplos ambientes de desktop (KDE, GNOME, XFCE, LXQT)
3. Validar pós-instalação de outros apps
4. Documentar processo de adição de novos apps com pós-instalação
5. Implementar testes automatizados

---

## [3.0.0] - 2025-12-21 (Sessão 1 - Correções Iniciais)

### 💥 Mudanças Críticas (Breaking Changes)
- **Reordenação de Execução:** O script `01-prepara-distro.sh` agora é executado ANTES da confirmação visual (YAD), garantindo que YAD esteja instalado antes de ser usado.
- **Idempotência Verdadeira:** Todos os scripts agora usam marcadores de bloco (`BEGIN`/`END`) para remoção segura de conteúdo anterior, permitindo execução múltipla sem duplicação.

### ✨ Adicionado

#### Core & Infraestrutura
- **Função `clean_path()`** em `core/package-mgr.sh`: Remove entradas duplicadas do PATH usando array associativo.
- **Verificação Crítica de YAD** em `01-prepara-distro.sh`: Se YAD não for instalado na primeira tentativa, tenta instalação alternativa com flags específicas por distro.
- **Script `clean-path-NUCLEAR.sh`**: Utilitário standalone que remove TODAS as linhas de PATH duplicadas e injeta uma única linha limpa.
- **Script `diagnose-path.sh`**: Ferramenta de diagnóstico que encontra todas as linhas que modificam PATH em múltiplos arquivos.

#### Configuração de Ambiente
- **Script `05-setup-sudoers.sh`** (NOVO): Configura sudo sem senha de forma segura.
- **Script `06-setup-shell-env.sh`** (MELHORADO): Configuração idempotente de `.bashrc` com aliases e funções.
- **Script `07-setup-user-dirs.sh`** (MELHORADO): Links simbólicos, bookmarks GTK, diretórios XDG, FUSE.
- **Script `08-setup-maintenance.sh`** (NOVO): Scripts de manutenção do sistema.

#### Configuração de Desktop
- **Script `04-pack-kde.sh`** (MELHORADO): Pacotes expandidos.
- **Script `04-pack-gnome.sh`** (MELHORADO): Pacotes expandidos.
- **Script `04-pack-xfce.sh`** (MELHORADO): Pacotes expandidos.
- **Script `04-pack-lxqt.sh`** (NOVO): Suporte completo para LXQT.
- **Script `04-pack-tiling-wm.sh`** (NOVO): Suporte para Tiling Window Managers.
- **Script `09-setup-fstab-mounts.sh`** (NOVO): Configura mounts de rede.
- **Script `10-setup-keyboard-shortcuts.sh`** (NOVO): Restaura atalhos de teclado.

#### Utilitários
- **Função `restore_zip_config()`** em `core/package-mgr.sh`: Restaura configurações de arquivos ZIP.
- **Script `clean-path.sh`** (DEFINITIVO): Remove todas as linhas de PATH.
- **Script `03-prepara-configs.sh`** (FINAL): Limpeza automática de PATH.

### 🛠️ Corrigido

#### Bugs Críticos
1. **Bug do YAD não instalado** (CRÍTICO)
2. **Bug de Múltiplos Pacotes** (CRÍTICO)
3. **Bug de Scripts de Desktop não Chamados** (CRÍTICO)
4. **Bug de PATH Duplicado Exponencial** (CRÍTICO)
5. **Bug de Restauração de Configurações** (MÉDIO)
6. **Bug de Arquivo Bash.bashrc Corrompido** (MÉDIO)
7. **Bug em `configs-zip.sh`** (MÉDIO)
8. **Bug de Funcionalidades Não Portadas** (MÉDIO)

---

**Versão Atual:** 3.2.0
**Status:** ✅ Estável
**Última Atualização:** 2025-12-21
