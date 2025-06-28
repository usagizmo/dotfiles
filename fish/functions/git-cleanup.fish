function git-cleanup -d "現在のブランチを削除してmainブランチを最新に更新"
    # 現在のブランチ名を保存
    set current_branch (git branch --show-current)

    # 現在のブランチがmainの場合はスキップ
    if test "$current_branch" = "main"
        echo "⚠️  現在mainブランチにいます。クリーンアップの必要はありません。"
        return 0
    end

    # main ブランチに切り替え
    echo "🔄 mainブランチに切り替えます..."
    git checkout main

    # 最新の変更を取得
    echo "⬇️ 最新の変更を取得しています..."
    git pull

    # リモートで削除されたブランチの参照を削除
    echo "🧹 リモートブランチの整理中..."
    git fetch --prune

    # 保存していたブランチを削除（mainの場合はスキップ）
    if test "$current_branch" != "main"
        echo "🗑️ ブランチを削除します: $current_branch"
        git branch -D $current_branch
    end

    echo "✅ クリーンアップ完了！"
end
