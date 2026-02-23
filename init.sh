#!/bin/bash

# ======================
# 🐙 GitHub Copilot 設定のセットアップ
# ======================

# .copilot ディレクトリのシンボリックリンク
if [ -e ~/.copilot ]; then
  echo "⏭️ ~/.copilot は既に存在します"
else
  if ln -s "$(pwd)/copilot" ~/.copilot 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.copilot -> $(pwd)/copilot"
  fi
fi


# ======================
# 🤖 Claude 設定のセットアップ
# ======================

# .claude ディレクトリのシンボリックリンク
if [ -e ~/.claude ]; then
  echo "⏭️ ~/.claude は既に存在します"
else
  if ln -s "$(pwd)/claude" ~/.claude 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.claude -> $(pwd)/claude"
  fi
fi


# ======================
# 🤖 Codex 設定のセットアップ
# ======================

# .codex ディレクトリのシンボリックリンク
if [ -e ~/.codex ]; then
  echo "⏭️ ~/.codex は既に存在します"
else
  if [ -d "$(pwd)/codex" ]; then
    if ln -s "$(pwd)/codex" ~/.codex 2>/dev/null; then
      echo "✅ シンボリックリンクを作成しました: ~/.codex -> $(pwd)/codex"
    fi
  else
    echo "⚠️ codex ディレクトリが見つかりません。後で再実行してください"
  fi
fi

# codex/AGENTS.md のシンボリックリンク
if [ -L "$(pwd)/codex/AGENTS.md" ]; then
  echo "⏭️ ~/.codex/AGENTS.md のシンボリックリンクは既に存在します"
else
  if ln -s ../claude/CLAUDE.md "$(pwd)/codex/AGENTS.md" 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.codex/AGENTS.md -> ../claude/CLAUDE.md"
  fi
fi


# ======================
# 🔧 Tmux 設定のセットアップ
# ======================

# .tmux.conf のシンボリックリンク作成
if [ -e ~/.tmux.conf ]; then
  echo "⏭️ ~/.tmux.conf は既に存在します"
else
  if ln -s "$(pwd)/tmux/.tmux.conf" ~/.tmux.conf 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.tmux.conf -> $(pwd)/tmux/.tmux.conf"
  fi
fi

# tmux plugin manager (tpm) のセットアップ
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm をインストールしています..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "✅ tpm をインストールしました: ~/.tmux/plugins/tpm"
else
  echo "⏭️ tpm は既にインストールされています"
fi


# ======================
# 🐠 Fish 設定のセットアップ
# ======================

# Fish設定ディレクトリ作成
if [ ! -d ~/.config/fish ]; then
  mkdir -p ~/.config/fish
  echo "✅ ディレクトリを作成しました: ~/.config/fish"
fi

# config.fish のシンボリックリンク
if [ -e ~/.config/fish/config.fish ]; then
  echo "⏭️ ~/.config/fish/config.fish は既に存在します"
else
  if ln -s "$(pwd)/fish/config.fish" ~/.config/fish/config.fish 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/fish/config.fish -> $(pwd)/fish/config.fish"
  fi
fi

# Fish 機密環境変数設定のセットアップ
if [ ! -d ~/.local/fish ]; then
  mkdir -p ~/.local/fish
  echo "✅ ディレクトリを作成しました: ~/.local/fish"
fi

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

# Neovim設定ディレクトリ作成
if [ ! -d ~/.config/nvim ]; then
  mkdir -p ~/.config/nvim
  echo "✅ ディレクトリを作成しました: ~/.config/nvim"
fi

# init.lua のシンボリックリンク
if [ -e ~/.config/nvim/init.lua ]; then
  echo "⏭️ ~/.config/nvim/init.lua は既に存在します"
else
  if ln -s "$(pwd)/nvim/init.lua" ~/.config/nvim/init.lua 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/nvim/init.lua -> $(pwd)/nvim/init.lua"
  fi
fi

# lua ディレクトリのシンボリックリンク
if [ -e ~/.config/nvim/lua ]; then
  echo "⏭️ ~/.config/nvim/lua は既に存在します"
else
  if ln -s "$(pwd)/nvim/lua" ~/.config/nvim/lua 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/nvim/lua -> $(pwd)/nvim/lua"
  fi
fi


# ======================
# 📁 Yazi 設定のセットアップ
# ======================

# Yazi設定ディレクトリ作成
if [ ! -d ~/.config/yazi ]; then
  mkdir -p ~/.config/yazi
  echo "✅ ディレクトリを作成しました: ~/.config/yazi"
