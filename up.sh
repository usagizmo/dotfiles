#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ======================
# 🤖 外部取得 agent skills の更新
# ======================

# agents/.skill-lock.json 管理の外部 skill (vercel-cli / sentry-cli 等) を更新する
if [ -x "$(command -v bunx)" ]; then
  echo "📦 外部取得の agent skills を更新しています..."
  (cd "$DOTFILES_DIR/agents" && bunx skills update -y)
  echo "✅ agent skills を更新しました"
else
  echo "⚠️ bunx が見つかりません。agent skills の更新をスキップします"
fi


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
