#!/usr/bin/env bash
# Instala el buscador enlazando los archivos del repo (los cambios se aplican sin reinstalar)
# y asigna Super+Espacio.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
ICONS="$HOME/.local/share/buscador/icons"

mkdir -p "$BIN" "$(dirname "$ICONS")"
ln -sfn "$DIR/buscador" "$BIN/buscador"
[ -L "$ICONS" ] || rm -rf "$ICONS"
ln -sfn "$DIR/icons" "$ICONS"

KEY=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/buscador/
SCHEMA=org.gnome.settings-daemon.plugins.media-keys
list=$(gsettings get $SCHEMA custom-keybindings)
if ! grep -q "custom-keybindings/ulauncher/\|$KEY" <<<"$list"; then
    if [ "$list" = "@as []" ]; then list="['$KEY']"; else list="${list%]}, '$KEY']"; fi
    gsettings set $SCHEMA custom-keybindings "$list"
    gsettings set $SCHEMA.custom-keybinding:$KEY name "Buscador"
    gsettings set $SCHEMA.custom-keybinding:$KEY command "$BIN/buscador"
    gsettings set $SCHEMA.custom-keybinding:$KEY binding "<Super>space"
fi
command -v fdfind >/dev/null || command -v fd >/dev/null || echo "Aviso: instala fd para buscar archivos (sudo apt install fd-find)"
command -v gh >/dev/null || echo "Aviso: instala gh para la pestaña GitHub"
echo "Buscador instalado. Pulsa Super+Espacio."
