# shellcheck shell=bash
# symlink 配線の共通 primitive と inventory API（各 repo の init / up / doctor から source する）
# REPO_DIR は呼び出し側が自分の repo ルートに設定する。
# **dotfiles 専用ではない。**agentfiles など別 repo も自分の REPO_DIR を渡して同じ実装を使う
# （管理下判定・付け替え・prune がすべて REPO_DIR 基準なので、repo ごとに閉じる）

# **mise 管理ツールの解決規則をここに一本化する。**activate していないシェル（cron・
# GUI クライアント・素の sh）から叩かれても解決できるよう shims を足す。init / up /
# doctor でばらつくと「インストール済みなのに片方だけ失敗する」が起きる。
# hook は lib を source しないので、.githooks/pre-commit が同じ 1 行を自前で持つ
[ -d "$HOME/.local/share/mise/shims" ] && PATH="$PATH:$HOME/.local/share/mise/shims"

# ---------- counters（apply / check 共通） ----------
LINK_BLOCKED=${LINK_BLOCKED:-0}
DOCTOR_OK=${DOCTOR_OK:-0}
DOCTOR_FAIL=${DOCTOR_FAIL:-0}
DOCTOR_WARN=${DOCTOR_WARN:-0}
DOCTOR_QUIET=${DOCTOR_QUIET:-0}
SWEEP_REMOVED=${SWEEP_REMOVED:-0}
INV_KEEP_DESTS=()
INV_SCAN_ROOTS=()
INV_HOMES=()
INV_SWEEP_ROOTS=()
COLLECTION_NAMES=()

_inv_keep_add() {
  local dest=$1 item
  for item in "${INV_KEEP_DESTS[@]+"${INV_KEEP_DESTS[@]}"}"; do
    [ "$item" = "$dest" ] && return 0
  done
  INV_KEEP_DESTS+=("$dest")
}

_inv_scan_add() {
  local root=$1 item
  [ -n "$root" ] || return 0
  for item in "${INV_SCAN_ROOTS[@]+"${INV_SCAN_ROOTS[@]}"}"; do
    [ "$item" = "$root" ] && return 0
  done
  INV_SCAN_ROOTS+=("$root")
}

_inv_home_add() {
  local dir=$1 item
  for item in "${INV_HOMES[@]+"${INV_HOMES[@]}"}"; do
    [ "$item" = "$dir" ] && return 0
  done
  INV_HOMES+=("$dir")
  _inv_scan_add "$dir"
}

_inv_sweep_root_add() {
  local root=$1 item
  [ -n "$root" ] || return 0
  for item in "${INV_SWEEP_ROOTS[@]+"${INV_SWEEP_ROOTS[@]}"}"; do
    [ "$item" = "$root" ] && return 0
  done
  INV_SWEEP_ROOTS+=("$root")
}

# source の隠し名は配らない。keep-set は配列の完全一致（空白区切りにしない）
_collection_fill_names() {
  local exclude_csv=$1
  shift
  COLLECTION_NAMES=()
  local src_dir entry name item dup
  for src_dir in "$@"; do
    [ -d "$src_dir" ] || continue
    for entry in "$src_dir"/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      name="$(basename "$entry")"
      case "$name" in
        .*) continue ;;
      esac
      _is_excluded "$name" "$exclude_csv" && continue
      dup=0
      for item in "${COLLECTION_NAMES[@]+"${COLLECTION_NAMES[@]}"}"; do
        if [ "$item" = "$name" ]; then
          dup=1
          break
        fi
      done
      [ "$dup" -eq 0 ] && COLLECTION_NAMES+=("$name")
    done
  done
}

# 同名は後の source が勝つ。COLLECTION_SRC に絶対 path を書く
_collection_last_src() {
  local name=$1 src_dir
  shift
  COLLECTION_SRC=""
  for src_dir in "$@"; do
    [ -d "$src_dir" ] || continue
    if [ -e "$src_dir/$name" ] || [ -L "$src_dir/$name" ]; then
      COLLECTION_SRC="$src_dir/$name"
    fi
  done
}

ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "✅ ディレクトリを作成しました: $1"
  fi
}

link_blocked() {
  echo "⚠️ $1"
  LINK_BLOCKED=$((LINK_BLOCKED + 1))
}

