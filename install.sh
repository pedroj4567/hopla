#!/usr/bin/env bash
# Installs the launcher by symlinking the repo files (changes apply without reinstalling)
# and binds Super+Space. Checks the requirements first ("doctor").
#   ./install.sh           check requirements, then install
#   ./install.sh --doctor  only check requirements
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
ICONS="$HOME/.local/share/buscador/icons"

# ---------- doctor ----------

if   command -v apt-get >/dev/null; then PM=apt
elif command -v dnf     >/dev/null; then PM=dnf
elif command -v pacman  >/dev/null; then PM=pacman
else PM=""; fi

# Package name for each requirement in the detected package manager.
pkg() {
    case "$PM:$1" in
        apt:python)    echo python3 ;;        dnf:python)    echo python3 ;;        pacman:python)    echo python ;;
        apt:gi)        echo python3-gi ;;     dnf:gi)        echo python3-gobject ;; pacman:gi)        echo python-gobject ;;
        apt:gtk)       echo gir1.2-gtk-4.0 ;; dnf:gtk)       echo gtk4 ;;           pacman:gtk)       echo gtk4 ;;
        apt:fd)        echo fd-find ;;        dnf:fd)        echo fd-find ;;        pacman:fd)        echo fd ;;
        apt:gh)        echo gh ;;             dnf:gh)        echo gh ;;             pacman:gh)        echo github-cli ;;
        *:nautilus)    echo nautilus ;;
        *)             echo "$1" ;;
    esac
}
install_cmd() {
    case "$PM" in
        apt)    echo "sudo apt install $*" ;;
        dnf)    echo "sudo dnf install $*" ;;
        pacman) echo "sudo pacman -S $*" ;;
        *)      echo "install with your package manager: $*" ;;
    esac
}

MISSING=()      # required packages
OPTIONAL=()     # optional packages
NOTES=()        # extra steps that are not packages
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

doctor() {
    echo "Checking requirements…"
    echo "Required:"

    if command -v gsettings >/dev/null &&
       gsettings list-schemas 2>/dev/null | grep -qx org.gnome.settings-daemon.plugins.media-keys; then
        ok "GNOME (gsettings, keyboard shortcuts)"
    else
        bad "GNOME desktop not detected: the Super+Space shortcut can't be created"
        NOTES+=("Run it on GNOME, or bind ~/.local/bin/buscador to a key in your desktop's settings.")
    fi

    if command -v python3 >/dev/null && python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
        ok "Python $(python3 -c 'import platform; print(platform.python_version())')"
    else
        bad "Python 3.9 or newer"
        MISSING+=("$(pkg python)")
    fi

    if command -v python3 >/dev/null && python3 -c 'import gi' 2>/dev/null; then
        ok "PyGObject"
        local gtk
        if gtk=$(python3 -c '
import gi; gi.require_version("Gtk", "4.0")
from gi.repository import Gtk
print(f"{Gtk.get_major_version()}.{Gtk.get_minor_version()}")' 2>/dev/null); then
            if [ "${gtk#4.}" -ge 12 ] 2>/dev/null; then
                ok "GTK $gtk"
            else
                bad "GTK $gtk is too old (4.12 or newer needed)"
                NOTES+=("Upgrade GTK 4 to 4.12+ (Ubuntu 24.04 / Fedora 39 or newer).")
            fi
        else
            bad "GTK 4 (introspection data)"
            MISSING+=("$(pkg gtk)")
        fi
    else
        bad "PyGObject (python3-gi)"
        MISSING+=("$(pkg gi)" "$(pkg gtk)")
    fi

    echo "Optional:"
    if command -v fdfind >/dev/null || command -v fd >/dev/null; then
        ok "fd (Files tab)"
    else
        warn "fd not found: the Files tab won't work"
        OPTIONAL+=("$(pkg fd)")
    fi

    if command -v gh >/dev/null; then
        if gh auth status --hostname github.com >/dev/null 2>&1; then
            ok "GitHub CLI, logged in (GitHub tab)"
        else
            warn "GitHub CLI is not logged in: the GitHub tab will be empty"
            NOTES+=("Log in to GitHub: gh auth login")
        fi
    else
        warn "GitHub CLI not found: the GitHub tab won't work"
        OPTIONAL+=("$(pkg gh)")
        NOTES+=("After installing gh, log in: gh auth login")
    fi

    if command -v nautilus >/dev/null; then
        ok "Nautilus (Ctrl+Enter on files)"
    else
        warn "Nautilus not found: Ctrl+Enter opens the folder with the default file manager"
    fi

    if command -v code >/dev/null; then
        ok "VS Code (Ctrl+Enter on cloned repos)"
    else
        warn "VS Code ('code') not found: Ctrl+Enter on cloned repos won't work"
        NOTES+=("Install VS Code from https://code.visualstudio.com if you want Ctrl+Enter on repos.")
    fi

    case ":$PATH:" in
        *":$BIN:"*) ok "$BIN is in PATH" ;;
        *) warn "$BIN is not in PATH: the shortcut works, but typing 'buscador' in a terminal won't"
           NOTES+=("Add to ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\"") ;;
    esac

    echo
    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "Missing (required):"
        echo "  $(install_cmd "${MISSING[@]}")"
    fi
    if [ ${#OPTIONAL[@]} -gt 0 ]; then
        echo "Missing (optional):"
        echo "  $(install_cmd "${OPTIONAL[@]}")"
    fi
    if [ ${#NOTES[@]} -gt 0 ]; then
        echo "Also:"
        printf '  - %s\n' "${NOTES[@]}"
    fi
    if [ ${#MISSING[@]} -eq 0 ] && [ ${#OPTIONAL[@]} -eq 0 ] && [ ${#NOTES[@]} -eq 0 ]; then
        echo "Everything is installed."
    fi
    [ ${#MISSING[@]} -eq 0 ]
}

if [ "${1:-}" = "--doctor" ]; then
    doctor
    exit
fi
if ! doctor; then
    echo
    echo "Install the required packages above and run ./install.sh again."
    exit 1
fi
echo

# ---------- install ----------

mkdir -p "$BIN" "$(dirname "$ICONS")"
ln -sfn "$DIR/buscador" "$BIN/buscador"
[ -L "$ICONS" ] || rm -rf "$ICONS"
ln -sfn "$DIR/icons" "$ICONS"

KEY=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/buscador/
SCHEMA=org.gnome.settings-daemon.plugins.media-keys
if command -v gsettings >/dev/null && gsettings list-schemas 2>/dev/null | grep -qx $SCHEMA; then
    list=$(gsettings get $SCHEMA custom-keybindings)
    if ! grep -q "custom-keybindings/ulauncher/\|$KEY" <<<"$list"; then
        if [ "$list" = "@as []" ]; then list="['$KEY']"; else list="${list%]}, '$KEY']"; fi
        gsettings set $SCHEMA custom-keybindings "$list"
        gsettings set $SCHEMA.custom-keybinding:$KEY name "Buscador"
        gsettings set $SCHEMA.custom-keybinding:$KEY command "$BIN/buscador"
        gsettings set $SCHEMA.custom-keybinding:$KEY binding "<Super>space"
    fi
    echo "Installed. Press Super+Space."
else
    echo "Installed at $BIN/buscador (no GNOME shortcut was created)."
fi
