# dotfiles-arch

My personal Arch Linux dotfiles and configuration files for my desktop environment.

This repository serves two primary purposes:

* **Sharing** — Providing my configuration files for anyone who wants to use or reference them.
* **Backup** — Allowing me to quickly restore my environment after a major system failure, configuration issue, or kernel-related problem.

## Important Notes

This is my **first dotfiles repository**, so some configurations may still be incomplete, broken, or subject to change.

Before running the installation script, I recommend:

1. Installing [`yay`](https://github.com/Jguer/yay).
2. Updating your system with `pacman -Syu`.
3. Reviewing `install.sh` before executing it.

I will do my best to keep `install.sh` up to date with the packages and dependencies required for compatibility.

## Current Limitations

> **August 2026:** Most colors are currently hardcoded around a single theme.

I plan to improve the color system and make the theme more dynamic (using py-wal) in the near future.

## Disclaimer

These dotfiles are configured specifically for my own Arch Linux environment. They WILL require modification to work correctly on another system.

Review the configuration and installation scripts before using them on your own machine.
