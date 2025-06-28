function git-archive -d "最新コミットの変更ファイルをzipアーカイブ化"
    echo "📦 最新コミットの変更ファイルをアーカイブ化しています..."
    git archive --format=zip --prefix=root/ HEAD (git diff --diff-filter=d --name-only HEAD^ HEAD) -o archive.zip
    if test $status -eq 0
        echo "✅ archive.zip を作成しました！"
    else
        echo "❌ アーカイブの作成に失敗しました"
        return 1
    end
end