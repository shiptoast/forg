# forg

## Codespaces

This repo includes a devcontainer configuration that installs the Pico-8 Linux binary during Codespace creation.

1. Place the official Pico-8 Linux distribution in `pico8/` at the repo root (it should contain `pico8` and `pico8.dat`).
2. Create or rebuild the Codespace to run the installer.

The setup script will install Pico-8 under `/opt/pico8` and symlink `/usr/local/bin/pico8`.
