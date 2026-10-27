# 非対話シェルを含む全 zsh で読まれる（Claude Code の Bash ツールなど）

# ユーザーローカルのコマンド
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

# Rust (cargo)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# mise (ランタイムバージョン管理)
# 非対話シェルはプロンプトフックが走らないため、activate ではなく shims を PATH に通す
[ -x /opt/homebrew/bin/mise ] && eval "$(/opt/homebrew/bin/mise activate zsh --shims)"
