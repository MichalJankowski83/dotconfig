# dotconfig
Linux console environment: tmux (tpm + catppuccin) and neovim (kickstart.nvim).

## Setup on a new server

```sh
git clone https://github.com/MichalJankowski83/dotconfig.git ~/dotconfig
~/dotconfig/install.sh        # SKIP_PKGS=1 to skip package install
```

- tmux: prefix `Ctrl+Space`, windows/panes start at 1, catppuccin (mocha). Plugins are installed by tpm; later use `prefix + I`.
- nvim: installs the latest neovim release from GitHub to `~/.local/nvim` (symlink in `~/.local/bin`; `SKIP_NVIM=1` to skip) and clones kickstart.nvim to `~/.config/nvim`. To keep your own changes, copy that config into `nvim/` in this repo (without `.git`) and commit it; the script will symlink it instead.

- vim: plugin-free im/vimrc symlinked to ~/.vimrc (relative numbers, 4-space indent, smart-case search, persistent undo in ~/.vim/state, Space leader).
