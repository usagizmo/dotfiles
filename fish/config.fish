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

# direnv (ディレクトリ単位の環境変数管理)
direnv hook fish | source
eval (direnv hook fish)

# anyenv (複数言語のバージョン管理)
status --is-interactive; and source (anyenv init -|psub)


# --------------------
# Path Settings
# --------------------

# Rust
fish_add_path "$HOME/.cargo/bin"


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
alias gc! 'git commit --amend'
alias gcm 'git commit -m'
alias gca 'claude --dangerously-skip-permissions -p "git diff --cached を実行して内容を確認して、stagingの内容のみコミットして"'

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
# Aliases - Taskwarrior
# --------------------

alias t 'task'
alias ta 'task add'
alias tan 'task annotate'
alias tm 'task modify'
alias te 'task edit'
alias ts 'task start'
alias tst 'task stop'
alias td 'task done'


# --------------------
# Aliases - アプリケーション
# --------------------

alias rm 'safe-rm'
alias pn 'pnpm'
alias sm 'open -a Sublime\ Merge'
alias st 'open -a Sublime\ Text'
alias yolo="claude --dangerously-skip-permissions"
alias keka="/Applications/Keka.app/Contents/MacOS/Keka --cli 7zz a"

