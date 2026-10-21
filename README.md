# dotfiles

My macOS setup. Tiling with yabai, a custom sketchybar, LazyVim, oh-my-zsh + p10k, and a themed Spotify via Spicetify.

## What's in here

| Path | What |
| --- | --- |
| `.config/sketchybar` | status bar (spaces, spotify, amphetamine, battery, wattage, notifications) |
| `.config/nvim` | LazyVim based config |
| `.config/spicetify` | Spicetify config, extensions and themes |
| `.yabairc`, `.config/yabai` | yabai window manager |
| `.config/zed` | Zed settings |
| `.zshrc`, `.zprofile`, `.tmux.conf` | shell + tmux |

## Install

```sh
git clone https://github.com/hritsh/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` symlinks everything into `$HOME` and backs up whatever was there first.

## Packages

Everything I have installed through Homebrew is in the `Brewfile`:

```sh
brew bundle --file ~/dotfiles/Brewfile
```

## sketchybar

- Font: GohuFont Nerd Font + `sketchybar-app-font` for the app glyphs in each space
- `plugins/wattage.swift` reads the SMC for live power draw; build it with `swiftc plugins/wattage.swift plugins/SMC.swift -o plugins/wattsec-cli`
- Notification counts come from the Dock badges (WhatsApp, Mail)

## Spicetify

Theme is the marketplace install of Glass. Small CSS fixes that the marketplace would overwrite live in `Extensions/tui-fixes.js` instead of `user.css`.

```sh
spicetify config current_theme marketplace color_scheme Glass
spicetify apply
```
