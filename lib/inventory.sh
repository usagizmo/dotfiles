# shellcheck shell=bash
# 配線 inventory の SSOT。
# 追加・変更は原則ここだけ。init.sh / doctor.sh は run_inventory を呼ぶ。
#
# 使い方:
#   DOTFILES_DIR=... source lib/links.sh && source lib/inventory.sh
#   run_inventory apply   # 配線を適用
#   run_inventory check   # 健全性検査
#
# 行の意味:
#   inv_home <dir>                         harness home 等の実ディレクトリ
#   inv_symlink <repo_rel> <dst>           symlink（実ファイルは repo へ取り込んでから symlink 化）
#   inv_harness_skills <dst> <harness>     agents + harnesses/<agent>（後勝ち）
#   inv_collection <dst> [--exclude a,b] <repo_rel_src>...
#   inv_seed <repo_rel> <dst>              初回 copy（check は存在確認のみ）
#   inv_symlink_if_host <host_dir> <repo_rel> <dst>  host があるときだけ

# ---------- inventory 操作（apply / check） ----------

inv_home() {
  local dir=$1
  case "$DOTFILES_OP" in
    apply) ensure_dir "$dir" ;;
    check) check_home_dir "$dir" ;;
  esac
}

inv_symlink() {
  local rel=$1 dst=$2
  case "$DOTFILES_OP" in
    apply) link_from_repo "$rel" "$dst" ;;
    check) check_symlink "$dst" "$DOTFILES_DIR/$rel" ;;
  esac
}

inv_harness_skills() {
  local dst=$1 harness=$2
  case "$DOTFILES_OP" in
    apply) link_harness_skills "$dst" "$harness" ;;
    check) check_harness_skills "$dst" "$harness" ;;
  esac
}

# inv_collection <dst> [--exclude a,b] <repo_rel>...
# パスは空白区切り文字列にせず配列で渡す（スペース入り DOTFILES_DIR でも壊さない）
# set -u 下の空配列展開は ${arr[@]+"${arr[@]}"} で回避
inv_collection() {
  local dst=$1
  shift
  local has_exclude=0 exclude_csv="" rel
  local -a abs_srcs=()

  if [ "${1:-}" = "--exclude" ]; then
    has_exclude=1
    exclude_csv="${2:-}"
    shift 2
  fi
  for rel in "$@"; do
    abs_srcs+=("$DOTFILES_DIR/$rel")
  done

  case "$DOTFILES_OP" in
    apply)
      if [ "$has_exclude" -eq 1 ]; then
        link_collection_union "$dst" --exclude "$exclude_csv" ${abs_srcs[@]+"${abs_srcs[@]}"}
      else
        link_collection_union "$dst" ${abs_srcs[@]+"${abs_srcs[@]}"}
      fi
      ;;
    check)
      if [ "$has_exclude" -eq 1 ]; then
        check_collection_union "$dst" --exclude "$exclude_csv" ${abs_srcs[@]+"${abs_srcs[@]}"}
      else
        check_collection_union "$dst" ${abs_srcs[@]+"${abs_srcs[@]}"}
      fi
      ;;
  esac
}

inv_seed() {
  local rel=$1 dst=$2
  case "$DOTFILES_OP" in
    apply)
      ensure_dir "$(dirname "$dst")"
      if copy_if_missing "$DOTFILES_DIR/$rel" "$dst"; then
        echo "📝 $dst を編集して環境変数を設定してください"
      fi
      ;;
    check) check_seed_file "$DOTFILES_DIR/$rel" "$dst" ;;
  esac
}

inv_symlink_if_host() {
  local host_dir=$1 rel=$2 dst=$3
  if [ -d "$host_dir" ]; then
    inv_symlink "$rel" "$dst"
  else
    case "$DOTFILES_OP" in
      apply) echo "⚠️ $host_dir が無いためスキップ: $dst" ;;
      check) doctor_warn "$host_dir が無いためスキップ: $dst" ;;
    esac
  fi
}

inv_section() {
  # apply / check とも同じ見出し形式（doctor と揃える）
  echo ""
  echo "## $1"
}

# ---------- SSOT: 配線一覧 ----------
# harness / ツールを足すときは、ここに 1 ブロック足すだけで init と doctor に反映される。

