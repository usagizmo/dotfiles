#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ======================
# 🔧 ヘルパー関数
# ======================

# ディレクトリが無ければ作成する
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "✅ ディレクトリを作成しました: $1"
  fi
}

link_path() {
  local src=$1 dst=$2 current parent
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    echo "⚠️ symlink 元が存在しないためスキップします: $src"
    return 1
  fi
  parent="$(dirname "$dst")"
  ensure_dir "$parent"
  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "⏭️ $dst のシンボリックリンクは既に存在します"
    elif [ "${current#$DOTFILES_DIR/}" != "$current" ]; then
      ln -sfn "$src" "$dst"
      echo "🔁 シンボリックリンクを更新しました: $dst -> $src"
    else
      echo "⚠️ $dst は別の場所を指しているためスキップします: $current"
    fi
  elif [ -d "$dst" ]; then
    echo "⚠️ $dst は実ディレクトリです。symlink 作成をスキップします"
  elif [ -e "$dst" ]; then
    echo "⚠️ $dst は実ファイルです。symlink 作成をスキップします"
  elif ln -s "$src" "$dst" 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: $dst -> $src"
  fi
}

link_from_repo() {
  link_path "$DOTFILES_DIR/$1" "$2"
}

link_agent_skills() {
  local dst=$1 skill link
  ensure_dir "$dst"
  for skill in "$DOTFILES_DIR"/agents/skills/*; do
    [ -d "$skill" ] || [ -L "$skill" ] || continue
    link_path "$skill" "$dst/$(basename "$skill")"
  done
  # repo から削除された skill 等の壊れた symlink を掃除する（正常なリンク・実体には触れない）
  for link in "$dst"/*; do
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      rm "$link"
      echo "🗑️ 壊れたシンボリックリンクを削除しました: $link"
    fi
  done
}

# 初回のみ src をコピーする（外部ツールが実体を書き換えるファイル用。コピーしたら 0 を返す）
copy_if_missing() {
  local src=$1 dst=$2
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "⏭️ $dst は既に存在します"
    return 1
  fi
  [ -L "$dst" ] && rm "$dst"
  cp "$src" "$dst" 2>/dev/null && echo "✅ ファイルをコピーしました: $dst <- $src"
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

# ======================
# 🤖 Claude 設定のセットアップ
# ======================

ensure_dir "$HOME/.claude"
link_from_repo agents/AGENTS.md "$HOME/.claude/CLAUDE.md"
link_from_repo agents/rules "$HOME/.claude/rules"
link_agent_skills "$HOME/.claude/skills"
# settings.json は外部ツール (orca / superset 等) が hooks を注入して書き換えるため
# symlink にせず初回コピーで seed する。意図的な設定変更は tracked 側にも手動で反映する
copy_if_missing "$DOTFILES_DIR/harnesses/claude/settings.json" "$HOME/.claude/settings.json"
link_from_repo harnesses/claude/statusline.py "$HOME/.claude/statusline.py"


# ======================
# 🤖 Codex 設定のセットアップ
# ======================

ensure_dir "$HOME/.codex"
link_from_repo agents/AGENTS.md "$HOME/.codex/AGENTS.md"
link_agent_skills "$HOME/.codex/skills"


# ======================
# 🐙 GitHub Copilot 設定のセットアップ
# ======================

ensure_dir "$HOME/.copilot"
link_from_repo harnesses/copilot/copilot-instructions.md "$HOME/.copilot/copilot-instructions.md"
link_from_repo harnesses/copilot/mcp-config.json "$HOME/.copilot/mcp-config.json"


# ======================
# 🤖 Cursor CLI / Agent 設定のセットアップ
# ======================

ensure_dir "$HOME/.cursor"
link_from_repo agents/AGENTS.md "$HOME/.cursor/AGENTS.md"
link_agent_skills "$HOME/.cursor/skills"


# ======================
# 🤖 Devin CLI 設定のセットアップ
# ======================

ensure_dir ~/.config
ensure_dir "$HOME/.config/devin"
link_from_repo harnesses/devin/AGENTS.md "$HOME/.config/devin/AGENTS.md"


# ======================
# 🤖 Agents 設定のセットアップ
# ======================

ensure_dir "$HOME/.agents"
link_from_repo agents/AGENTS.md "$HOME/.agents/AGENTS.md"
link_from_repo agents/rules "$HOME/.agents/rules"
link_from_repo agents/skills "$HOME/.agents/skills"
link_from_repo agents/.skill-lock.json "$HOME/.agents/.skill-lock.json"


# ======================
# 🔧 Tmux 設定のセットアップ
# ======================

link_from_repo tmux/.tmux.conf "$HOME/.tmux.conf"

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
link_from_repo mise/config.toml "$HOME/.config/mise/config.toml"

# ツールのインストール
if [ -x "$(command -v mise)" ]; then
  mise trust -q "$DOTFILES_DIR/mise/config.toml"
  if [ -n "$(mise ls --missing --no-header 2>/dev/null)" ]; then
    echo "📦 mise でツールをインストールしています..."
    mise install
    echo "✅ mise のツールをインストールしました"
  else
    echo "⏭️ mise のツールは既にインストールされています"
  fi
else
  echo "⚠️ mise がインストールされていません。brew install mise を実行してください"
fi


# ======================
# 🐠 Fish 設定のセットアップ
# ======================

ensure_dir ~/.config/fish
link_from_repo fish/config.fish "$HOME/.config/fish/config.fish"

# Fish 機密環境変数設定のセットアップ
ensure_dir ~/.local/fish

# env.fish のコピー（既存ファイルがある場合は上書きしない）
if copy_if_missing "$DOTFILES_DIR/fish/env.fish" "$HOME/.local/fish/env.fish"; then
  echo "📝 ~/.local/fish/env.fish を編集して環境変数を設定してください"
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
link_from_repo nvim/init.lua "$HOME/.config/nvim/init.lua"
link_from_repo nvim/lua "$HOME/.config/nvim/lua"


# ======================
# 📁 Yazi 設定のセットアップ
# ======================

ensure_dir ~/.config/yazi
link_from_repo yazi/yazi.toml "$HOME/.config/yazi/yazi.toml"
link_from_repo yazi/theme.toml "$HOME/.config/yazi/theme.toml"

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

link_from_repo ghostty "$HOME/.config/ghostty"


# ======================
# ⌨️ macOS キーバインディング設定のセットアップ
# ======================

ensure_dir ~/Library/KeyBindings
link_from_repo Library/KeyBindings/DefaultKeyBinding.dict "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"


# ======================
# 🖥️ Cursor IDE 設定のセットアップ
# ======================

# Cursor設定ディレクトリが存在する場合のみセットアップ
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
if [ -d "$CURSOR_USER_DIR" ]; then
  link_replace "$DOTFILES_DIR/cursor-app/settings.json" "$CURSOR_USER_DIR/settings.json"
  link_replace "$DOTFILES_DIR/cursor-app/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
else
  echo "⚠️ Cursor がインストールされていません。Cursor IDE 設定のセットアップをスキップします"
fi


# ======================
# 🐚 Zsh 設定のセットアップ
# ======================

link_from_repo zsh/.zshrc "$HOME/.zshrc"
