#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Generate Slug
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📋
# @raycast.packageName Utils

# Documentation:
# @raycast.description friendly slug（adjective-noun）を生成してクリップボードへコピー
# @raycast.author usagizmo

# HUD には @raycast.icon が付くため、genslug 出力先頭の 📋 は落とす
/usr/local/bin/fish -c genslug | sed 's/^📋 //'
