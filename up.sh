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

# agents/.skill-lock.json 管理の外部 skill (agent-browser / skill-creator) を更新する
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

# herdr skill は git 管理外。**HEAD から取らず、入っている binary から出す**
# （HEAD は binary より先行しうるので、無い CLI を説明する skill が配られる）
if [ -x "$(command -v herdr)" ]; then
  # **直接リダイレクトしない。**`>` は herdr を起動する前にファイルを 0 バイトへ切り詰めるので、
  # 生成に失敗すると既存の skill が消える（git 管理外なので戻せない）
  HERDR_SKILL_TMP="$(mktemp)"
  HERDR_SKILL_ERR="$(mktemp)"
  if herdr --skill >"$HERDR_SKILL_TMP" 2>"$HERDR_SKILL_ERR" && [ -s "$HERDR_SKILL_TMP" ]; then
    mkdir -p "$DOTFILES_DIR/agents/skills/herdr"
    install -m 644 "$HERDR_SKILL_TMP" "$DOTFILES_DIR/agents/skills/herdr/SKILL.md"
    echo "✅ herdr skill を $(herdr --version) から更新しました"
  else
    # 原因を捨てない。socket 断・権限でも同じ文言になると切り分けができない
    echo "⚠️ herdr skill を生成できませんでした: $(head -n 1 "$HERDR_SKILL_ERR")"
    UPDATE_FAILED=1
  fi
  rm -f "$HERDR_SKILL_TMP" "$HERDR_SKILL_ERR"
else
  # 更新の**対象そのもの**が無いので、更新すべき skill も存在しない（道具の欠落とは別）
  echo "⚠️ herdr が無いので skill の更新をスキップします"
fi

# 新規 skill ディレクトリが増えた場合に harness 側 symlink を追随させる
# full reconcile（partial API は作らない = up 専用経路の drift を防ぐ）
echo ""
echo "## links (re-apply after skills update)"
run_inventory apply


echo ""
echo "## mise tools"

# mise/config.toml の "latest" は install 時に固まるので、更新はここでしか起きない
if [ -x "$(command -v mise)" ]; then
  mise trust -q "$DOTFILES_DIR/mise/config.toml"
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
