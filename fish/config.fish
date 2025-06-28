function fish_user_key_bindings
  bind \c] fzf_ghq      # Ctrl-]
  bind \cr fzf_history  # Ctrl-r
  #bind \cj fzf_z        # Ctrl-j
  bind \co fzf_file     # Ctrl-o
end

function y
  set tmp (mktemp -t "yazi-cwd.XXXXXX")
  yazi $argv --cwd-file="$tmp"
  if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    builtin cd -- "$cwd"
  end
  rm -f -- "$tmp"
end

zoxide init fish | source

# aliases
alias cdd 'cd ~/Downloads'
alias cdc 'cd ~/.config'
alias sm 'open -a Sublime\ Merge'
alias st 'open -a Sublime\ Text'
alias pn 'pnpm'

# aliases (git)
alias g 'git'
alias gst 'git status'
alias gsh 'git show HEAD'
alias glog "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all"
alias gd 'git diff'
alias gdc 'git diff --cached'

alias ga 'git add'
alias gaa 'git add --all'

alias gc 'git commit'
alias gc! 'git commit --amend'
alias gcmsg 'git commit -m'
alias gcauto 'claude --dangerously-skip-permissions -p "git diff --cached を実行して内容を確認して、stagingの内容のみコミットして"'

alias gb 'git branch'
alias gco 'git checkout'
alias gm 'git merge'

alias gf 'git fetch'
alias gf! 'git fetch --prune'
alias gl 'git pull'
alias gp 'git push'
alias gp! 'git push --force'

# direnv
direnv hook fish | source
export EDITOR=vi
eval (direnv hook fish)

# anyenv
status --is-interactive; and source (anyenv init -|psub)

# Rust
fish_add_path "$HOME/.cargo/bin"

# Claude Code
alias yolo="claude --dangerously-skip-permissions"

# Keka
alias keka="/Applications/Keka.app/Contents/MacOS/Keka --cli 7zz a"

