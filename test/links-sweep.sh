#!/bin/bash
# run_inventory の sweep 回帰。一時 HOME と一時 repo だけで測る。
# live の配布先は触らない。
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/links.sh
. "$ROOT/lib/links.sh"

PASS=0
FAIL=0
CLEANUP_DIRS=()

cleanup() {
  local d
  for d in "${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

ok() {
  PASS=$((PASS + 1))
  echo "ok $* "
}

not_ok() {
  FAIL=$((FAIL + 1))
  echo "not ok $* "
}

assert_missing() {
  local path=$1 msg=$2
  if [ -e "$path" ] || [ -L "$path" ]; then
    not_ok "$msg (残っている: $path)"
  else
    ok "$msg"
  fi
}

assert_exists() {
  local path=$1 msg=$2
  if [ -e "$path" ] || [ -L "$path" ]; then
    ok "$msg"
  else
    not_ok "$msg (消えている: $path)"
  fi
}

assert_link() {
  local path=$1 expected=$2 msg=$3
  local current
  if [ ! -L "$path" ]; then
    not_ok "$msg (symlink でない: $path)"
    return 0
  fi
  current="$(readlink "$path")"
  if [ "$current" = "$expected" ]; then
    ok "$msg"
  else
    not_ok "$msg (got $current)"
  fi
}

assert_eq() {
  local got=$1 want=$2 msg=$3
  if [ "$got" = "$want" ]; then
    ok "$msg"
  else
    not_ok "$msg (got $got want $want)"
  fi
}

assert_output_lacks() {
  local output=$1 needle=$2 msg=$3
  case "$output" in
    *"$needle"*) not_ok "$msg" ;;
    *) ok "$msg" ;;
  esac
}

new_env() {
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/links-sweep.XXXXXX")"
  CLEANUP_DIRS+=("$tmp")
  export HOME="$tmp/home"
  export REPO_DIR="$tmp/repo"
  mkdir -p \
    "$HOME/.config/herdr" \
    "$HOME/.config/skills" \
    "$HOME/.config/fish/conf.d" \
    "$REPO_DIR/herdr" \
    "$REPO_DIR/skills/keep" \
    "$REPO_DIR/seed"
  printf 'keep\n' > "$REPO_DIR/herdr/foo.py"
  printf 'stale\n' > "$REPO_DIR/herdr/stale.ts"
  printf 'keep-item\n' > "$REPO_DIR/skills/keep/file"
  printf 'seed\n' > "$REPO_DIR/seed/env.fish"
  LINK_BLOCKED=0
  DOCTOR_OK=0
  DOCTOR_FAIL=0
  DOCTOR_WARN=0
  DOCTOR_QUIET=1
  SWEEP_REMOVED=0
}

inventory_define() {
  inv_section "test"
  inv_home "$HOME/.config"
  inv_home "$HOME/.config/herdr"
  inv_symlink herdr/foo.py "$HOME/.config/herdr/foo.py"
  inv_symlink herdr/foo.py "$HOME/.config/herdr/my file.py"
  inv_symlink missing/gone.txt "$HOME/.config/herdr/gone.txt"
  inv_symlink_if_host \
    "$HOME/Library/Application Support/DoesNotExist" \
    cursor/settings.json \
    "$HOME/Library/Application Support/DoesNotExist/settings.json"
  inv_collection "$HOME/.config/skills" skills
  inv_seed seed/env.fish "$HOME/.config/fish/conf.d/env.fish"
}

plant_managed() {
  local dest=$1 rel=${2:-herdr/stale.ts}
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$REPO_DIR/$rel" "$dest"
}

echo "# apply: 消す側"

