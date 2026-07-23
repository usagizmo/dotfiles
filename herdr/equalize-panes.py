#!/usr/bin/env python3
"""フォーカス中の herdr tab の pane を等分割にする。

herdr に equalize アクションが無いため、socket API の layout.export で
split 木を取得し、各 split の ratio を同一軸の pane 数で重み付けして
layout.set_split_ratio で設定する（同方向に並ぶ pane が等幅になる）。
"""

import json
import os
import socket

SOCK = os.path.expanduser("~/.config/herdr/herdr.sock")


def call(method: str, params: dict) -> dict:
    s = socket.socket(socket.AF_UNIX)
    s.connect(SOCK)
    s.settimeout(5)
    s.sendall((json.dumps({"id": "equalize", "method": method, "params": params}) + "\n").encode())
    buf = b""
    while not buf.endswith(b"\n"):
        buf += s.recv(65536)
    s.close()
    res = json.loads(buf)
    if "error" in res:
        raise SystemExit(f"herdr api error: {res['error']}")
    return res["result"]


def axis(direction: str) -> str:
    return "h" if direction in ("left", "right") else "v"


def weight(node: dict, along: str) -> int:
    """`along` 軸方向に並ぶ leaf pane 数（軸が変わる subtree は 1 とみなす）"""
    if node["type"] != "split" or axis(node["direction"]) != along:
        return 1
    return weight(node["first"], along) + weight(node["second"], along)


def equalize(node: dict, path: list[bool]) -> None:
    if node["type"] != "split":
        return
    a = axis(node["direction"])
    first, second = weight(node["first"], a), weight(node["second"], a)
    call("layout.set_split_ratio", {"path": path, "ratio": first / (first + second)})
    equalize(node["first"], path + [False])
    equalize(node["second"], path + [True])


root = call("layout.export", {})["layout"]["root"]
equalize(root, [])
