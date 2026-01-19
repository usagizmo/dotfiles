function git-archive -d "指定コミットの変更ファイルをzipアーカイブ化" -a commit_id
    # 使用例:
    #   git-archive           # HEAD の差分をアーカイブ
    #   git-archive abc1234   # 指定コミットの差分をアーカイブ
    #   git-archive HEAD~3    # 3つ前のコミットの差分をアーカイブ

    # 引数がなければ HEAD を使用
    set -l target_commit (test -n "$commit_id" && echo $commit_id || echo "HEAD")

    echo "📦 $target_commit の変更ファイルをアーカイブ化しています..."
    git archive --format=zip --prefix=root/ $target_commit (git diff --diff-filter=d --name-only $target_commit^ $target_commit) -o archive.zip
    if test $status -eq 0
        echo "✅ archive.zip を作成しました！"
    else
        echo "❌ アーカイブの作成に失敗しました"
        return 1
    end
end