#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$DOTFILES/$1"
    local dest="$HOME/$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "Backing up existing $dest -> $dest.bak"
        mv "$dest" "$dest.bak"
    fi
    ln -sf "$src" "$dest"
    echo "Linked $dest -> $src"
}

# -----------------------------
# Symlinks
# -----------------------------
link zsh/.zshrc .zshrc
link atuin/.config/atuin/config.toml .config/atuin/config.toml

# Create git/.gitconfig from template if it doesn't exist (kept out of git so
# clones don't inherit a previous user's name/email).
if [[ ! -f "$DOTFILES/git/.gitconfig" ]]; then
    cp "$DOTFILES/git/.gitconfig.template" "$DOTFILES/git/.gitconfig"
    echo "Created $DOTFILES/git/.gitconfig from template -- edit it with your name and email"
fi
link git/.gitconfig .gitconfig
link wezterm/.config/wezterm/wezterm.lua .config/wezterm/wezterm.lua
link wezterm/.config/wezterm/config.lua .config/wezterm/config.lua
link wezterm/.config/wezterm/events.lua .config/wezterm/events.lua
link wezterm/.config/wezterm/theme.lua .config/wezterm/theme.lua
link starship/starship.toml .config/starship.toml

# Create .zsh_local from template if it doesn't exist
if [[ ! -f "$HOME/.zsh_local" ]]; then
    cp "$DOTFILES/zsh/.zsh_local.template" "$HOME/.zsh_local"
    echo "Created ~/.zsh_local from template -- add your secrets and machine-specific config there"
fi

echo "Dotfiles synced."
