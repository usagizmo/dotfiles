function drop -d "Git差分をDropboxで共有するためのワークフロー自動化"
    # -h オプションの処理
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        _drop_help
        return 0
    end

    # サブコマンド
    set -l subcmd $argv[1]
    set -e argv[1]

    switch $subcmd
        case init
            _drop_init
        case zip
            _drop_zip $argv
        case mv
            _drop_mv
        case open
            _drop_open $argv
        case '*'
            # サブコマンドなしの場合は open と同じ動作
            _drop_open $subcmd $argv
    end
end

function _drop_help
    echo "使用方法: drop [サブコマンド] [オプション]"
    echo ""
    echo "サブコマンドなしで実行すると Dropbox フォルダを開きます"
    echo ""
    echo "サブコマンド:"
    echo "  init              設定ファイル(drop.config.json)を作成"
    echo "  zip <対象名>      指定した対象のzipファイルを作成"
    echo "  mv                zipファイルをDropboxに移動してブラウザを開く"
    echo "  open              Dropboxフォルダを開く"
    echo ""
    echo "オプション:"
    echo "  -h, --help             ヘルプを表示"
    echo "  -w, --web              Dropbox Webを開く (drop / drop open)"
    echo "  zip -c, --commit <id>  指定コミットからの差分を使用"
end

function _drop_init
    set -l config_file "drop.config.json"

    if test -f $config_file
        echo "⚠️  $config_file は既に存在します"
        return 1
    end

    set -l dir_name (basename (pwd))

    echo "{
  \"prefix\": \"$dir_name\",
  \"dropboxPath\": \"/Users/USERNAME/Library/CloudStorage/Dropbox/.../send\",
  \"password\": \"pass\",
  \"targets\": {
    \"pages\": \"apps/pages/public\",
    \"web\": \"apps/web/public\"
  }
}" >$config_file

    echo "✅ $config_file を作成しました"

    # .gitignore に追加
    if test -f .gitignore
        if not grep -q "^drop.config.json\$" .gitignore
            echo "drop.config.json" >>.gitignore
            echo "✅ .gitignore に drop.config.json を追加しました"
        end
    else
        echo "drop.config.json" >.gitignore
        echo "✅ .gitignore を作成し、drop.config.json を追加しました"
    end

    echo "📝 設定を編集してください"
end

function _drop_zip
    # オプション解析
    argparse 'c/commit=' -- $argv
    or return 1

    set -l target_name $argv[1]

    if test -z "$target_name"
        echo "❌ 対象名を指定してください"
        echo "使用方法: drop zip <対象名> [-c|--commit <id>]"
        return 1
    end

    # 設定ファイルの確認
    set -l config_file "drop.config.json"
    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        echo "💡 'drop init' で設定ファイルを作成してください"
        return 1
    end

    # 設定の読み込み
    set -l prefix (jq -r '.prefix' $config_file)
    set -l target_path (jq -r ".targets[\"$target_name\"]" $config_file)

    if test "$target_path" = null
        echo "❌ 対象 '$target_name' が見つかりません"
        echo "📝 drop.config.json の targets に追加してください"
        return 1
    end

    # コミットIDの決定
    set -l base_commit (test -n "$_flag_commit" && echo $_flag_commit || echo "HEAD^")

    echo "📦 $base_commit から HEAD までの差分をアーカイブ化しています..."

    # 一時ディレクトリの作成
    set -l tmp_dir (mktemp -d)
    set -l archive_file "archive.zip"

    # git-archive でアーカイブ作成
    set -l diff_files (git diff --diff-filter=d --name-only $base_commit HEAD 2>/dev/null)
    if test $status -ne 0
        echo "❌ git diff の実行に失敗しました"
        rm -rf $tmp_dir
        return 1
    end

    if test -z "$diff_files"
        echo "❌ 差分ファイルがありません"
        rm -rf $tmp_dir
        return 1
    end

    git archive --format=zip --prefix=root/ HEAD $diff_files -o $archive_file
    if test $status -ne 0
        echo "❌ アーカイブの作成に失敗しました"
        rm -rf $tmp_dir
        return 1
    end

    # 一時ディレクトリに解凍
    unzip -q $archive_file -d $tmp_dir
    if test $status -ne 0
        echo "❌ 解凍に失敗しました"
        rm -f $archive_file
        rm -rf $tmp_dir
        return 1
    end

    # 対象ディレクトリの確認
    set -l extract_path "$tmp_dir/root/$target_path"
    if not test -d $extract_path
        echo "❌ 差分に '$target_path' が含まれていません"
        rm -f $archive_file
        rm -rf $tmp_dir
        return 1
    end

    echo "📂 $target_path を抽出しています..."

    # 出力ファイル名の生成
    set -l date_str (date "+%Y年%m月%d日")
    set -l output_file "$prefix"_"$target_name"_"$date_str"_diff.zip

    # 対象ディレクトリのみをzip化
    pushd $extract_path >/dev/null
    zip -rq $output_file .
    popd >/dev/null

    # カレントディレクトリに移動
    mv "$extract_path/$output_file" .

    echo "✅ $output_file を作成しました"
    echo ""
    tree $extract_path

    # クリーンアップ
    rm -f $archive_file
    rm -rf $tmp_dir
end

function _drop_mv
    # 設定ファイルの確認
    set -l config_file "drop.config.json"
    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        return 1
    end

    # 設定の読み込み
    set -l dropbox_path (jq -r '.dropboxPath' $config_file)
    set -l password (jq -r '.password' $config_file)

    # ~/ を展開
    set dropbox_path (string replace '~' $HOME $dropbox_path)

    # Dropboxパスの確認
    if not test -d $dropbox_path
        echo "❌ Dropboxフォルダが見つかりません: $dropbox_path"
        return 1
    end

    # *_diff.zip ファイルの検索
    set -l zip_files *_diff.zip
    if test -z "$zip_files" -o ! -f "$zip_files[1]"
        echo "❌ *_diff.zip ファイルが見つかりません"
        echo "💡 'drop zip <対象名>' でzipファイルを作成してください"
        return 1
    end

    # 各zipファイルを移動
    for zip_file in $zip_files
        mv $zip_file $dropbox_path/
        echo "📤 $zip_file を Dropbox に移動しました"
    end

    # パスワードをクリップボードにコピー
    if test -n "$password" -a "$password" != null
        echo -n $password | pbcopy
        echo "📋 パスワード: $password (クリップボードにコピー済み)"
    end

    # Dropbox Web を開く
    set -l web_path (echo $dropbox_path | sed 's|.*/Dropbox[^/]*/||')
    echo "🔗 Dropbox を開いています..."
    open "https://www.dropbox.com/home/$web_path"
end

function _drop_open
    # オプション解析
    argparse 'w/web' -- $argv
    or return 1

    # 設定ファイルの確認
    set -l config_file "drop.config.json"
    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        return 1
    end

    # 設定の読み込み
    set -l dropbox_path (jq -r '.dropboxPath' $config_file)

    # ~/ を展開
    set dropbox_path (string replace '~' $HOME $dropbox_path)

    if set -q _flag_web
        # Dropbox Web を開く
        set -l web_path (echo $dropbox_path | sed 's|.*/Dropbox[^/]*/||')
        echo "🔗 Dropbox Web を開いています..."
        open "https://www.dropbox.com/home/$web_path"
    else
        # Dropboxパスの確認
        if not test -d $dropbox_path
            echo "❌ Dropboxフォルダが見つかりません: $dropbox_path"
            return 1
        end

        echo "📂 Dropbox フォルダを開いています..."
        open $dropbox_path
    end
end
