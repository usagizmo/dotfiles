#!/usr/bin/env python3
"""フォーカス中の workspace の worktree を branch ごと削除する。

組み込みの remove_worktree は checkout しか消さず branch が残るため、
herdr の popup（type = "popup" の custom command）内で確認したうえで
`herdr worktree remove` と `git branch -d` を続けて実行する。
"""

import json
import os
import subprocess
import sys
import time

TRASH = os.path.expanduser("~/.wt-trash")

# 削除の所要時間はファイル数で決まる。node_modules / cargo target を
# rm する前に同一ボリューム内 rename で退避し、実削除は background に逃がす
HEAVY_DIR_NAMES = {"node_modules", "target", "dist", ".turbo"}
HEAVY_SCAN_DEPTH = 4


def evacuate_heavy_dirs(checkout: str) -> None:
    os.makedirs(TRASH, exist_ok=True)
    moved = False
    for root, dirs, _files in os.walk(checkout):
        depth = os.path.relpath(root, checkout).count(os.sep)
        if depth >= HEAVY_SCAN_DEPTH:
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if d != ".git"]
        for d in list(dirs):
            if d not in HEAVY_DIR_NAMES:
                continue
            src = os.path.join(root, d)
            if os.path.islink(src):
                continue  # 共有 cargo target 等の symlink は checkout ごと消えるだけでよい
            dest = os.path.join(TRASH, f"{d}-{time.time_ns()}")
            try:
                os.rename(src, dest)  # 同一ボリューム内なら即完了
                moved = True
                dirs.remove(d)
            except OSError:
                pass  # 別ボリューム等で rename できなければ従来どおり rm に任せる
    if moved:
        subprocess.Popen(
            ["/bin/sh", "-c", f"rm -rf {TRASH}/*"],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def notify(title: str, body: str) -> None:
    subprocess.run(["herdr", "notification", "show", title, "--body", body], check=False)


def fail(body: str) -> None:
    notify("worktree 削除失敗", body)
    if sys.stdin.isatty():
        try:
            input(f"❌ {body}\nEnter で閉じる ")
        except (EOFError, KeyboardInterrupt):
            pass
    sys.exit(1)


ws = os.environ.get("HERDR_ACTIVE_WORKSPACE_ID")
if not ws:
    fail("HERDR_ACTIVE_WORKSPACE_ID がありません")

# worktree list は workspace とのマッピングが欠けることがあるため、
# worktree 情報を直接持つ workspace list から解決する
out = subprocess.run(["herdr", "workspace", "list"], capture_output=True, text=True)
if out.returncode != 0:
    fail(out.stderr.strip() or "workspace list に失敗")
workspaces = json.loads(out.stdout)["result"]["workspaces"]
w = next((x for x in workspaces if x["workspace_id"] == ws), None)
if w is None:
    fail(f"workspace {ws} が見つかりません")
wt = w.get("worktree")
if not wt or not wt["is_linked_worktree"]:
    fail("この workspace は herdr 管理の worktree ではありません")

repo_root, checkout = wt["repo_root"], wt["checkout_path"]
head = subprocess.run(["git", "-C", checkout, "branch", "--show-current"],
                      capture_output=True, text=True)
branch = head.stdout.strip()
if not branch:
    fail("checkout の branch を特定できません（detached HEAD?）")
try:
    answer = input(f"worktree と branch {branch} を削除しますか？ [Y/n] ")
except (EOFError, KeyboardInterrupt):
    sys.exit(0)
if answer.strip().lower() not in ("", "y", "yes"):
    sys.exit(0)

evacuate_heavy_dirs(checkout)

rm = subprocess.run(["herdr", "worktree", "remove", "--workspace", ws, "--json"],
                    capture_output=True, text=True)
if rm.returncode != 0:
    fail(rm.stderr.strip() or rm.stdout.strip() or "worktree remove に失敗")

br = subprocess.run(["git", "-C", repo_root, "branch", "-d", branch],
                    capture_output=True, text=True)
if br.returncode != 0:
    fail(f"worktree は削除済み。branch {branch} は未マージのため残しました: {br.stderr.strip()}")

notify("worktree 削除", f"checkout と branch {branch} を削除しました")
