#!/usr/bin/env bash
# Symlink dotfiles into $HOME. Existing files are moved to ~/.dotfiles-backup.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

link() {
	local src="$DOTFILES/$1" dst="$HOME/$1"
	if [[ -e "$dst" && ! -L "$dst" ]]; then
		mkdir -p "$BACKUP/$(dirname "$1")"
		mv "$dst" "$BACKUP/$1"
	fi
	mkdir -p "$(dirname "$dst")"
	ln -sfn "$src" "$dst"
	echo "linked $1"
}

for f in .zshrc .zprofile .tmux.conf .yabairc; do link "$f"; done
for d in sketchybar nvim yabai zed; do link ".config/$d"; done

# Spicetify keeps its config in ~/.config/spicetify
link .config/spicetify
command -v spicetify >/dev/null && spicetify apply || true
