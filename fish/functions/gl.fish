function gl -d "最新の変更を取得し、マージ済みローカルブランチを削除"
    # リモートの最新情報を取得し、削除されたブランチの参照も削除
    git fetch --prune
    or return 1

    # 現在のブランチを fast-forward マージで更新
    git merge --ff-only @{u} $argv
    or return 1

    # マージ済みローカルブランチを削除
    set -l merged_branches (git branch --merged | grep -v '\*' | grep -v -E '^\s*(main|master)\s*$' | string trim)

    if test -n "$merged_branches"
        echo "🗑️  マージ済みブランチを削除します:"
        for branch in $merged_branches
            echo "  - $branch"
            git branch -d $branch
        end
        echo "✅ ローカルブランチのクリーンアップ完了"
    end
end
