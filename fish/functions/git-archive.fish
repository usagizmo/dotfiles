function git-archive -d "指定コミットから現在までの変更ファイルをzipアーカイブ化" -a commit_id
    # 使用例:
    #   git-archive           # HEAD^ から HEAD までの差分をアーカイブ
    #   git-archive abc1234   # abc1234 から HEAD までの差分をアーカイブ
    #   git-archive HEAD~3    # 3つ前のコミットから HEAD までの差分をアーカイブ

    # 引数がなければ HEAD^ を使用
    set -l base_commit (test -n "$commit_id" && echo $commit_id || echo "HEAD^")

    echo "📦 $base_commit から HEAD までの変更ファイルをアーカイブ化しています..."
    git archive --format=zip --prefix=root/ HEAD (git diff --diff-filter=d --name-only $base_commit HEAD) -o archive.zip
    if test $status -eq 0
        echo "✅ archive.zip を作成しました！"
    else
        echo "❌ アーカイブの作成に失敗しました"
        return 1
    end
end