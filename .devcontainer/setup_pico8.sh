#!/usr/bin/env bash
set -euo pipefail

if command -v pico8 >/dev/null 2>&1; then
  echo "pico8 already installed."
  exit 0
fi

if [[ -z "${PICO8_URL:-}" ]]; then
  cat <<'MESSAGE'
PICO8_URL is not set. To install pico8 in this Codespace:
1. Upload/download the pico8 Linux archive to a private URL.
2. Add PICO8_URL as a Codespaces secret or env var.
3. Rebuild the container.
MESSAGE
  exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive_path="$tmp_dir/pico8.zip"

curl -fsSL "$PICO8_URL" -o "$archive_path"
unzip -q "$archive_path" -d "$tmp_dir"

pico8_dat="$(find "$tmp_dir" -type f -name 'pico8.dat' | head -n 1)"
if [[ -z "$pico8_dat" ]]; then
  echo "Unable to locate pico8.dat in downloaded archive."
  exit 1
fi

pico8_dir="$(dirname "$pico8_dat")"
install_dir="/opt/pico8"

rm -rf "$install_dir"
mkdir -p "$install_dir"
cp -R "$pico8_dir"/* "$install_dir"/

chmod +x "$install_dir/pico8"
ln -sf "$install_dir/pico8" /usr/local/bin/pico8

echo "pico8 installed to $install_dir."
