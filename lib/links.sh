# shellcheck shell=bash
# symlink 配線の共通 primitive（init / doctor から source する）
# DOTFILES_DIR は呼び出し側で設定済みであること

# ---------- counters（apply / check 共通） ----------
LINK_BLOCKED=${LINK_BLOCKED:-0}
DOCTOR_OK=${DOCTOR_OK:-0}
DOCTOR_FAIL=${DOCTOR_FAIL:-0}
DOCTOR_WARN=${DOCTOR_WARN:-0}
DOCTOR_QUIET=${DOCTOR_QUIET:-0}

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

# dst が「symlink にできない実体」なら警告して non-zero
link_refuse_if_solid() {
  local dst=$1
  if [ -L "$dst" ]; then
    return 0
  fi
  if [ -d "$dst" ]; then
    link_blocked "$dst は実ディレクトリです（symlink であるべき）。退避または削除してから init.sh を再実行してください"
    return 1
  fi
  if [ -e "$dst" ]; then
    link_blocked "$dst は実ファイルです（symlink であるべき）。退避または削除してから init.sh を再実行してください"
    return 1
  fi
  return 0
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
    elif [ "${current#$DOTFILES_DIR/}" != "$current" ]; then
      try_symlink "$src" "$dst" force
      return $?
    else
      link_blocked "$dst は別の場所を指しているためスキップします: $current"
      return 1
    fi
  fi
  link_refuse_if_solid "$dst" || return 1
  try_symlink "$src" "$dst" new
}

link_from_repo() {
  link_path "$DOTFILES_DIR/$1" "$2"
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
  link_refuse_if_solid "$dst" || return 1
  try_symlink "$src" "$dst" new
}

