#!/usr/bin/env bash
# Bootstrap tmux (+tpm, catppuccin) and neovim (kickstart) on a new Linux server.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

install_pkgs() {
  local pkgs=(tmux vim git curl make gcc unzip ripgrep fd-find)
  local sudo=""
  [ "$(id -u)" -ne 0 ] && sudo="sudo"
  if command -v apt-get >/dev/null; then
    $sudo apt-get update && $sudo apt-get install -y "${pkgs[@]}"
  elif command -v dnf >/dev/null; then
    $sudo dnf install -y tmux vim git curl make gcc unzip ripgrep fd-find
  elif command -v pacman >/dev/null; then
    $sudo pacman -Sy --needed --noconfirm tmux vim git curl make gcc unzip ripgrep fd
  else
    echo "Unsupported package manager; install tmux, neovim, git manually." >&2
  fi
}

install_nvim() {
  case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported arch for nvim release" >&2; return 1 ;;
  esac
  local dest="$HOME/.local/nvim"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" -o "$tmp/nvim.tgz"
  rm -rf "$dest" && mkdir -p "$dest" "$HOME/.local/bin"
  tar -xzf "$tmp/nvim.tgz" -C "$dest" --strip-components=1
  ln -sfn "$dest/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo 'Add ~/.local/bin to PATH (export PATH="$HOME/.local/bin:$PATH")' ;; esac
}

install_tree_sitter() {
  case "$(uname -m)" in
    x86_64) arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported arch for tree-sitter" >&2; return 1 ;;
  esac
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-${arch}.gz" \
    | gunzip > "$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"
}

link() {  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
}

[ "${SKIP_PKGS:-0}" = "1" ] || install_pkgs
[ "${SKIP_NVIM:-0}" = "1" ] || { install_nvim; install_tree_sitter; }

# tmux
link "$REPO_DIR/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
link "$REPO_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

# vim: plain vimrc
link "$REPO_DIR/vim/vimrc" "$HOME/.vimrc"

# neovim: kickstart.nvim, with local customisations kept in this repo
if [ ! -e "$CONFIG_DIR/nvim" ]; then
  if [ -d "$REPO_DIR/nvim" ]; then
    link "$REPO_DIR/nvim" "$CONFIG_DIR/nvim"
  else
    git clone https://github.com/nvim-lua/kickstart.nvim.git "$CONFIG_DIR/nvim"
  fi
fi

echo "Done. Start tmux, then run nvim once to let kickstart install plugins."
