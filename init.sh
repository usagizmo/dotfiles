#!/bin/bash

# ======================
# 🔧 ヘルパー関数
# ======================

# dst が無ければ src へのシンボリックリンクを作成する。
# 既存 symlink がこの dotfiles repo 内を指している場合は、移動後の src へ更新する。
link_if_absent() {
  local src=$1 dst=$2 current repo_root
  repo_root="$(pwd)"
  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "⏭️ $dst のシンボリックリンクは既に存在します"
    elif [ "${current#$repo_root/}" != "$current" ]; then
      ln -sfn "$src" "$dst"
      echo "🔁 シンボリックリンクを更新しました: $dst -> $src"
    else
      echo "⏭️ $dst は別の場所を指しているためスキップします: $current"
    fi
  elif [ -e "$dst" ]; then
    echo "⏭️ $dst は既に存在します"
  elif ln -s "$src" "$dst" 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: $dst -> $src"
  fi
}

# リポジトリ内に相対パス target へのシンボリックリンクを作成する。
# 既存 symlink が別 target を向いている場合は更新する。
link_repo_relative() {
  local target=$1 path=$2 current
  if [ -L "$path" ]; then
    current="$(readlink "$path")"
    if [ "$current" = "$target" ]; then
      echo "⏭️ $path のシンボリックリンクは既に存在します"
    else
      ln -sfn "$target" "$path"
      echo "🔁 シンボリックリンクを更新しました: $path -> $target"
    fi
  elif [ -e "$path" ]; then
    echo "⏭️ $path は既に存在します"
  elif ln -s "$target" "$path" 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: $path -> $target"
  fi
}

# 既存の実ファイルを削除して src へのシンボリックリンクに置き換える
link_replace() {
  local src=$1 dst=$2 current
  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "⏭️ $dst は既にシンボリックリンクです"
    else
      ln -sfn "$src" "$dst"
      echo "🔁 シンボリックリンクを更新しました: $dst -> $src"
    fi
    return
  fi
  if [ -e "$dst" ]; then
    rm "$dst"
    echo "🗑️ 既存のファイルを削除しました: $dst"
  fi
  if ln -s "$src" "$dst" 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: $dst -> $src"
  fi
}

# ディレクトリが無ければ作成する
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "✅ ディレクトリを作成しました: $1"
  fi
}


# ======================
# 🤖 Claude 設定のセットアップ
# ======================

link_if_absent "$(pwd)/harnesses/claude" ~/.claude


# ======================
# 🤖 Codex 設定のセットアップ
# ======================

link_if_absent "$(pwd)/harnesses/codex" ~/.codex


# ======================
# 🐙 GitHub Copilot 設定のセットアップ
# ======================

link_if_absent "$(pwd)/harnesses/copilot" ~/.copilot


# ======================
# 🤖 Cursor CLI / Agent 設定のセットアップ
# ======================

link_if_absent "$(pwd)/harnesses/cursor" ~/.cursor


# ======================
# 🤖 Devin CLI 設定のセットアップ
# ======================

ensure_dir ~/.config
link_if_absent "$(pwd)/harnesses/devin" ~/.config/devin


# ======================
# 🤖 Agents 設定のセットアップ
# ======================

link_if_absent "$(pwd)/agents" ~/.agents


# ======================
# 🔧 Tmux 設定のセットアップ
# ======================

link_if_absent "$(pwd)/tmux/.tmux.conf" ~/.tmux.conf

# tmux plugin manager (tpm) のセットアップ
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm をインストールしています..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "✅ tpm をインストールしました: ~/.tmux/plugins/tpm"
else
  echo "⏭️ tpm は既にインストールされています"
fi


# ======================
# 🔧 mise (ランタイムバージョン管理) のセットアップ
# ======================

ensure_dir ~/.config/mise
link_if_absent "$(pwd)/mise/config.toml" ~/.config/mise/config.toml

# ツールのインストール
if [ -x "$(command -v mise)" ]; then
  mise trust "$(pwd)/mise/config.toml"
  echo "📦 mise でツールをインストールしています..."
  mise install
  echo "✅ mise のツールをインストールしました"
