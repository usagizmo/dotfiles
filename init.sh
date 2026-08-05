#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/links.sh
. "$DOTFILES_DIR/lib/links.sh"
# shellcheck source=lib/inventory.sh
. "$DOTFILES_DIR/lib/inventory.sh"

INSTALL_FAILED=0

# インストールの成否を握りつぶさない。失敗は summary で集計し非ゼロ終了する
# 第 1 引数は助詞まで含む文節（「tpm を」）。「インストール〜」に直接続ける
install_step() {
  local phrase="$1"
  shift
  echo "📦 ${phrase}インストールしています..."
  if "$@"; then
    echo "✅ ${phrase}インストールしました"
  else
    echo "⚠️ ${phrase}インストールできませんでした"
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
  fi
}

echo "## links (lib/inventory.sh)"
run_inventory apply


echo ""
echo "## mise"

if [ -x "$(command -v mise)" ]; then
  mise trust -q "$DOTFILES_DIR/mise/config.toml"
  if [ -n "$(mise ls --missing --no-header 2>/dev/null)" ]; then
    install_step "mise でツールを" mise install
  else
    echo "⏭️ mise のツールは既にインストールされています"
  fi
else
  echo "⚠️ mise がインストールされていません。brew install mise を実行してください"
fi


echo ""
echo "## brew packages"

# shell 設定が前提とする CLI（fish/zsh の alias・keybind・関数から参照）。形式: <brew パッケージ名>:<コマンド名>
BREW_PACKAGES="safe-rm:safe-rm fzf:fzf neovim:nvim"

if [ -x "$(command -v brew)" ]; then
  for entry in $BREW_PACKAGES; do
    pkg="${entry%%:*}"
    cmd="${entry##*:}"
    if [ -x "$(command -v "$cmd")" ]; then
      echo "⏭️ $pkg は既にインストールされています"
    else
      install_step "$pkg を" brew install "$pkg"
    fi
  done
else
  echo "⚠️ brew がインストールされていません。brew パッケージのインストールをスキップします"
fi


echo ""
echo "## fish plugins"

if [ -x "$(command -v fish)" ]; then
  if ! fish -c "type -q fisher" 2>/dev/null; then
    install_step "fisher を" fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  else
    echo "⏭️ fisher は既にインストールされています"
  fi

  if [ ! -f ~/.config/fish/fish_plugins ] || ! grep -q "oh-my-fish/theme-bobthefish" ~/.config/fish/fish_plugins 2>/dev/null; then
    install_step "bobthefish テーマを" fish -c "fisher install oh-my-fish/theme-bobthefish"
  else
    echo "⏭️ bobthefish テーマは既にインストールされています"
  fi
else
  echo "⚠️ fish がインストールされていません。fisher とプラグインのセットアップをスキップします"
fi


echo ""
echo "## yazi flavors"

if [ -x "$(command -v ya)" ]; then
  if [ ! -d ~/.config/yazi/flavors/dracula.yazi ]; then
    install_step "Catppuccin Dracula テーマを" ya pkg add yazi-rs/flavors:dracula
  else
    echo "⏭️ Catppuccin Dracula テーマは既にインストールされています"
  fi
else
  echo "⚠️ ya コマンドが見つかりません。Yazi のテーマインストールをスキップします"
fi


echo ""
echo "## ghostty defaults"

# macOS 標準タブ機能の「すべてのタブを表示」(⇧⌘\) が herdr の split_horizontal を
# 食うため、メニューショートカットを使わない組み合わせ (⌃⌥⇧⌘\) へ退避する
# （Ghostty の config では AppKit メニュー由来のショートカットを変更できない）
if defaults write com.mitchellh.ghostty NSUserKeyEquivalents -dict-add "Show All Tabs" '@~^$\\' &&
  defaults write com.mitchellh.ghostty NSUserKeyEquivalents -dict-add "すべてのタブを表示" '@~^$\\'; then
  echo "✅ Show All Tabs のショートカットを退避しました（Ghostty 再起動後に有効）"
else
  echo "⚠️ Ghostty の NSUserKeyEquivalents を設定できませんでした"
  INSTALL_FAILED=$((INSTALL_FAILED + 1))
fi


echo ""
echo "## herdr integrations"

if [ -x "$(command -v herdr)" ]; then
  # 未インストールだけでなく hook が古い場合（current 以外）も再インストールで更新する
  if herdr integration status 2>/dev/null | grep -q "^claude: current"; then
    echo "⏭️ herdr claude integration は既にインストールされています"
  else
    install_step "herdr claude integration を" herdr integration install claude
  fi
else
  echo "⚠️ herdr がインストールされていません。integration のセットアップをスキップします"
fi


echo ""
echo "## summary"

FAILED=0

if [ "$LINK_BLOCKED" -gt 0 ]; then
  echo "⚠️ symlink を作成できなかった箇所が ${LINK_BLOCKED} 件あります。"
  echo "   上の「実ディレクトリ / 実ファイル / 作成失敗」を確認し、退避または削除してから再実行してください。"
  echo "   検査だけなら: ./doctor.sh"
  FAILED=1
fi

if [ "$INSTALL_FAILED" -gt 0 ]; then
  echo "⚠️ インストールに失敗した項目が ${INSTALL_FAILED} 件あります。"
  echo "   上の「インストールできませんでした」を確認し、原因を解消してから再実行してください。"
  FAILED=1
fi

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

echo "✅ init 完了（symlink block / インストール失敗なし）"
