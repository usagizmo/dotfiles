#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/links.sh
. "$DOTFILES_DIR/lib/links.sh"
# shellcheck source=lib/inventory.sh
. "$DOTFILES_DIR/lib/inventory.sh"

echo "## links (lib/inventory.sh)"
run_inventory apply


echo ""
echo "## tpm"

if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm をインストールしています..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "✅ tpm をインストールしました: ~/.tmux/plugins/tpm"
else
  echo "⏭️ tpm は既にインストールされています"
fi


echo ""
echo "## mise"

if [ -x "$(command -v mise)" ]; then
  mise trust -q "$DOTFILES_DIR/mise/config.toml"
  if [ -n "$(mise ls --missing --no-header 2>/dev/null)" ]; then
    echo "📦 mise でツールをインストールしています..."
    mise install
    echo "✅ mise のツールをインストールしました"
  else
    echo "⏭️ mise のツールは既にインストールされています"
  fi
else
  echo "⚠️ mise がインストールされていません。brew install mise を実行してください"
fi


echo ""
echo "## fish plugins"

if [ -x "$(command -v fish)" ]; then
  if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "📦 fisher をインストールしています..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    echo "✅ fisher をインストールしました"
  else
    echo "⏭️ fisher は既にインストールされています"
  fi

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


echo ""
echo "## yazi flavors"

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


echo ""
echo "## summary"

if [ "$LINK_BLOCKED" -gt 0 ]; then
  echo "⚠️ symlink を作成できなかった箇所が ${LINK_BLOCKED} 件あります。"
  echo "   上の「実ディレクトリ / 実ファイル / 作成失敗」を確認し、退避または削除してから再実行してください。"
  echo "   検査だけなら: ./doctor.sh"
  exit 1
fi

echo "✅ init 完了（symlink block なし）"
