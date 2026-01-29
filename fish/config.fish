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

# asdf の設定
if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

# fish_add_path（Fish 3.2で追加）はPATHの順序が変わる可能性があるため使用しない
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims


# --------------------
# Path Settings
# --------------------

# User
fish_add_path "$HOME/.local/bin"

# Rust
fish_add_path "$HOME/.cargo/bin"

# Bun
fish_add_path "$HOME/.bun/bin"


# --------------------
# Aliases - ディレクトリ移動
# --------------------

alias cdd 'cd ~/Downloads'
alias cdc 'cd ~/.config'


# --------------------
# Aliases - Git操作
# --------------------

# 基本コマンド
alias g 'git'
alias gst 'git status'
alias gsh 'git show HEAD'
alias glog "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all"

# diff
alias gd 'git diff'
alias gdc 'git diff --cached'

# add
alias ga 'git add'
alias gaa 'git add --all'

# commit
alias gc 'git commit'
alias gcm 'git commit -m'
alias gca 'git commit --amend'

# branch/checkout/merge
alias gb 'git branch'
alias gco 'git checkout'
alias gm 'git merge'

# fetch/pull/push
alias gf 'git fetch'
alias gf! 'git fetch --prune'
alias gl 'git pull'
alias gp 'git push'
alias gp! 'git push --force'


# --------------------
# Aliases - アプリケーション
# --------------------

alias rm 'safe-rm'
alias br 'bun run'
alias c 'claude'
alias sm 'open -a Sublime\ Merge'
alias st 'open -a Sublime\ Text'
alias yolo="claude --dangerously-skip-permissions"
alias keka="/Applications/Keka.app/Contents/MacOS/Keka --cli 7zz a"

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/usagizmo/.lmstudio/bin
# End of LM Studio CLI section

