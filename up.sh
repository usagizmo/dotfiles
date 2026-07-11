#!/bin/bash
# 外部依存の更新。配線の SSOT は lib/inventory.sh（変更後は links を再適用する）

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/links.sh
. "$DOTFILES_DIR/lib/links.sh"
# shellcheck source=lib/inventory.sh
. "$DOTFILES_DIR/lib/inventory.sh"

# 外部更新の失敗と symlink blocked は別軸
UPDATE_FAILED=0

echo "## agent skills (external)"

# agents/.skill-lock.json 管理の外部 skill (vercel-cli / sentry-cli 等) を更新する
if [ -x "$(command -v bunx)" ]; then
  echo "📦 外部取得の agent skills を更新しています..."
  if (cd "$DOTFILES_DIR/agents" && bunx skills update -y); then
    echo "✅ agent skills を更新しました"
  else
    echo "⚠️ agent skills の更新に失敗しました"
    UPDATE_FAILED=1
  fi
else
  # skills 更新は up の主目的のひとつなので、ツール欠落は失敗扱い
  echo "⚠️ bunx が見つかりません。agent skills の更新をスキップします"
  UPDATE_FAILED=1
fi

# 新規 skill ディレクトリが増えた場合に harness 側 symlink を追随させる
# full reconcile（partial API は作らない = up 専用経路の drift を防ぐ）
echo ""
echo "## links (re-apply after skills update)"
run_inventory apply


echo ""
echo "## tpm"

if [ -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm を更新しています..."
  if (cd ~/.tmux/plugins/tpm && git pull); then
    echo "✅ tpm を更新しました"
  else
    echo "⚠️ tpm の更新に失敗しました"
    UPDATE_FAILED=1
  fi
else
  echo "⚠️ tpm がインストールされていません。init.sh を実行してください"
  UPDATE_FAILED=1
fi


echo ""
echo "## yazi"

if [ -x "$(command -v ya)" ]; then
  echo "📦 Yazi プラグインを更新しています..."
  if ya pkg upgrade; then
    echo "✅ Yazi プラグインを更新しました"
  else
    echo "⚠️ Yazi プラグインの更新に失敗しました"
    UPDATE_FAILED=1
  fi
else
  # 未インストールは optional skip（失敗ではない）
  echo "⚠️ ya コマンドが見つかりません。Yazi プラグインの更新をスキップします"
fi


echo ""
echo "## summary"

exit_code=0
if [ "$LINK_BLOCKED" -gt 0 ]; then
  echo "⚠️ symlink を作成できなかった箇所が ${LINK_BLOCKED} 件あります。"
  echo "   検査: ./doctor.sh ／ 修復の切り分け: ./init.sh"
  exit_code=1
fi
if [ "$UPDATE_FAILED" -ne 0 ]; then
  echo "⚠️ 外部更新の一部が失敗またはスキップされました（配線結果とは別軸）。"
  exit_code=1
fi
if [ "$exit_code" -eq 0 ]; then
  echo "✅ up 完了"
fi
exit "$exit_code"
