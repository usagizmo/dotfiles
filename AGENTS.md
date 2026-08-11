# dotfiles プロジェクト固有の設定

## この repo は public

**private な案件の repo 名・Issue / PR 番号・社内固有の文言を、tracked ファイルにも commit message にも書かない。** 由来を残したいときは、何を直したかだけを書く。**リンクの曖昧さを完全修飾で解こうとしない** —— `#123` が自分の repo を指してしまうからと `org/private-repo#123` へ直すと、曖昧さの代わりに repo 名が公開される。

## agentfiles との関係

**agent 共通 instructions / skills と harness overlay は agentfiles（兄弟 repo）が持つ。**この repo は shell / editor / terminal の設定と、**両 repo が使う配線 primitive** を持つ。

**`lib/links.sh` は dotfiles 専用ではない。**agentfiles が `lib/bootstrap.sh` から自分の `REPO_DIR` を渡して同じ実装を使う。**ここを変えると agentfiles の配線にも効く** —— 関数を消す・引数を変えるときは向こうの `lib/inventory.sh` も見る。

**参照方向は agentfiles → dotfiles の一方通行。**この repo は agentfiles を知らない（`lib/inventory.sh` に agent の行を置かない）。

**新しいマシンでは dotfiles → agentfiles の順に `./init.sh` を実行する** —— agentfiles は bun / mise をこの repo から供給される。

## コミットメッセージ規約

スコープごとに固定の gitmoji を使う。

### 形式

```
{gitmoji} [{scope}] {message}

- {詳細1}
- {詳細2}
```

### スコープと絵文字の対応

| 絵文字 | スコープ       | 説明                                               |
| ------ | -------------- | ---------------------------------------------------- |
| 🐟     | `[fish]`       | Fish シェル設定                                    |
| 🐚     | `[zsh]`        | Zsh シェル設定                                     |
| 📝     | `[nvim]`       | Neovim 設定                                        |
| 👻     | `[ghostty]`    | Ghostty ターミナル設定                             |
| 🐏     | `[herdr]`      | `herdr/` / `~/.config/herdr` 配下の herdr 設定     |
| 📁     | `[yazi]`       | Yazi ファイルマネージャー設定                      |
| 🔨     | `[mise]`       | mise ランタイムバージョン管理設定                  |
| 🖥️     | `[cursor-app]` | `cursor-app` 配下の Cursor IDE 設定                |
| 🔧     | `[複数]`       | 複数スコープにまたがる設定変更（例: `[fish][zsh]`） |

スコープに該当しない全体的な変更は、汎用 gitmoji を使う（新機能: ✨、バグ修正: 🐛、削除: 🔥、リファクタリング: ♻️）。

### コミット例

```
🐟 [fish] claude コマンドの短縮 abbreviation c を追加

- `abbr -a c claude` を追加し、より素早く Claude を起動できるように改善
```

## 配置方針

- `./AGENTS.md` はこの repo 自体の instructions とし、`./.claude/CLAUDE.md` は Claude 互換入口として `../AGENTS.md` へ symlink する
- **tracked ファイルに絶対 home パス（`/Users/...` `/home/...`）を書かない。**`$HOME` / `~` を使う（別環境で壊れる）。`doctor.sh` が repo 全体の tracked ファイルを検査する。symlink 先に使う絶対パスは `$REPO_DIR` 展開であって、リテラルの絶対パスではない

### symlink の貼り方

| パターン                           | 対象                             | 例                                                                                |
| ---------------------------------- | -------------------------------- | --------------------------------------------------------------------------------- |
| 単一ファイル                       | instructions / hooks / 設定 1 枚 | `mise/config.toml` → `~/.config/mise/config.toml`                                 |
| ディレクトリ丸ごと                 | union 不要な SSOT 投影           | `ghostty` → `~/.config/ghostty`                                                   |
| 実 dir + 項目ごと symlink（union） | skills / agents 等のコレクション | `~/.claude/skills/<name>` ← `agents/skills` + `harnesses/claude/skills`（後勝ち） |

