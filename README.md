# V3RTECH Scripts v4.0

Suite completa de scripts de automação para instalação e configuração de sistemas Linux.

**Versão:** 4.7.0  
**Data:** 2026-02-25  
**Autor:** V3RTECH Tecnologia, Consultoria e Inovação  
**Website:** https://v3rtech.com.br/

---

## 📋 Características Principais

- **Modularidade Total:** Cada script é 100% independente e pode ser executado isoladamente
- **Multi-Distribuição:** Suporta Arch Linux, Debian/Ubuntu e Fedora automaticamente
- **Configuração Centralizada:** Arquivo `config.conf` compartilhado entre todos os scripts
- **Suporte a Imutáveis:** Detecção automática de distribuições imutáveis (Silverblue, Kinoite, etc)
- **Preferência de Instalação:** Pergunta uma única vez se prefere apps nativos ou Flatpak
- **Inputs Antecipados:** Todos os inputs são solicitados no início, sem interrupções
- **Tratamento de Erros:** Diferencia erros críticos de não-críticos
- **Logging Completo:** Registra todas as ações em arquivo de log
- **Comentários Detalhados:** Código bem documentado e fácil de entender

---

## 🚀 Início Rápido

### 1. Clonar o Repositório

```bash
git clone https://github.com/v3rtech/v3rtech-scripts.git
cd v3rtech-scripts
chmod +x v3rtech-install.sh
```

### 2. Executar o Script Principal

```bash
./v3rtech-install.sh
```

Isso abrirá um menu interativo com as seguintes opções:

1. **Executar setup COMPLETO** (recomendado para novo sistema)
2. **Instalar apenas apps essenciais**
3. **Configurar desktop**
4. **Instalar aplicativos**
5. **Configurar sistema**
6. **Executar script específico**
7. **Configurar preferências**
8. **Sair**

### 3. Executar Scripts Independentes

Você pode executar qualquer script isoladamente:

```bash
# Instalar apenas apps essenciais
./lib/install-essentials.sh

# Instalar apps de escritório
./lib/install-apps-office.sh

# Instalar Docker
./lib/install-docker.sh

# Configurar sistema
./lib/setup-system.sh
```

---

## 📁 Estrutura de Diretórios

```
v3rtech-scripts/
├── core/                      # Infraestrutura base
│   ├── config.conf           # Arquivo de configuração compartilhado
│   ├── env.sh                # Variáveis globais e caminhos
│   ├── logging.sh            # Funções de logging
│   └── package-mgr.sh        # Abstração de gerenciadores de pacotes
│
├── lib/                       # Scripts de instalação e configuração
│   ├── detect-system.sh      # Detecta distribuição, desktop, GPU
│   ├── install-essentials.sh # Apps essenciais (obrigatório)
│   ├── install-apps-*.sh     # Instalação de apps por categoria
│   ├── install-desktop-*.sh  # Instalação de ambientes desktop
│   ├── install-docker.sh     # Docker e Docker Compose
│   ├── install-ia-stack.sh   # Stack de IA/ML
│   ├── install-certificates.sh # Certificados ICP-Brasil
│   ├── install-virtualbox.sh # VirtualBox
│   ├── setup-system.sh       # Configuração de sistema
│   └── cleanup.sh            # Limpeza final
│
├── utils/                     # Utilitários e scripts especializados
│   └── [scripts do projeto original]
│
├── configs/                   # Arquivos de configuração
│   ├── aliases.geral         # Aliases globais
│   ├── cupsd.conf            # Configuração CUPS
│   └── [outros arquivos]
│
├── resources/                 # Recursos (atalhos, fontes, etc)
│   ├── atalhos/
│   └── fonts/
│
├── backups/                   # Backups automáticos
├── data/                      # Dados compartilhados
│
├── v3rtech-install.sh        # Script principal (orquestrador)
├── README.md                 # Este arquivo
├── ARCHITECTURE.md           # Documentação técnica
├── CHANGELOG.md              # Histórico de versões
└── LICENSE                   # Licença do projeto
```

---

## 🔧 Distribuições Suportadas

