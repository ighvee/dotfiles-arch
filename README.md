[![StandWithPalestine](https://raw.githubusercontent.com/Safouene1/support-palestine-banner/master/StandWithPalestine.svg)](https://github.com/Safouene1/support-palestine-banner/blob/master/Markdown-pages/Support.md) ![TransRightsAreHumanRights](https://pride-badges.pony.workers.dev/static/v1?label=TransRightsAreHumanRights&stripeWidth=6&stripeColors=5BCEFA,F5A9B8,FFFFFF,F5A9B8,5BCEFA) ![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?logo=archlinux&logoColor=white) ![Hyprland](https://img.shields.io/badge/WM-Hyprland-00AEEF?logo=hyprland&logoColor=white)

# dotfiles-arch

My personal Arch Linux dotfiles and configuration files for my desktop environment.

This repository serves two primary purposes:

* **Sharing**: Providing my configuration files for anyone who wants to use or reference them.
* **Backup**: Allowing me to quickly restore my environment after a major system failure, configuration issue, or kernel-related problem.

## System Specifications

These dotfiles are currently configured around the following hardware and software environment:

* **CPU:** AMD Ryzen 7 9800X3D
* **GPU:** NVIDIA GeForce RTX 5080
* **Memory:** 32GB DDR5  of Crucial Overclocking Memory
* **Kernel:** Linux Zen (`linux-zen`)
* **NVIDIA Driver:** `nvidia-open-dkms`
* **Operating System:** Arch Linux
* **Desktop Environment:** Hyprland

## Important Notes

This is my **first dotfiles repository**, so some configurations may still be incomplete, broken, or subject to change.

Before running the installation script, I recommend:

1. Installing [`yay`](https://github.com/Jguer/yay).
2. Updating your system with `pacman -Syu`.
3. Reviewing `install.sh` before executing it.

I will do my best to keep `install.sh` up to date with the packages and dependencies required for compatibility.

## Current Limitations

> **August 2026:** Most colors are currently hardcoded around a single theme.

I plan to improve the color system and make the theme more dynamic using **pywal** in the near future.

## Disclaimer

These dotfiles are configured specifically for my own Arch Linux environment. They WILL require modification to work correctly on another system.

In particular, the included kernel and NVIDIA driver configuration is designed around my hardware.

Review the configuration and installation scripts before using them on your own machine.
