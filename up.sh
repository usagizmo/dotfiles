#!/bin/bash

# ======================
# 🔧 Tmux 設定の更新
# ======================

# tmux plugin manager (tpm) の更新
if [ -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm を更新しています..."
  (cd ~/.tmux/plugins/tpm && git pull)
  echo "✅ tpm を更新しました"
else
  echo "⚠️ tpm がインストールされていません。init.sh を実行してください"
fi


# ======================
# 📁 Yazi 設定の更新
# ======================

# Yazi プラグインの更新
if [ -x "$(command -v ya)" ]; then
  echo "📦 Yazi プラグインを更新しています..."
  ya pkg upgrade
  echo "✅ Yazi プラグインを更新しました"
else
  echo "⚠️ ya コマンドが見つかりません。Yazi プラグインの更新をスキップします"
fi
