#!/bin/bash
# ==============================================================================
# Script: fpk-system.sh
# Versão: 4.7.0
# Data: 2026-02-25
# Objetivo: Instalação de utilitários de sistema via Flatpak
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

# KDE Iso Image Writer
  sudo flatpak install -y flathub org.kde.isoimagewriter

# Bottles
  sudo flatpak install -y flathub com.usebottles.bottles

# Backups
  sudo flatpak install -y flathub io.github.vikdevelop.SaveDesktop

# RClone browser
  sudo flatpak install -y flathub io.github.pieterdd.RcloneShuttle

# Tiny Wii Backup Manager
  sudo flatpak install -y flathub it.mq1.TinyWiiBackupManager

# Letterpress
  sudo flatpak install -y flathub io.gitlab.gregorni.Letterpress

# FINALIZANDO A INSTALACAO
  echo "Instalacao concluida!"