doctor_pass() {
  DOCTOR_OK=$((DOCTOR_OK + 1))
  if [ "${DOCTOR_QUIET:-0}" -eq 0 ]; then
    echo "✅ $1"
  fi
}

doctor_fail() {
  DOCTOR_FAIL=$((DOCTOR_FAIL + 1))
  echo "❌ $1"
}

doctor_warn() {
  DOCTOR_WARN=$((DOCTOR_WARN + 1))
  echo "⚠️ $1"
}

# dst が実ディレクトリなら警告して non-zero（symlink 処理後に呼ぶ）
link_refuse_if_dir() {
  local dst=$1
  if [ -d "$dst" ]; then
    link_blocked "$dst は実ディレクトリです（symlink であるべき）。退避または削除してから init.sh を再実行してください"
    return 1
  fi
}

# 第3引数: new | force
try_symlink() {
  local src=$1 dst=$2 mode=${3:-new}
  if [ "$mode" = force ]; then
    if ln -sfn "$src" "$dst"; then
      echo "🔁 シンボリックリンクを更新しました: $dst -> $src"
      return 0
    fi
  else
    if ln -s "$src" "$dst"; then
      echo "✅ シンボリックリンクを作成しました: $dst -> $src"
      return 0
    fi
  fi
  link_blocked "symlink 作成に失敗しました: $dst -> $src"
  return 1
}

# 実ファイルは内容を repo 側へ取り込んでから symlink 化（差分は git で確認・discard 可能）。
# repo 外を指す symlink・実ディレクトリは触らず警告
link_path() {
  local src=$1 dst=$2 current parent
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    link_blocked "symlink 元が存在しないためスキップします: $src"
    return 1
  fi
  parent="$(dirname "$dst")"
  ensure_dir "$parent"
  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "⏭️ $dst のシンボリックリンクは既に存在します"
      return 0
    elif [ "${current#"$REPO_DIR"/}" != "$current" ]; then
      try_symlink "$src" "$dst" force
      return $?
    else
      link_blocked "$dst は別の場所を指しているためスキップします: $current"
      return 1
    fi
  fi
  link_refuse_if_dir "$dst" || return 1
  if [ -e "$dst" ]; then
    if ! cmp -s "$src" "$dst"; then
      if cp "$dst" "$src"; then
        echo "📥 実ファイルの内容を repo に取り込みました: $src <- $dst"
      else
        link_blocked "$dst の内容を $src へ取り込めなかったため symlink を作成できません"
        return 1
      fi
    fi
    if rm "$dst"; then
      echo "🗑️ 既存のファイルを削除しました: $dst"
    else
      link_blocked "$dst の削除に失敗したため symlink を作成できません"
      return 1
    fi
  fi
  try_symlink "$src" "$dst" new
}

link_from_repo() {
  link_path "$REPO_DIR/$1" "$2"
}

# コレクション項目: 既存 symlink は常に付け替え可。実体は触らず警告
link_collection_entry() {
  local src=$1 dst=$2 current
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    link_blocked "symlink 元が存在しないためスキップします: $src"
    return 1
  fi
  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "⏭️ $dst のシンボリックリンクは既に存在します"
      return 0
    fi
    try_symlink "$src" "$dst" force
    return $?
  fi
  link_refuse_if_dir "$dst" || return 1
  if [ -e "$dst" ]; then
    link_blocked "$dst は実ファイルです（symlink であるべき）。退避または削除してから init.sh を再実行してください"
    return 1
  fi
  try_symlink "$src" "$dst" new
}

