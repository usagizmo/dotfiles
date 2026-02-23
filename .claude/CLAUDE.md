# dotfiles プロジェクト固有の設定

## コミットメッセージ規約

このプロジェクトでは、スコープごとに固定された gitmoji を使用します。

### 形式

```
{gitmoji} [{scope}] {message}

- {詳細1}
- {詳細2}
```

### スコープと絵文字の対応

| 絵文字 | スコープ | 説明 |
|-------|---------|------|
| 🐟 | `[fish]` | Fish シェル設定 |
| 🐚 | `[zsh]` | Zsh シェル設定 |
| 🤖 | `[claude]` | Claude Code 設定（スキル、ルール、CLAUDE.md 等） |
| 🤖 | `[codex]` | Codex 関連設定 |
| 🐙 | `[copilot]` | GitHub Copilot 設定 |
| 📝 | `[nvim]` | Neovim 設定 |
| 👻 | `[ghostty]` | Ghostty ターミナル設定 |
| 🖥️ | `[tmux]` | tmux 設定 |
| 📁 | `[yazi]` | Yazi ファイルマネージャー設定 |
| 🔧 | `[複数]` | 複数スコープにまたがる設定変更（例: `[fish][zsh]`） |

### 補足ルール

- 複数スコープの場合は 🔧 を使用
- スコープに該当しない全体的な変更は、適切な汎用 gitmoji を使用
- 新機能: ✨、バグ修正: 🐛、削除: 🔥、リファクタリング: ♻️

### コミット例

```
🐟 [fish] claude コマンドの短縮エイリアス c を追加

- `alias c 'claude'` を追加し、より素早く Claude を起動できるように改善
```

```
🔧 [fish][zsh] LM Studio CLI パス設定を追加

- 両シェルで LM Studio の CLI ツールを使用可能に
```

```
🤖 [claude] ボーイスカウトルールの記述を統合し重複を削除

- CLAUDE.md とスキル内の重複した記述を整理
```
