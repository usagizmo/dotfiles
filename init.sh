#!/bin/bash

# ======================
# 🤖 Claude 設定のセットアップ
# ======================

# Claude設定ディレクトリ作成
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


# ======================
# 🔧 Tmux 設定のセットアップ
# ======================

# .tmux.conf のシンボリックリンク作成
if [ -e ~/.tmux.conf ]; then
  echo "⏭️ ~/.tmux.conf は既に存在します"
else
  if ln -s "$(pwd)/tmux/.tmux.conf" ~/.tmux.conf 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.tmux.conf -> $(pwd)/tmux/.tmux.conf"
  fi
fi

# tmux plugin manager (tpm) のセットアップ
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "📦 tpm をインストールしています..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "✅ tpm をインストールしました: ~/.tmux/plugins/tpm"
else
  echo "⏭️ tpm は既にインストールされています"
fi


# ======================
# 🐠 Fish 設定のセットアップ
# ======================

# Fish設定ディレクトリ作成
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

# 壊れたシンボリックリンクをクリーンアップ
for linked_file in ~/.config/fish/functions/*.fish; do
  if [ -L "$linked_file" ]; then
    if [ ! -e "$linked_file" ]; then
      func_name=$(basename "$linked_file")
      rm "$linked_file"
      echo "🗑️ 壊れたシンボリックリンクを削除しました: ~/.config/fish/functions/$func_name"
    fi
  fi
done

# Fish 機密環境変数設定のセットアップ
if [ ! -d ~/.local/fish ]; then
  mkdir -p ~/.local/fish
  echo "✅ ディレクトリを作成しました: ~/.local/fish"
fi

# env.fish のコピー（既存ファイルがある場合は上書きしない）
if [ -e ~/.local/fish/env.fish ]; then
  echo "⏭️ ~/.local/fish/env.fish は既に存在します"
else
  if cp "$(pwd)/fish/env.fish" ~/.local/fish/env.fish 2>/dev/null; then
    echo "✅ ファイルをコピーしました: ~/.local/fish/env.fish <- $(pwd)/fish/env.fish"
    echo "📝 ~/.local/fish/env.fish を編集して環境変数を設定してください"
  fi
fi

# Fisher (fish plugin manager) のセットアップ
if [ -x "$(command -v fish)" ]; then
  # fisher がインストールされているか確認
  if ! fish -c "type -q fisher" 2>/dev/null; then
    echo "📦 fisher をインストールしています..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    echo "✅ fisher をインストールしました"
  else
    echo "⏭️ fisher は既にインストールされています"
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


# ======================
# 📝 Neovim 設定のセットアップ
# ======================

# Neovim設定ディレクトリ作成
if [ ! -d ~/.config/nvim ]; then
  mkdir -p ~/.config/nvim
  echo "✅ ディレクトリを作成しました: ~/.config/nvim"
fi

# init.lua のシンボリックリンク
if [ -e ~/.config/nvim/init.lua ]; then
  echo "⏭️ ~/.config/nvim/init.lua は既に存在します"
else
  if ln -s "$(pwd)/nvim/init.lua" ~/.config/nvim/init.lua 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/nvim/init.lua -> $(pwd)/nvim/init.lua"
  fi
fi

# lua ディレクトリのシンボリックリンク
if [ -e ~/.config/nvim/lua ]; then
  echo "⏭️ ~/.config/nvim/lua は既に存在します"
else
  if ln -s "$(pwd)/nvim/lua" ~/.config/nvim/lua 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/nvim/lua -> $(pwd)/nvim/lua"
  fi
fi


# ======================
# 📁 Yazi 設定のセットアップ
# ======================

# Yazi設定ディレクトリ作成
if [ ! -d ~/.config/yazi ]; then
  mkdir -p ~/.config/yazi
  echo "✅ ディレクトリを作成しました: ~/.config/yazi"
fi

# yazi.toml のシンボリックリンク
if [ -e ~/.config/yazi/yazi.toml ]; then
  echo "⏭️ ~/.config/yazi/yazi.toml は既に存在します"
else
  if ln -s "$(pwd)/yazi/yazi.toml" ~/.config/yazi/yazi.toml 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/yazi/yazi.toml -> $(pwd)/yazi/yazi.toml"
  fi
fi

# theme.toml のシンボリックリンク
if [ -e ~/.config/yazi/theme.toml ]; then
  echo "⏭️ ~/.config/yazi/theme.toml は既に存在します"
else
  if ln -s "$(pwd)/yazi/theme.toml" ~/.config/yazi/theme.toml 2>/dev/null; then
    echo "✅ シンボリックリンクを作成しました: ~/.config/yazi/theme.toml -> $(pwd)/yazi/theme.toml"
  fi
fi

# Catppuccin Dracula テーマのインストール
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


# ======================
# 📋 Taskwarrior 設定のセットアップ
# ======================

# Taskwarrior設定ファイル作成
if [ ! -f ~/.taskrc ]; then
  touch ~/.taskrc
  echo "✅ ファイルを作成しました: ~/.taskrc"
fi

# Taskwarrior 設定の追加
if ! grep -q "uda.duration.label=Duration" ~/.taskrc; then
  echo "📦 Taskwarrior 設定を追加しています..."

  cat >> ~/.taskrc << 'EOF'
uda.duration.type=string
uda.duration.label=Duration
report.next.columns=id,start.age,entry.age,depends,priority,tags,recur,scheduled.countdown,due.relative,until.remaining,duration,project,description,urgency
report.next.labels=ID,Active,Age,Deps,P,Tag,Recur,S,Due,Until,Dur,Project,Description,Urg
report.list.columns=id,start.age,entry.age,depends.indicator,priority,tags,recur.indicator,scheduled.countdown,due,until.remaining,duration,project,description.count,urgency
report.list.labels=ID,Active,Age,D,P,Tags,R,Sch,Due,Until,Dur,Project,Description,Urg
report.waiting.columns=id,start.active,entry.age,depends.indicator,priority,tags,recur.indicator,wait,wait.remaining,scheduled,due,until,duration,project,description
report.waiting.labels=ID,A,Age,D,P,Tags,R,Wait,Remaining,Sched,Due,Until,Dur,Project,Description

EOF
  echo "✅ Taskwarrior 設定を ~/.taskrc に追加しました"
else
  echo "⏭️ Taskwarrior 設定は既に存在します"
fi
