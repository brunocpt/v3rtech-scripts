#!/bin/bash
# Script de instalação de aplicativos para o sistema via flatpak

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