### 配線の SSOT（スケール用）

| パス               | 役割                                                                                     |
| ------------------ | ------------------------------------------------------------------------------------------ |
| `lib/inventory.sh` | **この repo が何を配線するかの唯一の正**。symlink の追加はここだけ                       |
| `lib/links.sh`     | apply / check の primitive と `inv_*` の実装（**agentfiles も source する**）            |
| `./init.sh`        | `run_inventory apply` + パッケージ類のインストール副作用                                 |
| `./up.sh`          | 外部依存（mise tools / yazi plugins）の更新                                              |
| `./doctor.sh`      | `run_inventory check` + tracked ファイルの絶対 home パス検査（read-only。修復は init）   |

新しい symlink を足す手順:

1. `lib/inventory.sh` の `inventory_define` に 1 ブロック追加（`inv_home` / `inv_symlink` / `inv_seed` 等）
2. 上の「スコープと絵文字の対応」に行を追加する
3. `./init.sh` で配線
4. `./doctor.sh` で検査

外部コマンド実行のルール（インストール・更新の副作用）:

- パッケージ / プラグインのインストールは `init.sh` の `install_step "<助詞まで含む文節>" <cmd...>` で実行する（例: `install_step "tpm を" git clone ...`）。成否を握りつぶさず、失敗は件数を集計して summary で非ゼロ終了する
- **ツール欠落の扱いは、欠いたまま完走したときにそのスクリプトの主目的が達成できるかで決まる**。達成できるならスキップして ⚠️ に留め、できないなら失敗に数える（`init.sh` は配線が主目的でインストールは全て付随物なのでスキップ、agentfiles の `up.sh` は skills 更新が主目的なので `bunx` 欠落は失敗）
- **更新の対象そのものが入っていない場合はスキップ**（生成元が無いので更新できないが、既にあるものを壊しもしない）。道具の欠落と区別する — `up.sh` の `mise` は対象なのでスキップ、agentfiles の `bunx` は道具なので失敗
- 実行を試みて失敗した場合は、上によらず数える
- **生成物を直接リダイレクトで上書きしない。**`>` はコマンド起動の前にファイルを 0 バイトへ切り詰めるので、生成に失敗すると既存の成果物が消える。temp へ出し、成功かつ非空を確かめてから `mv` する

コレクション配線のルール:

- **source 列は優先度低→高**。後から渡した source が同名を上書きする
- 存在しない source dir はスキップする（実体ができてから作る）
- symlink は **絶対パス**（`$REPO_DIR/...`）

配布先に既に何かある場合の扱いは、経路で違う:

| 配布先の状態            | 単一ファイル（`inv_symlink`）                                                | コレクション項目（`inv_collection` / `inv_harness_skills`） |
| ----------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------- |
| repo 配下を指す symlink | 付け替える                                                                   | 付け替える                                                  |
| repo 外を指す symlink   | ⚠️ 触らない                                                                  | 付け替える                                                  |
| 実ファイル              | 内容を repo へ取り込んでから symlink 化（差分は git で確認・discard できる） | ⚠️ 拒否                                                     |
| 実ディレクトリ          | ⚠️ 触らない                                                                  | ⚠️ 触らない                                                 |

- **⚠️ は必ず出し、件数を集計して非ゼロ終了する**（黙殺しない）。`ln` の失敗も同じ。実ディレクトリは自動削除しない
- prune で消すのは **repo 配下を指す管理下 symlink のうち、配布対象に無いもの・壊れたもの**だけ。repo 外を指す link・実ファイル・実ディレクトリ（vendor の `.system` や Grok bundled skills 等）は触らない
- doctor は実ファイル / 実ディレクトリを ❌ にする（read-only。修復は `init.sh`）