new_env
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/foo.py"
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/my file.py"
plant_managed "$HOME/.config/herdr/stale.ts"
plant_managed "$HOME/.config/herdr/.hidden-stale"
plant_managed "$HOME/.config/herdr/stale file.ts"
plant_managed "$HOME/.config/herdr/broken.ts" herdr/does-not-exist.ts
mkdir -p "$HOME/.config/oldtool"
plant_managed "$HOME/.config/oldtool/leftover"
plant_managed "$HOME/.config/skills/extra"
run_inventory apply >/dev/null || true
assert_missing "$HOME/.config/herdr/stale.ts" "apply は単一ファイル dest の stale を消す"
assert_missing "$HOME/.config/herdr/.hidden-stale" "apply は隠し名の stale を消す"
assert_missing "$HOME/.config/herdr/stale file.ts" "apply は空白を含む stale dest を消す"
assert_missing "$HOME/.config/herdr/broken.ts" "apply は壊れた管理下 link を消す"
assert_missing "$HOME/.config/oldtool/leftover" "apply は inv_home 直下 dir の取り残しを消す"
assert_missing "$HOME/.config/skills/extra" "apply はコレクションの stale を消す"
assert_link "$HOME/.config/herdr/foo.py" "$REPO_DIR/herdr/foo.py" "apply は keep dest を残す"
assert_link "$HOME/.config/herdr/my file.py" "$REPO_DIR/herdr/foo.py" "apply は空白を含む keep dest を残す"

echo "# apply: 消さない側"

new_env
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/foo.py"
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/my file.py"
ln -sfn /tmp/links-sweep-outside "$HOME/.config/herdr/outside"
printf 'real\n' > "$HOME/.config/herdr/real.txt"
mkdir -p "$HOME/.config/herdr/realdir"
plant_managed "$HOME/.config/herdr/gone.txt"
mkdir -p "$HOME/Library/Application Support/DoesNotExist"
plant_managed "$HOME/Library/Application Support/DoesNotExist/settings.json"
plant_managed "$HOME/.config/fish/conf.d/env.fish"
out="$(run_inventory apply 2>&1 || true)"
assert_exists "$HOME/.config/herdr/outside" "apply は repo 外 link を消さない"
assert_exists "$HOME/.config/herdr/real.txt" "apply は実ファイルを消さない"
assert_exists "$HOME/.config/herdr/realdir" "apply は実ディレクトリを消さない"
assert_exists "$HOME/.config/herdr/gone.txt" "apply は source 欠落の dest を keep する"
assert_exists "$HOME/Library/Application Support/DoesNotExist/settings.json" "apply は host が無い inv_symlink_if_host dest を keep する"
assert_exists "$HOME/.config/fish/conf.d/env.fish" "apply は seed dest を prune しない"
assert_output_lacks "$out" "想定外" "apply は想定外実体の warn を出さない"

echo "# apply: sweep だけでは非ゼロにしない"

new_env
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/foo.py"
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/my file.py"
plant_managed "$HOME/.config/herdr/stale.ts"
inventory_define_keep_only() {
  inv_home "$HOME/.config"
  inv_home "$HOME/.config/herdr"
  inv_symlink herdr/foo.py "$HOME/.config/herdr/foo.py"
  inv_symlink herdr/foo.py "$HOME/.config/herdr/my file.py"
}
inventory_define() { inventory_define_keep_only; }
set +e
run_inventory apply >/dev/null
sweep_rc=$?
set -e
assert_eq "$sweep_rc" "0" "apply の sweep は非ゼロ終了にしない"
assert_missing "$HOME/.config/herdr/stale.ts" "keep-only inventory でも stale を消す"

echo "# check: 同じずれを失敗にし、消さない"

new_env
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/foo.py"
ln -sfn "$REPO_DIR/herdr/foo.py" "$HOME/.config/herdr/my file.py"
plant_managed "$HOME/.config/herdr/stale.ts"
run_inventory check >/dev/null || true
assert_exists "$HOME/.config/herdr/stale.ts" "check は配布先を消さない"
if [ "$DOCTOR_FAIL" -gt 0 ]; then
  ok "check は stale を失敗にする (fail=$DOCTOR_FAIL)"
else
  not_ok "check は stale を失敗にする (fail=$DOCTOR_FAIL)"
fi

echo "# summary"
echo "pass=$PASS fail=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
