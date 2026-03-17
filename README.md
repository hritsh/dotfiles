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
