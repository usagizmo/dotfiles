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

rm = subprocess.run(["herdr", "worktree", "remove", "--workspace", ws, "--json"],
                    capture_output=True, text=True)
if rm.returncode != 0:
    fail(rm.stderr.strip() or rm.stdout.strip() or "worktree remove に失敗")

br = subprocess.run(["git", "-C", repo_root, "branch", "-d", branch],
                    capture_output=True, text=True)
if br.returncode != 0:
    fail(f"worktree は削除済み。branch {branch} は未マージのため残しました: {br.stderr.strip()}")

notify("worktree 削除", f"checkout と branch {branch} を削除しました")
