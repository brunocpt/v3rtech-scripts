# Changelog - Versão 3.5.0

## [3.5.0] - 2025-12-21 (Sessão 5 - Boot Options Multi-Distro)

### ✨ Adicionado

#### Boot Options Multi-Distro
- **Configuração de Boot Options** em `03-prepara-configs.sh`:
  - **Debian/Ubuntu:** Configuração GRUB com opções otimizadas
  - **Arch Linux:** Configuração systemd-boot com opções otimizadas
  - **Fedora:** Configuração GRUB2 com opções otimizadas
  - **Opções Aplicadas:**
    - `quiet` - Suprime mensagens de boot
    - `splash` - Mostra splash screen
    - `loglevel=0` - Suprime logs do kernel
    - `systemd.show_status=false` - Suprime status do systemd
    - `rd.udev.log_level=0` - Suprime logs do udev
    - `zswap.enabled=1` - Ativa compressão de swap
  - Backup automático de /etc/default/grub
  - Regeneração automática de configuração de boot

#### Plymouth Multi-Distro
- **Suporte Completo a Plymouth** em `03-prepara-configs.sh`:
  - **Debian/Ubuntu:** Instalação simples com apt
  - **Arch Linux:** Configuração completa com:
    - Configuração de mkinitcpio.conf (adiciona plymouth aos HOOKS)
    - Regeneração de initramfs (mkinitcpio -P)
    - Configuração de boot options
    - Backup automático de arquivos críticos
  - **Fedora:** Instalação com dnf e regeneração de initramfs
  - Detecção automática de temas disponíveis
  - Tratamento de erros robusto

### 🔧 Corrigido

#### Bug 19: Plymouth Não Instalado em Arch/Fedora
- **Problema:** Script só instalava Plymouth para Debian/Ubuntu
- **Solução:** Implementada função `install_plymouth()` com suporte multi-distro
- **Impacto:** Agora Plymouth funciona em todas as distribuições suportadas

#### Bug 20: Boot Options Não Configuradas em Debian/Ubuntu/Fedora
- **Problema:** Boot options só eram configuradas no Arch Linux
- **Solução:** Implementadas funções `configure_grub_boot_options()` e `configure_grub2_boot_options()`
- **Impacto:** Agora boot é otimizado em todas as distribuições

### 📊 Estatísticas Atualizadas

- **Bugs Corrigidos:** 8 (sessão 1) + 8 (sessão 2) + 2 (sessão 3) + 2 (sessão 5) = **20 total**
- **Novos Scripts:** 10 (sessão 1) + 0 (sessão 2) + 1 (sessão 3) + 2 (sessão 4) = **13 total**
- **Scripts Melhorados:** 5 (sessão 1) + 3 (sessão 2) + 1 (sessão 3) + 1 (sessão 5) = **10 total**
- **Novas Funcionalidades:** 8 (sessão 1) + 6 (sessão 2) + 2 (sessão 3) + 4 (sessão 4) + 2 (sessão 5) = **22 total**
- **Documentos Atualizados:** 3 (sessão 1) + 6 (sessão 2) + 2 (sessão 3) + 2 (sessão 4) + 1 (sessão 5) = **14 total**

---

**Versão Atual:** 3.5.0
**Status:** ✅ Estável
**Última Atualização:** 2025-12-21