else
  echo "⚠️ mise がインストールされていません。brew install mise を実行してください"
fi


# ======================
# 🐠 Fish 設定のセットアップ
# ======================

ensure_dir ~/.config/fish
link_if_absent "$(pwd)/fish/config.fish" ~/.config/fish/config.fish

# Fish 機密環境変数設定のセットアップ
ensure_dir ~/.local/fish

# env.fish のコピー（既存ファイルがある場合は上書きしない）
if [ -e ~/.local/fish/env.fish ]; then
  echo "⏭️ ~/.local/fish/env.fish は既に存在します"
else
  if cp "$(pwd)/fish/env.fish" ~/.local/fish/env.fish 2>/dev/null; then
    echo "✅ ファイルをコピーしました: ~/.local/fish/env.fish <- $(pwd)/fish/env.fish"
    echo "📝 ~/.local/fish/env.fish を編集して環境変数を設定してください"
  fi
fi

# Fisher (fish plugin manager) のセットアップ
if [ -x "$(command -v fish)" ]; then
  # fisher がインストールされているか確認
  if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "📦 fisher をインストールしています..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    echo "✅ fisher をインストールしました"
  else
    echo "⏭️ fisher は既にインストールされています"
  fi

  # bobthefish テーマのインストール
  if [ ! -f ~/.config/fish/fish_plugins ] || ! grep -q "oh-my-fish/theme-bobthefish" ~/.config/fish/fish_plugins 2>/dev/null; then
    echo "📦 bobthefish テーマをインストールしています..."
    fish -c "fisher install oh-my-fish/theme-bobthefish"
    echo "✅ bobthefish テーマをインストールしました"
  else
    echo "⏭️ bobthefish テーマは既にインストールされています"
  fi
else
  echo "⚠️ fish がインストールされていません。fisher とプラグインのセットアップをスキップします"
fi


# ======================
# 📝 Neovim 設定のセットアップ
# ======================

ensure_dir ~/.config/nvim
link_if_absent "$(pwd)/nvim/init.lua" ~/.config/nvim/init.lua
link_if_absent "$(pwd)/nvim/lua" ~/.config/nvim/lua


# ======================
# 📁 Yazi 設定のセットアップ
# ======================

ensure_dir ~/.config/yazi
link_if_absent "$(pwd)/yazi/yazi.toml" ~/.config/yazi/yazi.toml
link_if_absent "$(pwd)/yazi/theme.toml" ~/.config/yazi/theme.toml

# Catppuccin Dracula テーマのインストール
if [ -x "$(command -v ya)" ]; then
  if [ ! -d ~/.config/yazi/flavors/dracula.yazi ]; then
    echo "📦 Catppuccin Dracula テーマをインストールしています..."
    ya pkg add yazi-rs/flavors:dracula
    echo "✅ Catppuccin Dracula テーマをインストールしました"
  else
    echo "⏭️ Catppuccin Dracula テーマは既にインストールされています"
  fi
else
  echo "⚠️ ya コマンドが見つかりません。Yazi のテーマインストールをスキップします"
fi


# ======================
# 👻 Ghostty 設定のセットアップ
# ======================

link_if_absent "$(pwd)/ghostty" ~/.config/ghostty


# ======================
# ⌨️ macOS キーバインディング設定のセットアップ
# ======================

ensure_dir ~/Library/KeyBindings
link_if_absent "$(pwd)/Library/KeyBindings/DefaultKeyBinding.dict" ~/Library/KeyBindings/DefaultKeyBinding.dict


# ======================
# 🖥️ Cursor IDE 設定のセットアップ
# ======================

# Cursor設定ディレクトリが存在する場合のみセットアップ
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
if [ -d "$CURSOR_USER_DIR" ]; then
  link_replace "$(pwd)/cursor-app/settings.json" "$CURSOR_USER_DIR/settings.json"
  link_replace "$(pwd)/cursor-app/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
else
  echo "⚠️ Cursor がインストールされていません。Cursor IDE 設定のセットアップをスキップします"
fi


# ======================
# 🐚 Zsh 設定のセットアップ
# ======================

link_if_absent "$(pwd)/zsh/.zshrc" ~/.zshrc
