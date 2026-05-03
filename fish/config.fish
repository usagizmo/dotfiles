# --------------------
# Function Path
# --------------------

# config.fish のシンボリックリンクを解決し、同階層の functions を参照
# dotfiles の配置場所に依存しない
set -l config_dir (dirname (realpath (status filename)))
set -gp fish_function_path $config_dir/functions


# --------------------
# Functions
# --------------------

# キーバインディング設定
function fish_user_key_bindings
  bind \c] fzf_ghq      # Ctrl-]
  bind \cr fzf_history  # Ctrl-r
end

# Yazi (ファイルマネージャー) 統合
function y
  set tmp (mktemp -t "yazi-cwd.XXXXXX")
  yazi $argv --cwd-file="$tmp"
  if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    builtin cd -- "$cwd"
  end
  rm -f -- "$tmp"
end

function vi
  nvim --listen ~/.cache/nvim/server-$(date +%s).pipe $argv
end


# --------------------
# Environment Variables
# --------------------

# エディタ設定
set -gx EDITOR nvim

# Cargo の target ディレクトリを共通化（プロジェクト／worktree 跨ぎで再利用）
set -gx CARGO_TARGET_DIR "$HOME/.cache/cargo-target"

# 機密情報は別ファイルで管理
if test -f ~/.local/fish/env.fish
  source ~/.local/fish/env.fish
end


# --------------------
# Tool Initialization
# --------------------

# zoxide (スマートなディレクトリジャンプ)
zoxide init fish | source

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# mise (ランタイムバージョン管理)
mise activate fish | source


# --------------------
# Path Settings
# --------------------

# User
fish_add_path "$HOME/.local/bin"

# Rust
fish_add_path "$HOME/.cargo/bin"

# Bun
fish_add_path "$HOME/.bun/bin"

# LM Studio CLI
fish_add_path "$HOME/.lmstudio/bin"


# --------------------
# Abbreviations - ディレクトリ移動
# --------------------

abbr -a cdd cd ~/Downloads
abbr -a cdc cd ~/.config


# --------------------
# Abbreviations - Git操作
# --------------------

# 基本コマンド
abbr -a g git
abbr -a gst git status
abbr -a gsh git show HEAD
abbr -a glog "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all"

# diff
abbr -a gd git diff
abbr -a gdc git diff --cached

# add
abbr -a ga git add
abbr -a gaa git add --all

# commit
abbr -a gc git commit
abbr -a gcm git commit -m
abbr -a gca git commit --amend

# branch/checkout/merge
abbr -a gb git branch
abbr -a gco git checkout
abbr -a gm git merge

# fetch/pull/push
abbr -a gf git fetch
abbr -a gf! git fetch --prune
abbr -a gp git push
abbr -a gp! git push --force


# --------------------
# Abbreviations - アプリケーション
# --------------------

abbr -a rm safe-rm
abbr -a br bun run
abbr -a c claude
abbr -a cur cursor
abbr -a sm smerge
abbr -a st subl
abbr -a ol ollama
abbr -a keka /Applications/Keka.app/Contents/MacOS/Keka --cli 7zz a


# opencode
fish_add_path /Users/usagizmo/.opencode/bin