inventory_define() {
  # --- Agents 共通 SSOT 投影 ---
  inv_section "agents (SSOT projection)"
  inv_home "$HOME/.agents"
  inv_symlink agents/AGENTS.md "$HOME/.agents/AGENTS.md"
  inv_symlink agents/skills "$HOME/.agents/skills"
  inv_symlink agents/.skill-lock.json "$HOME/.agents/.skill-lock.json"

  # --- Claude ---
  inv_section "claude"
  inv_home "$HOME/.claude"
  inv_symlink agents/AGENTS.md "$HOME/.claude/CLAUDE.md"
  inv_harness_skills "$HOME/.claude/skills" claude
  inv_symlink harnesses/claude/settings.json "$HOME/.claude/settings.json"
  inv_symlink harnesses/claude/statusline.py "$HOME/.claude/statusline.py"

  # --- Codex ---
  # Codex は ~/.agents/skills をネイティブに読む。union は harness 固有 overlay のみ
  inv_section "codex"
  inv_home "$HOME/.codex"
  inv_symlink agents/AGENTS.md "$HOME/.codex/AGENTS.md"
  inv_collection "$HOME/.codex/skills" harnesses/codex/skills
  inv_symlink harnesses/codex/hooks.json "$HOME/.codex/hooks.json"

  # --- Copilot ---
  inv_section "copilot"
  inv_home "$HOME/.copilot"
  inv_symlink harnesses/copilot/copilot-instructions.md "$HOME/.copilot/copilot-instructions.md"
  inv_symlink harnesses/copilot/mcp-config.json "$HOME/.copilot/mcp-config.json"
  inv_symlink harnesses/copilot/hooks/hooks.json "$HOME/.copilot/hooks/hooks.json"

  # --- Cursor CLI ---
  inv_section "cursor"
  inv_home "$HOME/.cursor"
  inv_symlink agents/AGENTS.md "$HOME/.cursor/AGENTS.md"
  inv_harness_skills "$HOME/.cursor/skills" cursor
  inv_symlink harnesses/cursor/hooks.json "$HOME/.cursor/hooks.json"

  # --- Devin ---
  inv_section "devin"
  inv_home "$HOME/.config"
  inv_home "$HOME/.config/devin"
  inv_symlink harnesses/devin/AGENTS.md "$HOME/.config/devin/AGENTS.md"
  inv_harness_skills "$HOME/.config/devin/skills" devin

  # --- Grok ---
  inv_section "grok"
  inv_home "$HOME/.grok"
  inv_symlink harnesses/grok/hooks/hooks.json "$HOME/.grok/hooks/hooks.json"
  inv_harness_skills "$HOME/.grok/skills" grok

  # --- Pi ---
  # settings は好みのみ。auth/trust/sessions/git cache は tracked にしない
  # Orca/Superset が書く extensions 実ファイルは union で温存（dotfiles 管理下 link のみ掃除）
  # /consult /finish は extensions/workflow.ts（slash 起動の SSOT。prompts は使わない）
  inv_section "pi"
  inv_home "$HOME/.pi"
  inv_home "$HOME/.pi/agent"
  inv_home "$HOME/.pi/agent/extensions"
  inv_symlink agents/AGENTS.md "$HOME/.pi/agent/AGENTS.md"
  inv_symlink harnesses/pi/settings.json "$HOME/.pi/agent/settings.json"
  inv_collection "$HOME/.pi/agent/extensions" harnesses/pi/extensions
  # pi は ~/.agents/skills をネイティブに読む（skills union なし）

  # --- Shell / editor / tools ---
  inv_section "shell / editor / tools"
  inv_symlink tmux/.tmux.conf "$HOME/.tmux.conf"
  inv_home "$HOME/.config/mise"
  inv_symlink mise/config.toml "$HOME/.config/mise/config.toml"
  inv_home "$HOME/.config/fish"
  inv_symlink fish/config.fish "$HOME/.config/fish/config.fish"
  inv_seed fish/env.fish "$HOME/.config/fish/conf.d/env.fish"
  inv_home "$HOME/.config/nvim"
  inv_symlink nvim/init.lua "$HOME/.config/nvim/init.lua"
  inv_symlink nvim/lua "$HOME/.config/nvim/lua"
  inv_home "$HOME/.config/yazi"
  inv_symlink yazi/yazi.toml "$HOME/.config/yazi/yazi.toml"
  inv_symlink yazi/theme.toml "$HOME/.config/yazi/theme.toml"
  inv_symlink ghostty "$HOME/.config/ghostty"
  inv_home "$HOME/Library/KeyBindings"
  inv_symlink Library/KeyBindings/DefaultKeyBinding.dict \
    "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  inv_symlink zsh/.zshrc "$HOME/.zshrc"

  # --- Cursor IDE（インストール時のみ） ---
  inv_section "cursor-app"
  inv_symlink_if_host \
    "$HOME/Library/Application Support/Cursor/User" \
    cursor-app/settings.json \
    "$HOME/Library/Application Support/Cursor/User/settings.json"
  inv_symlink_if_host \
    "$HOME/Library/Application Support/Cursor/User" \
    cursor-app/keybindings.json \
    "$HOME/Library/Application Support/Cursor/User/keybindings.json"
}

run_inventory() {
  local op=$1
  case "$op" in
    apply|check) ;;
    *)
      echo "run_inventory: unknown op: $op (apply|check)" >&2
      return 2
      ;;
  esac
  if [ -z "${DOTFILES_DIR:-}" ]; then
    echo "run_inventory: DOTFILES_DIR is not set" >&2
    return 2
  fi
  DOTFILES_OP=$op
  inventory_define
}