is_repo_managed_link() {
  local link=$1 current resolved
  [ -L "$link" ] || return 1
  current="$(readlink "$link")"
  case "$current" in
    "$REPO_DIR"/*) return 0 ;;
  esac
  resolved="$(realpath "$link" 2>/dev/null)" || return 1
  case "$resolved" in
    "$REPO_DIR"/*) return 0 ;;
  esac
  return 1
}

# link_collection_union <dst> [--exclude name,name,...] <src_dir>...
link_collection_union() {
  local dst=$1
  shift
  local exclude_csv="" src_dir name has_src=0

  if [ "${1:-}" = "--exclude" ]; then
    exclude_csv="${2:-}"
    shift 2
  fi

  for src_dir in "$@"; do
    if [ -d "$src_dir" ]; then
      has_src=1
      break
    fi
  done
  if [ "$has_src" -eq 0 ] && [ ! -d "$dst" ]; then
    return 0
  fi
  ensure_dir "$dst"

  _collection_fill_names "$exclude_csv" "$@"
  for name in "${COLLECTION_NAMES[@]+"${COLLECTION_NAMES[@]}"}"; do
    _collection_last_src "$name" "$@"
    [ -n "$COLLECTION_SRC" ] || continue
    link_collection_entry "$COLLECTION_SRC" "$dst/$name"
  done
}

copy_if_missing() {
  local src=$1 dst=$2
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "⏭️ $dst は既に存在します"
    return 1
  fi
  [ -L "$dst" ] && rm "$dst"
  cp "$src" "$dst" 2>/dev/null && echo "✅ ファイルをコピーしました: $dst <- $src"
}

# ---------- doctor (check) primitives ----------

# check_symlink <dst> <expected_abs>
check_symlink() {
  local dst=$1 expected=$2
  local current resolved expected_resolved

  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$expected" ]; then
      if [ -e "$dst" ] || [ -d "$dst" ]; then
        doctor_pass "$dst -> $expected"
      else
        doctor_fail "$dst は壊れた symlink です: $current"
      fi
      return 0
    fi
    resolved="$(realpath "$dst" 2>/dev/null || true)"
    expected_resolved="$(realpath "$expected" 2>/dev/null || true)"
    if [ -n "$resolved" ] && [ -n "$expected_resolved" ] && [ "$resolved" = "$expected_resolved" ]; then
      doctor_warn "$dst は expected と実体は一致するが path 表記が違う: $current （expected: ${expected}）"
      return 0
    fi
    doctor_fail "$dst のリンク先が違う: $current （expected: ${expected}）"
    return 0
  fi

  if [ -d "$dst" ]; then
    doctor_fail "$dst は実ディレクトリです（symlink であるべき）"
    return 0
  fi
  if [ -e "$dst" ]; then
    doctor_fail "$dst は実ファイルです（symlink であるべき）"
    return 0
  fi
  doctor_fail "$dst がありません（expected symlink -> ${expected}）"
}

check_collection_root() {
  local dst=$1
  if [ -L "$dst" ]; then
    doctor_fail "$dst が symlink です（skills/agents の親は実ディレクトリであるべき）: $(readlink "$dst")"
    return 1
  fi
  if [ -d "$dst" ]; then
    doctor_pass "$dst は実ディレクトリ（union 土台）"
    return 0
  fi
  if [ -e "$dst" ]; then
    doctor_fail "$dst は実ファイルです（実ディレクトリであるべき）"
    return 1
  fi
  doctor_fail "$dst がありません（init.sh 未実行の可能性）"
  return 1
}

_is_excluded() {
  local name=$1 exclude_csv=$2
  [ -z "$exclude_csv" ] && return 1
  case ",$exclude_csv," in
    *",$name,"*) return 0 ;;
    *) return 1 ;;
  esac
}

# check_collection_union <dst> [--exclude a,b] <src_dir>...
# src_dir は "$@" のまま扱い、空白区切り文字列に潰さない
# 配布対象外の管理下 symlink は sweep_managed_links が判定する
check_collection_union() {
  local dst=$1
  shift
  local exclude_csv="" src_dir name
  local has_src=0

  if [ "${1:-}" = "--exclude" ]; then
    exclude_csv="${2:-}"
    shift 2
  fi

  for src_dir in "$@"; do
    if [ -d "$src_dir" ]; then
      has_src=1
      break
    fi
  done

  if [ "$has_src" -eq 0 ] && [ ! -d "$dst" ] && [ ! -L "$dst" ]; then
    doctor_pass "$dst は未作成（source も無し = 正常）"
    return 0
  fi

  check_collection_root "$dst" || return 0

  _collection_fill_names "$exclude_csv" "$@"
  for name in "${COLLECTION_NAMES[@]+"${COLLECTION_NAMES[@]}"}"; do
    _collection_last_src "$name" "$@"
    [ -n "$COLLECTION_SRC" ] || continue
    check_symlink "$dst/$name" "$COLLECTION_SRC"
  done

  if [ -n "$exclude_csv" ] && [ -d "$dst" ]; then
    local ex oldifs=$IFS
    IFS=,
    # shellcheck disable=SC2086
    set -- $exclude_csv
    IFS=$oldifs
    for ex in "$@"; do
      [ -n "$ex" ] || continue
      if [ -L "$dst/$ex" ]; then
        continue
      elif [ -e "$dst/$ex" ]; then
        doctor_warn "$dst/$ex は exclude 対象だが実体が存在します（vendor なら無視可）"
      fi
    done
  fi
}

# check_seed_file <template> <dst>
# 存在に加え、テンプレートの `set -gx VAR value` を突き合わせる:
# dst に VAR が無い、または値がテンプレート（placeholder）のままなら warn
check_seed_file() {
  local template=$1 dst=$2 line var placeholder actual missing=0
  if [ ! -f "$dst" ] && [ ! -L "$dst" ]; then
    doctor_warn "$dst が無い（init.sh で copy される）"
    return 0
  fi
  while IFS= read -r line; do
    var=$(echo "$line" | awk '{print $3}')
    placeholder=$(echo "$line" | awk '{print $4}')
    actual=$(grep -E "^set -gx $var " "$dst" | awk '{print $4}')
    if [ -z "$actual" ]; then
      doctor_warn "$dst に $var が定義されていません（テンプレート: ${template}）"
      missing=1
    elif [ "$actual" = "$placeholder" ]; then
      doctor_warn "$dst の $var が placeholder のままです: $placeholder"
      missing=1
    fi
  done < <(grep -E '^set -gx ' "$template")
  if [ "$missing" -eq 0 ]; then
    doctor_pass "$dst が存在し、テンプレートの変数が設定済み（seed）"
  fi
}

# check_guard_dir <dst> [allow_csv]
# 「管理下 symlink と allowlist 以外は置かれないはず」の dir を監視する。
# 外部ツールが落とした想定外エントリを warn で可視化する（read-only。削除はしない）
check_guard_dir() {
  local dst=$1 allow_csv=${2:-} entry name unexpected=0
  if [ ! -d "$dst" ] || [ -L "$dst" ]; then
    doctor_fail "$dst が実ディレクトリではありません（監視対象 dir）"
    return 0
  fi
  for entry in "$dst"/* "$dst"/.[!.]* "$dst"/..?*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    name="$(basename "$entry")"
    _is_excluded "$name" "$allow_csv" && continue
    is_repo_managed_link "$entry" && continue
    doctor_warn "$dst に想定外のエントリがあります: ${name}（外部ツールが書き込んだ可能性）"
    unexpected=$((unexpected + 1))
  done
  if [ "$unexpected" -eq 0 ]; then
    doctor_pass "$dst は管理下エントリのみ（想定外の書き込みなし）"
  fi
  return 0
}

check_home_dir() {
  local dst=$1
  if [ -d "$dst" ] && [ ! -L "$dst" ]; then
    doctor_pass "$dst は実ディレクトリ"
  elif [ -L "$dst" ]; then
    doctor_fail "$dst が symlink です（harness home は実ディレクトリであるべき）"
  elif [ -e "$dst" ]; then
    doctor_fail "$dst は実ファイルです（実ディレクトリであるべき）"
  else
    doctor_fail "$dst がありません"
  fi
}

# commit gate（.githooks/pre-commit）の配線を検査する。
# 道具が無いと hook は commit を止めるだけになるので、道具の有無もここで見る。修復は ./init.sh
check_commit_gate() {
  local current
  # 未設定なら git config は exit 1（doctor.sh は set -e なので握る）
  current="$(git -C "$REPO_DIR" config --get core.hooksPath || true)"
  if [ "$current" != ".githooks" ]; then
    doctor_fail "core.hooksPath が .githooks ではありません: ${current:-未設定}"
  elif [ ! -x "$REPO_DIR/.githooks/pre-commit" ]; then
    doctor_fail "$REPO_DIR/.githooks/pre-commit が実行可能ではありません"
  else
    doctor_pass "core.hooksPath=.githooks（pre-commit は実行可能）"
  fi
  # hook と同じ解決順で見る（hook は mise activate が無い環境向けに shims も足す）。
  # oxfmt / oxlint は node_modules 側なので、見るのは bun と依存の有無
  if command -v bun >/dev/null 2>&1 || [ -x "$HOME/.local/share/mise/shims/bun" ]; then
    doctor_pass "bun を hook から解決できます"
  else
    doctor_fail "bun が見つかりません（この状態では commit が止まります）"
  fi
  # hook は bun run で repo-local の実体を呼ぶ（bunx だと registry から引いて通ってしまう）
  if [ -x "$REPO_DIR/node_modules/.bin/lint-staged" ]; then
    doctor_pass "開発依存が入っています"
  else
    doctor_fail "開発依存が入っていません（この状態では commit が止まります）"
  fi
  return 0
}

# tracked ファイルに絶対 home パスが無いか検査する。
# 別マシンで init.sh すると壊れるうえ、public repo ではユーザー名が露出する。
# 外部ツール（herdr 等）が tracked な設定へ書き戻すことがあるので定期的に見る
check_absolute_home_paths() {
  local hit found=0
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    doctor_warn "絶対 home パスが tracked ファイルにあります: ${hit}（\$HOME か ~ に置き換える）"
    found=$((found + 1))
  # [U] / [h] は自己マッチ回避。この行自体が検出対象にならないようにする
  done < <(git -C "$REPO_DIR" grep -nE "(/[U]sers/|/[h]ome/)[^/[:space:]\"']+/" -- . 2>/dev/null || true)
  if [ "$found" -eq 0 ]; then
    doctor_pass "tracked ファイルに絶対 home パスなし（別環境で init.sh 可能）"
  fi
  return 0
}

# 行の意味:
#   inv_home <dir>                         harness home 等の実ディレクトリ
#   inv_symlink <repo_rel> <dst>           symlink（実ファイルは repo へ取り込んでから symlink 化）
#   inv_harness_skills <dst> <harness>     agents + harnesses/<agent>（後勝ち）
#   inv_collection <dst> [--exclude a,b] <repo_rel_src>...
#   inv_seed <repo_rel> <dst>              初回 copy（check は存在確認のみ）
#   inv_symlink_if_host <host_dir> <repo_rel> <dst>  host があるときだけ
#   inv_guard_dir <dst> [allow_csv]        doctor 専用。想定外エントリを warn

# 管理下判定は readlink の prefix。realpath には頼らない（壊れた link を拾う）
sweep_managed_links() {
  local op=$1
  local root child entry current item keep broken
  INV_SWEEP_ROOTS=()
  for root in "${INV_SCAN_ROOTS[@]+"${INV_SCAN_ROOTS[@]}"}"; do
    _inv_sweep_root_add "$root"
  done
  for root in "${INV_HOMES[@]+"${INV_HOMES[@]}"}"; do
    [ -d "$root" ] || continue
    [ -L "$root" ] && continue
    for child in "$root"/* "$root"/.[!.]* "$root"/..?*; do
      [ -d "$child" ] || continue
      [ -L "$child" ] && continue
      _inv_sweep_root_add "$child"
    done
  done
  for root in "${INV_SWEEP_ROOTS[@]+"${INV_SWEEP_ROOTS[@]}"}"; do
    [ -d "$root" ] || continue
    [ -L "$root" ] && continue
    for entry in "$root"/* "$root"/.[!.]* "$root"/..?*; do
      [ -L "$entry" ] || continue
      keep=0
      for item in "${INV_KEEP_DESTS[@]+"${INV_KEEP_DESTS[@]}"}"; do
        if [ "$item" = "$entry" ]; then
          keep=1
          break
        fi
      done
      [ "$keep" -eq 1 ] && continue
      current="$(readlink "$entry")"
      case "$current" in
        "$REPO_DIR"/*) ;;
        *) continue ;;
      esac
      if [ "$op" = apply ]; then
        if [ -e "$entry" ] || [ -d "$entry" ]; then
          broken=0
        else
          broken=1
        fi
        if rm "$entry"; then
          SWEEP_REMOVED=$((SWEEP_REMOVED + 1))
          if [ "$broken" -eq 1 ]; then
            echo "🗑️ 壊れたシンボリックリンクを削除しました: $entry"
          else
            echo "🗑️ 配布対象外のシンボリックリンクを削除しました: $entry"
          fi
        else
          link_blocked "配布対象外の symlink を削除できませんでした: $entry"
        fi
      else
        if [ -e "$entry" ] || [ -d "$entry" ]; then
          doctor_fail "$entry は管理下 symlink だが配布対象外です: $current"
        else
          doctor_fail "$entry は壊れた管理下 symlink です: $current"
        fi
      fi
    done
  done
}

# ---------- inventory 操作（collect / apply / check） ----------

inv_home() {
  local dir=$1
  case "$REPO_OP" in
    collect) _inv_home_add "$dir" ;;
    apply) ensure_dir "$dir" ;;
    check) check_home_dir "$dir" ;;
  esac
}

inv_symlink() {
  local rel=$1 dst=$2
  case "$REPO_OP" in
    collect)
      _inv_keep_add "$dst"
      _inv_scan_add "$(dirname "$dst")"
      ;;
    apply) link_from_repo "$rel" "$dst" ;;
    check) check_symlink "$dst" "$REPO_DIR/$rel" ;;
  esac
}

inv_harness_skills() {
  local dst=$1 harness=$2
  inv_collection "$dst" "agents/skills" "harnesses/$harness/skills"
}

# inv_collection <dst> [--exclude a,b] <repo_rel>...
# パスは空白区切り文字列にせず配列で渡す（スペース入り REPO_DIR でも壊さない）
# set -u 下の空配列展開は ${arr[@]+"${arr[@]}"} で回避
inv_collection() {
  local dst=$1
  shift
  local has_exclude=0 exclude_csv="" rel name
  local -a abs_srcs=()

  if [ "${1:-}" = "--exclude" ]; then
    has_exclude=1
    exclude_csv="${2:-}"
    shift 2
  fi
  for rel in "$@"; do
    abs_srcs+=("$REPO_DIR/$rel")
  done

  case "$REPO_OP" in
    collect)
      _inv_scan_add "$dst"
      _collection_fill_names "$exclude_csv" ${abs_srcs[@]+"${abs_srcs[@]}"}
      for name in "${COLLECTION_NAMES[@]+"${COLLECTION_NAMES[@]}"}"; do
        _inv_keep_add "$dst/$name"
      done
      ;;
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
  case "$REPO_OP" in
    collect)
      _inv_keep_add "$dst"
      _inv_scan_add "$(dirname "$dst")"
      ;;
    apply)
      ensure_dir "$(dirname "$dst")"
      if copy_if_missing "$REPO_DIR/$rel" "$dst"; then
        echo "📝 $dst を編集して環境変数を設定してください"
      fi
      ;;
    check) check_seed_file "$REPO_DIR/$rel" "$dst" ;;
  esac
}

inv_symlink_if_host() {
  local host_dir=$1 rel=$2 dst=$3
  if [ "$REPO_OP" = collect ] || [ -d "$host_dir" ]; then
    inv_symlink "$rel" "$dst"
    return 0
  fi
  case "$REPO_OP" in
    apply) echo "⚠️ $host_dir が無いためスキップ: $dst" ;;
    check) doctor_warn "$host_dir が無いためスキップ: $dst" ;;
  esac
}

# hooks 等の tripwire dir。apply は何もしない（検知専用。勝手に消さない）
inv_guard_dir() {
  local dst=$1 allow_csv=${2:-}
  case "$REPO_OP" in
    check) check_guard_dir "$dst" "$allow_csv" ;;
  esac
}

inv_section() {
  [ "$REPO_OP" = collect ] && return 0
  echo ""
  echo "## $1"
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
  if [ -z "${REPO_DIR:-}" ]; then
    echo "run_inventory: REPO_DIR is not set" >&2
    return 2
  fi
  INV_KEEP_DESTS=()
  INV_SCAN_ROOTS=()
  INV_HOMES=()
  INV_SWEEP_ROOTS=()
  SWEEP_REMOVED=0
  REPO_OP=collect
  inventory_define
  REPO_OP=$op
  inventory_define
  sweep_managed_links "$op"
}
