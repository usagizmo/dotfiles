#!/bin/bash

# 🔄 dotfiles の更新処理

# 🔧 tmux plugin manager (tpm) の更新
if [ -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm を更新しています..."
  (cd ~/.tmux/plugins/tpm && git pull)
  echo "✅ tpm を更新しました"
else
  echo "⚠️ tpm がインストールされていません。init.sh を実行してください"
fi