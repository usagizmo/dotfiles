function gw -d "git worktree の操作を簡略化"
    set -l subcmd $argv[1]

    switch $subcmd
        case '' list ls
            git worktree list

        case add
            # パラメータチェック
            if test (count $argv) -lt 2
                echo "❌ パラメータが必要です"
                echo "使い方: gw add <feature-name>"
                return 1
            end

            set -l feature_name $argv[2]
            set -l branch_name "feat/$feature_name"

            # リポジトリのルートを取得
            set -l current_path (pwd)
            set -l repo_root $current_path

            # .worktree/{name} 内にいる場合
            if string match -q "*/.worktree/*" $current_path
                set repo_root (string replace -r "/.worktree/.*" "" $current_path)
            # .worktree ディレクトリ内にいる場合
            else if string match -q "*/.worktree" $current_path
                set repo_root (dirname $current_path)
            end

            # worktree を作成
            echo "🌳 worktree を作成: $branch_name"
            git worktree add -b $branch_name $repo_root/.worktree/$feature_name

            if test $status -eq 0
                echo "📂 ディレクトリに移動: $repo_root/.worktree/$feature_name"
                cd $repo_root/.worktree/$feature_name

                # 初期化スクリプトの実行
                set -l init_script $repo_root/.gw-init
                if test -f $init_script
                    echo ""
                    echo "📜 初期化スクリプトを検出: .gw-init"
                    echo "────────────────────────────────"
                    cat $init_script
                    echo "────────────────────────────────"
                    echo ""
                    read -P "▶ 実行しますか? [Y/n] " confirm
                    if test -z "$confirm" -o "$confirm" = "Y" -o "$confirm" = "y"
                        echo "🚀 初期化スクリプトを実行中..."
                        echo ""
                        bash $init_script
                        set -l exit_code $status
                        echo ""
                        if test $exit_code -eq 0
                            echo "✅ 初期化完了"
                        else
                            echo "⚠️ 初期化スクリプトが失敗しました (終了コード: $exit_code)"
                        end
                    else
                        echo "⏭️ スキップしました"
                    end
                end
            end

        case remove rm
            # 現在の worktree を削除
            set -l current_path (pwd)
            if not string match -q "*/.worktree/*" $current_path
                echo "❌ worktree 内ではありません"
                return 1
            end

            set -l feature_name (basename $current_path)
            set -l branch_name "feat/$feature_name"
            set -l repo_root (string replace -r "/.worktree/.*" "" $current_path)
            set -l worktree_path $repo_root/.worktree/$feature_name

            echo "🗑️ worktree を削除: $branch_name"
            cd $repo_root
            git worktree remove .worktree/$feature_name
            git branch -D $branch_name

            # ディレクトリが残っている場合は削除
            if test -d $worktree_path
                echo "📁 ディレクトリを削除: $worktree_path"
                rm -rf $worktree_path
            end

        case prune
            echo "🧹 不要な worktree 情報を削除"
            git worktree prune -v

        case .
            # main ディレクトリに移動
            set -l current_path (pwd)

            # .worktree/{name} 内にいる場合
            if string match -q "*/.worktree/*" $current_path
                set -l repo_root (string replace -r "/.worktree/.*" "" $current_path)
                cd $repo_root
                return
            end

            # .worktree ディレクトリ内にいる場合
            if string match -q "*/.worktree" $current_path
                cd (dirname $current_path)
                return
            end

            # すでに main にいる場合
            echo "📍 すでに main ディレクトリにいます"

        case -h --help
            echo "使い方: gw [subcommand]"
            echo ""
            echo "サブコマンド:"
            echo "  (なし)                worktree の一覧を表示"
            echo "  add <feature-name>    新しい worktree を作成して移動 (ブランチ名: feat/<feature-name>)"
            echo "                        (.gw-init があれば実行を確認)"
            echo "  remove, rm            現在の worktree を削除"
            echo "  prune                 不要な worktree 情報を削除"
            echo "  .                     main ディレクトリに移動"

        case '*'
            echo "❌ 不明なサブコマンド: $subcmd"
            echo "使い方: gw -h"
            return 1
    end
end