fi

# yazi.toml のシンボリックリンク
if [ -e ~/.config/yazi/yazi.toml ]; then
  echo "⏭️ ~/.config/yazi/yazi.toml は既に存在します"
else
  if ln -s "$(pwd)/yazi/yazi.toml" ~/.config/yazi/yazi.toml 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/yazi/yazi.toml -> $(pwd)/yazi/yazi.toml"
  fi
fi

# theme.toml のシンボリックリンク
if [ -e ~/.config/yazi/theme.toml ]; then
  echo "⏭️ ~/.config/yazi/theme.toml は既に存在します"
else
  if ln -s "$(pwd)/yazi/theme.toml" ~/.config/yazi/theme.toml 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/yazi/theme.toml -> $(pwd)/yazi/theme.toml"
  fi
fi

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

# Ghostty設定ディレクトリのシンボリックリンク
if [ -e ~/.config/ghostty ]; then
  echo "⏭️ ~/.config/ghostty は既に存在します"
else
  if ln -s "$(pwd)/ghostty" ~/.config/ghostty 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/ghostty -> $(pwd)/ghostty"
  fi
fi


# ======================
# ⌨️ macOS キーバインディング設定のセットアップ
# ======================

# KeyBindings ディレクトリ作成
if [ ! -d ~/Library/KeyBindings ]; then
  mkdir -p ~/Library/KeyBindings
  echo "✅ ディレクトリを作成しました: ~/Library/KeyBindings"
fi

# DefaultKeyBinding.dict のシンボリックリンク
if [ -e ~/Library/KeyBindings/DefaultKeyBinding.dict ]; then
  echo "⏭️ ~/Library/KeyBindings/DefaultKeyBinding.dict は既に存在します"
else
  if ln -s "$(pwd)/Library/KeyBindings/DefaultKeyBinding.dict" ~/Library/KeyBindings/DefaultKeyBinding.dict 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/Library/KeyBindings/DefaultKeyBinding.dict -> $(pwd)/Library/KeyBindings/DefaultKeyBinding.dict"
  fi
fi


# ======================
# 🖥️ Cursor 設定のセットアップ
# ======================

# Cursor設定ディレクトリ
CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"

# Cursor設定ディレクトリが存在する場合のみセットアップ
if [ -d "$CURSOR_USER_DIR" ]; then
  # settings.json のシンボリックリンク
  if [ -L "$CURSOR_USER_DIR/settings.json" ]; then
    echo "⏭️ $CURSOR_USER_DIR/settings.json は既にシンボリックリンクです"
  else
    if [ -e "$CURSOR_USER_DIR/settings.json" ]; then
      rm "$CURSOR_USER_DIR/settings.json"
      echo "🗑️ 既存のファイルを削除しました: $CURSOR_USER_DIR/settings.json"
    fi
    if ln -s "$(pwd)/cursor/settings.json" "$CURSOR_USER_DIR/settings.json" 2>/dev/null; then
      echo "✅ シンボリックリンクを作成しました: $CURSOR_USER_DIR/settings.json -> $(pwd)/cursor/settings.json"
    fi
  fi

  # keybindings.json のシンボリックリンク
  if [ -L "$CURSOR_USER_DIR/keybindings.json" ]; then
    echo "⏭️ $CURSOR_USER_DIR/keybindings.json は既にシンボリックリンクです"
  else
    if [ -e "$CURSOR_USER_DIR/keybindings.json" ]; then
      rm "$CURSOR_USER_DIR/keybindings.json"
      echo "🗑️ 既存のファイルを削除しました: $CURSOR_USER_DIR/keybindings.json"
    fi
    if ln -s "$(pwd)/cursor/keybindings.json" "$CURSOR_USER_DIR/keybindings.json" 2>/dev/null; then
      echo "✅ シンボリックリンクを作成しました: $CURSOR_USER_DIR/keybindings.json -> $(pwd)/cursor/keybindings.json"
    fi
  fi
else
  echo "⚠️ Cursor がインストールされていません。Cursor 設定のセットアップをスキップします"
fi


# ======================
# 🐚 Zsh 設定のセットアップ
# ======================

# .zshrc のシンボリックリンク作成
if [ -e ~/.zshrc ]; then
  echo "⏭️ ~/.zshrc は既に存在します"
else
  if ln -s "$(pwd)/zsh/.zshrc" ~/.zshrc 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.zshrc -> $(pwd)/zsh/.zshrc"
  fi
fi
