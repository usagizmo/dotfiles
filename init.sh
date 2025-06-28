#!/bin/bash

# 🎉 dotfiles のセットアップ

# 🔗 .tmux.conf のシンボリックリンク作成
if [ -e ~/.tmux.conf ]; then
  echo "⏭️ ~/.tmux.conf は既に存在します"
else
  if ln -s "$(pwd)/tmux/.tmux.conf" ~/.tmux.conf 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.tmux.conf -> $(pwd)/tmux/.tmux.conf"
  fi
fi

# 🔧 tmux plugin manager (tpm) のセットアップ
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm をインストールしています..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "✅ tpm をインストールしました: ~/.tmux/plugins/tpm"
else
  echo "⏭️ tpm は既にインストールされています"
fi

# 🤖 Claude 設定のセットアップ
if [ ! -d ~/.claude ]; then
  mkdir -p ~/.claude
  echo "✅ ディレクトリを作成しました: ~/.claude"
fi

# CLAUDE.md のシンボリックリンク
if [ -e ~/.claude/CLAUDE.md ]; then
  echo "⏭️ ~/.claude/CLAUDE.md は既に存在します"
else
  if ln -s "$(pwd)/claude/CLAUDE.md" ~/.claude/CLAUDE.md 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.claude/CLAUDE.md -> $(pwd)/claude/CLAUDE.md"
  fi
fi

# settings.json のシンボリックリンク
if [ -e ~/.claude/settings.json ]; then
  echo "⏭️ ~/.claude/settings.json は既に存在します"
else
  if ln -s "$(pwd)/claude/settings.json" ~/.claude/settings.json 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.claude/settings.json -> $(pwd)/claude/settings.json"
  fi
fi

# commands ディレクトリのシンボリックリンク
if [ -e ~/.claude/commands ]; then
  echo "⏭️ ~/.claude/commands は既に存在します"
else
  if ln -s "$(pwd)/claude/commands" ~/.claude/commands 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.claude/commands -> $(pwd)/claude/commands"
  fi
fi

# 🐠 Fish 設定のセットアップ
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

# functions ディレクトリのシンボリックリンク
if [ ! -d ~/.config/fish/functions ]; then
  mkdir -p ~/.config/fish/functions
  echo "✅ ディレクトリを作成しました: ~/.config/fish/functions"
fi

# functions ディレクトリ内のファイルをシンボリックリンク
for func_file in $(pwd)/fish/functions/*.fish; do
  if [ -f "$func_file" ]; then
    func_name=$(basename "$func_file")
    if [ -e ~/.config/fish/functions/"$func_name" ]; then
      echo "⏭️ ~/.config/fish/functions/$func_name は既に存在します"
    else
      if ln -s "$func_file" ~/.config/fish/functions/"$func_name" 2>/dev/null; then
        echo "✅ シンボリックリンクを作成しました: ~/.config/fish/functions/$func_name -> $func_file"
      fi
    fi
  fi
done

# 🎣 Fisher (fish plugin manager) のセットアップ
if [ -x "$(command -v fish)" ]; then
  # fisher がインストールされているか確認
  if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "📦 fisher をインストールしています..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    echo "✅ fisher をインストールしました"
  else
    echo "⏭️ fisher は既にインストールされています"
  fi

  # fish-fzf プラグインのインストール
  if [ ! -f ~/.config/fish/fish_plugins ] || ! grep -q "takashabe/fish-fzf" ~/.config/fish/fish_plugins 2>/dev/null; then
    echo "📦 fish-fzf をインストールしています..."
    fish -c "fisher install takashabe/fish-fzf"
    echo "✅ fish-fzf をインストールしました"
  else
    echo "⏭️ fish-fzf は既にインストールされています"
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
