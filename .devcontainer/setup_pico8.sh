#!/usr/bin/env bash
set -euo pipefail

if command -v pico8 >/dev/null 2>&1; then
  echo "pico8 already installed."
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pico8_source="$repo_root/pico8"

if [[ ! -d "$pico8_source" || ! -f "$pico8_source/pico8.dat" ]]; then
  cat <<MESSAGE
Pico-8 files not found at $pico8_source.
Place the official Pico-8 Linux distribution in $pico8_source
so that pico8 and pico8.dat are present, then rebuild the container.
MESSAGE
  exit 0
fi

install_dir="/opt/pico8"

rm -rf "$install_dir"
mkdir -p "$install_dir"
cp -R "$pico8_source"/* "$install_dir"/

chmod +x "$install_dir/pico8"
ln -sf "$install_dir/pico8" /usr/local/bin/pico8

echo "pico8 installed to $install_dir."
