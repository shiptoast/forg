# forg

## Codespaces

This repo includes a devcontainer configuration that can install the Pico-8 Linux binary during Codespace creation.

1. Upload the official Pico-8 Linux archive to a private URL.
2. Add a Codespaces secret named `PICO8_URL` pointing at that archive.
3. Create or rebuild the Codespace to run the installer.

The setup script will install Pico-8 under `/opt/pico8` and symlink `/usr/local/bin/pico8`.
