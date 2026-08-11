#!/bin/bash
# 外部依存の更新。配線の SSOT は lib/inventory.sh（変更したら ./init.sh で再適用する）
#
# **agent skills の更新はここに無い。**agentfiles（兄弟 repo）の ./up.sh が行う。

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/links.sh
. "$REPO_DIR/lib/links.sh"

UPDATE_FAILED=0

echo "## mise tools"

# mise/config.toml の "latest" は install 時に固まるので、更新はここでしか起きない
if [ -x "$(command -v mise)" ]; then
  mise trust -q "$REPO_DIR/mise/config.toml"
  echo "📦 mise のツールを更新しています..."
  if mise upgrade; then
    echo "✅ mise のツールを更新しました"
  else
    echo "⚠️ mise のツールの更新に失敗しました"
    UPDATE_FAILED=1
  fi
else
  # mise が無ければ mise 管理のツールも入っていない（更新対象そのものが無い）
  echo "⚠️ mise が見つかりません。ツールの更新をスキップします"
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
if [ "$UPDATE_FAILED" -ne 0 ]; then
  echo "⚠️ 外部更新の一部が失敗またはスキップされました（配線結果とは別軸）。"
  exit_code=1
fi
if [ "$exit_code" -eq 0 ]; then
  echo "✅ up 完了"
fi
exit "$exit_code"
