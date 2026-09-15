# shellcheck shell=bash
# **この repo が何を配線するかの SSOT。**追加・変更は原則ここだけ。
# inv_* の実装と run_inventory は lib/links.sh（repo をまたいで共有する API）。
#
# 使い方:
#   REPO_DIR=... source lib/links.sh && source lib/inventory.sh
#   run_inventory apply   # 配線を適用
#   run_inventory check   # 健全性検査

# ---------- SSOT: 配線一覧 ----------
# ツールを足すときは、ここに 1 ブロック足すだけで init と doctor に反映される。
#
# **agent 設定（`~/.agents` / `~/.claude` / `~/.codex` / `~/.grok`）はここに無い。**
# agentfiles（兄弟 repo）が自分の lib/inventory.sh で張る。

inventory_define() {
  # --- Shell / editor / tools ---
  inv_section "shell / editor / tools"
  inv_home "$HOME/.config"
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
  inv_home "$HOME/.config/herdr"
  inv_symlink herdr/config.toml "$HOME/.config/herdr/config.toml"
  inv_symlink herdr/equalize-panes.py "$HOME/.config/herdr/equalize-panes.py"
  inv_symlink herdr/remove-worktree.py "$HOME/.config/herdr/remove-worktree.py"
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