is_dotfiles_managed_link() {
  local link=$1 current resolved
  [ -L "$link" ] || return 1
  current="$(readlink "$link")"
  case "$current" in
    "$DOTFILES_DIR"/*) return 0 ;;
  esac
  resolved="$(realpath "$link" 2>/dev/null)" || return 1
  case "$resolved" in
    "$DOTFILES_DIR"/*) return 0 ;;
  esac
  return 1
}

# link_collection_union <dst> [--exclude name,name,...] <src_dir>...
link_collection_union() {
  local dst=$1
  shift
  local exclude_csv="" src_dir entry name link desired="" has_src=0

  if [ "${1:-}" = "--exclude" ]; then
    exclude_csv=",${2:-},"
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

  for src_dir in "$@"; do
    [ -d "$src_dir" ] || continue
    for entry in "$src_dir"/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      name="$(basename "$entry")"
      case "$name" in
        .*) continue ;;
      esac
      if [ -n "$exclude_csv" ]; then
        case "$exclude_csv" in
          *",$name,"*) continue ;;
        esac
      fi
      link_collection_entry "$entry" "$dst/$name"
      desired="$desired $name "
    done
  done

  for link in "$dst"/*; do
    [ -L "$link" ] || continue
    name="$(basename "$link")"
    if [ ! -e "$link" ]; then
      case "$(readlink "$link")" in
        "$DOTFILES_DIR"/*)
          rm "$link"
          echo "🗑️ 壊れたシンボリックリンクを削除しました: $link"
          ;;
      esac
      continue
    fi
    is_dotfiles_managed_link "$link" || continue
    case "$desired" in
      *" $name "*) ;;
      *)
        rm "$link"
        echo "🗑️ 配布対象外のシンボリックリンクを削除しました: $link"
        ;;
    esac
  done
}

# link_harness_skills <dst> <harness>
# source 優先度: agents/skills < harnesses/shared/skills < harnesses/<agent>/skills
# harnesses/shared は home を持たない共有束（疑似 harness ではない）
# shared を載せない harness（例: Codex）は inv_collection で source を明示する
link_harness_skills() {
  local dst=$1 harness=$2
  link_collection_union "$dst" \
    "$DOTFILES_DIR/agents/skills" \
    "$DOTFILES_DIR/harnesses/shared/skills" \
    "$DOTFILES_DIR/harnesses/$harness/skills"
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

# 実ファイルは差し替え。実ディレクトリは消さず警告
link_replace() {
  local src=$1 dst=$2 current
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    link_blocked "symlink 元が存在しないためスキップします: $src"
    return 1
  fi
  if [ -L "$dst" ]; then
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "⏭️ $dst は既にシンボリックリンクです"
      return 0
    fi
    try_symlink "$src" "$dst" force
    return $?
  fi
  if [ -d "$dst" ]; then
    link_blocked "$dst は実ディレクトリです（symlink であるべき）。退避または削除してから init.sh を再実行してください"
    return 1
  fi
  if [ -e "$dst" ]; then
    if rm "$dst"; then
      echo "🗑️ 既存のファイルを削除しました: $dst"
    else
      link_blocked "$dst の削除に失敗したため symlink を作成できません"
      return 1
    fi
  fi
  try_symlink "$src" "$dst" new
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
      doctor_warn "$dst は expected と実体は一致するが path 表記が違う: $current （expected: $expected）"
      return 0
    fi
    doctor_fail "$dst のリンク先が違う: $current （expected: $expected）"
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
  doctor_fail "$dst がありません（expected symlink -> $expected）"
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
check_collection_union() {
  local dst=$1
  shift
  local exclude_csv="" src_dir name entry current expected desired="" resolved managed
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

  for src_dir in "$@"; do
    [ -d "$src_dir" ] || continue
    for entry in "$src_dir"/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      name="$(basename "$entry")"
      case "$name" in
        .*) continue ;;
      esac
      _is_excluded "$name" "$exclude_csv" && continue
      case " $desired " in
        *" $name "*) ;;
        *) desired="$desired $name " ;;
      esac
    done
  done

  for name in $desired; do
    expected=""
    for src_dir in "$@"; do
      [ -d "$src_dir" ] || continue
      if [ -e "$src_dir/$name" ] || [ -L "$src_dir/$name" ]; then
        expected="$src_dir/$name"
      fi
    done
    [ -n "$expected" ] || continue
    check_symlink "$dst/$name" "$expected"
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
        current="$(readlink "$dst/$ex")"
        managed=0
        case "$current" in
          "$DOTFILES_DIR"/*) managed=1 ;;
        esac
        if [ "$managed" -eq 0 ] && { [ -e "$dst/$ex" ] || [ -d "$dst/$ex" ]; }; then
          resolved="$(realpath "$dst/$ex" 2>/dev/null || true)"
          case "$resolved" in
            "$DOTFILES_DIR"/*) managed=1 ;;
          esac
        fi
        if [ "$managed" -eq 1 ]; then
          doctor_fail "$dst/$ex は exclude 対象なのに管理下 symlink が残っています: $current"
        fi
      elif [ -e "$dst/$ex" ]; then
        doctor_warn "$dst/$ex は exclude 対象だが実体が存在します（vendor なら無視可）"
      fi
    done
  fi

  [ -d "$dst" ] || return 0

  for entry in "$dst"/*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    name="$(basename "$entry")"
    case "$name" in
      .*) continue ;;
    esac
    [ -L "$entry" ] || continue

    current="$(readlink "$entry")"
    if [ ! -e "$entry" ] && [ ! -d "$entry" ]; then
      case "$current" in
        "$DOTFILES_DIR"/*)
          doctor_fail "$entry は壊れた管理下 symlink です: $current"
          ;;
        *)
          doctor_warn "$entry は壊れた symlink です: $current"
          ;;
      esac
      continue
    fi

    managed=0
    case "$current" in
      "$DOTFILES_DIR"/*) managed=1 ;;
    esac
    if [ "$managed" -eq 0 ]; then
      resolved="$(realpath "$entry" 2>/dev/null || true)"
      case "$resolved" in
        "$DOTFILES_DIR"/*) managed=1 ;;
      esac
    fi
    if [ "$managed" -eq 1 ]; then
      case " $desired " in
        *" $name "*) ;;
        *)
          doctor_fail "$entry は管理下 symlink だが配布対象外です: $current"
          ;;
      esac
    fi
  done
}

check_harness_skills() {
  local dst=$1 harness=$2
  check_collection_union "$dst" \
    "$DOTFILES_DIR/agents/skills" \
    "$DOTFILES_DIR/harnesses/shared/skills" \
    "$DOTFILES_DIR/harnesses/$harness/skills"
}

check_seed_file() {
  local dst=$1
  if [ -f "$dst" ] || [ -L "$dst" ]; then
    doctor_pass "$dst が存在する（seed）"
  else
    doctor_warn "$dst が無い（init.sh で copy される）"
  fi
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
