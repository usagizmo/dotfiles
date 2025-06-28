function git-tag-push -d "🏷️ タグを作成してoriginにプッシュ" -a tag_name
    # 引数チェック
    if test -z "$tag_name"
        echo "❌ エラー: タグ名を指定してください"
        echo "使用方法: git-tag-push <tag_name>"
        return 1
    end

    # タグの作成
    echo "🏷️  タグを作成します: $tag_name"
    if not git tag "$tag_name"
        echo "❌ タグの作成に失敗しました"
        return 1
    end

    # タグをoriginにpush
    echo "📤 タグをoriginにpushします..."
    if git push origin "$tag_name"
        echo "✅ タグ '$tag_name' を正常にpushしました！"
    else
        echo "❌ タグのpushに失敗しました"
        # ローカルのタグも削除
        git tag -d "$tag_name"
        return 1
    end
end