| Distribuição | Status | Notas |
|---|---|---|
| **Arch Linux** | ✅ Completo | Paru/Yay para AUR |
| **Debian** | ✅ Completo | Apt com apt-fast opcional |
| **Ubuntu** | ✅ Completo | Baseado em Debian |
| **Fedora** | ✅ Completo | DNF com skip-unavailable |
| **Fedora Silverblue** | ✅ Imutável | Flatpak automático |
| **Fedora Kinoite** | ✅ Imutável | Flatpak automático |
| **openSUSE** | ⚠️ Parcial | Não testado |
| **Solus** | ⚠️ Parcial | Não testado |

---

## 🖥️ Ambientes Desktop Suportados

| Desktop | Status | Notas |
|---|---|---|
| **KDE Plasma** | ✅ Completo | Totalmente suportado |
| **GNOME** | ✅ Completo | Totalmente suportado |
| **XFCE** | ✅ Completo | Totalmente suportado |
| **Deepin** | ✅ Completo | Totalmente suportado |
| **Cosmic** | ✅ Básico | Suporte limitado |

---

## 📦 Categorias de Aplicativos

Os scripts permitem instalar aplicativos em várias categorias:

- **Internet:** Navegadores, Nuvem, Comunicação
- **Escritório:** LibreOffice, PDF, OCR, Dicionários
- **Desenvolvimento:** IDEs, Ferramentas, Controle de Versão
- **Multimídia:** Áudio, Vídeo, Imagem
- **Design:** Vetorial, Raster, 3D, UI/UX
- **Sistema:** Gerenciadores, Backup, Monitoramento
- **Jogos:** Emuladores, Plataformas, Jogos Open Source

---

## ⚙️ Configuração Compartilhada

O arquivo `~/.config/v3rtech-scripts/config.conf` armazena:

- Informações da distribuição detectada
- Ambiente desktop
- Preferência de instalação (Nativo vs Flatpak)
- Categorias selecionadas
- Informações de GPU e sessão gráfica

Este arquivo é criado automaticamente na primeira execução e permite que scripts sejam executados independentemente.

---

## 🎯 Fluxo de Setup Completo

Quando você escolhe "Executar setup COMPLETO", a sequência é:

1. **Selecionar categorias de apps** (Internet, Escritório, Dev, etc)
2. **Instalar apps essenciais** (obrigatório)
3. **Configurar sistema** (PATH, aliases, sudoers)
4. **Configurar bookmarks, atalhos, mounts**
5. **Configurar desktop** (KDE, GNOME, XFCE, etc)
6. **Instalar apps selecionados** (por categoria)
7. **Instalar Docker** (opcional)
8. **Instalar Stack IA/ML** (opcional)
9. **Instalar certificados ICP-Brasil** (opcional)
10. **Instalar VirtualBox** (opcional)
11. **Limpeza final** (remove pacotes órfãos, limpa cache)

---

## 🔐 Segurança

- Scripts não precisam ser executados como root
- Sudo é usado apenas quando necessário
- Arquivo de configuração é criado com permissões restritas (700)
- Backups automáticos de arquivos críticos (cupsd.conf, sudoers)
- Validação de sintaxe para arquivos sensíveis

---

## 📝 Logging

Todos os eventos são registrados em:

```
~/.config/v3rtech-scripts/logs/v3rtech-install.log
```

O arquivo de log inclui:
- Timestamp de cada ação
- Tipo de mensagem (INFO, WARN, ERROR, SUCCESS)
- Descrição detalhada
- Informações do sistema

---

## 🐛 Tratamento de Erros

- **Erros Críticos:** Param a execução e pedem intervenção do usuário
- **Erros Não-Críticos:** Registram em log e continuam a execução
- **Validação:** Verifica dependências antes de executar

---

## 🤝 Contribuindo

Para contribuir com melhorias:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/melhoria`)
3. Commit suas mudanças (`git commit -am 'Adiciona melhoria'`)
4. Push para a branch (`git push origin feature/melhoria`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo `LICENSE` para detalhes.

---

## 📞 Suporte

Para reportar bugs ou sugerir melhorias, abra uma issue no repositório GitHub.

---

## 🔄 Histórico de Versões

Veja o arquivo `CHANGELOG.md` para um histórico completo de versões e mudanças.

---

## ✨ Agradecimentos

Desenvolvido pela V3RTECH Tecnologia, Consultoria e Inovação.

**Versão:** 4.7.0  
**Última atualização:** 2026-02-25
