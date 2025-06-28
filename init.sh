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
