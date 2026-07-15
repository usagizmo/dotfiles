function drop -d "pwd に紐づくフォルダを Finder で開く"
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        _drop_help
        return 0
    end

    switch "$argv[1]"
        case ''
            _drop_open
        case link
            _drop_link $argv[2]
        case unlink
            _drop_unlink
        case list
            _drop_list
        case config
            _drop_config
        case '*'
            echo "❌ 不明なサブコマンド: $argv[1]"
            _drop_help
            return 1
    end
end

function _drop_config_file
    echo ~/.config/drop/config.json
end

function _drop_help
    echo "使用方法: drop [サブコマンド]"
    echo ""
    echo "pwd に紐づけたフォルダを Finder で開く"
    echo "設定: "(_drop_config_file)" （{\"pathA\": \"pathB\", ...}）"
    echo ""
    echo "サブコマンド:"
    echo "  (なし)        pwd に紐づくフォルダを開く"
    echo "  link <path>   pwd に <path> を紐づける（作成・更新）"
    echo "  unlink        pwd の紐づけを削除"
    echo "  list          紐づけ一覧を表示"
    echo "  config        設定ファイルを Finder で表示"
end

function _drop_open
    set -l config_file (_drop_config_file)
    set -l cwd (pwd)

    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        echo "💡 'drop link <path>' で紐づけを作成してください"
        return 1
    end

    set -l target (jq -r --arg cwd $cwd '.[$cwd] // empty' $config_file)
    if test -z "$target"
        echo "❌ $cwd の紐づけがありません"
        echo "💡 'drop link <path>' で紐づけを作成してください"
        return 1
    end

    if not test -d $target
        echo "❌ フォルダが見つかりません: $target"
        return 1
    end

    echo "📂 $target を開いています..."
    open $target
end

function _drop_link
    set -l target $argv[1]
    if test -z "$target"
        echo "❌ 紐づけるパスを指定してください"
        echo "使用方法: drop link <path>"
        return 1
    end

    # 絶対パスに正規化（存在チェックを兼ねる）
    set target (realpath $target 2>/dev/null)
    if test -z "$target" -o ! -d "$target"
        echo "❌ フォルダが見つかりません: $argv[1]"
        return 1
    end

    set -l config_file (_drop_config_file)
    set -l cwd (pwd)
    mkdir -p (dirname $config_file)
    test -f $config_file; or echo '{}' >$config_file

    set -l tmp (mktemp)
    jq --arg cwd $cwd --arg target $target '.[$cwd] = $target' $config_file >$tmp
    and mv $tmp $config_file
    or begin
        rm -f $tmp
        echo "❌ $config_file の更新に失敗しました"
        return 1
    end

    echo "✅ 紐づけました: $cwd -> $target"
end

function _drop_unlink
    set -l config_file (_drop_config_file)
    set -l cwd (pwd)

    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        return 1
    end

    set -l target (jq -r --arg cwd $cwd '.[$cwd] // empty' $config_file)
    if test -z "$target"
        echo "❌ $cwd の紐づけがありません"
        return 1
    end

    set -l tmp (mktemp)
    jq --arg cwd $cwd 'del(.[$cwd])' $config_file >$tmp
    and mv $tmp $config_file
    or begin
        rm -f $tmp
        echo "❌ $config_file の更新に失敗しました"
        return 1
    end

    echo "🗑️ 紐づけを削除しました: $cwd -> $target"
end

function _drop_config
    set -l config_file (_drop_config_file)

    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        echo "💡 'drop link <path>' で紐づけを作成してください"
        return 1
    end

    echo "📂 $config_file を Finder で表示しています..."
    open -R $config_file
end

function _drop_list
    set -l config_file (_drop_config_file)

    if not test -f $config_file
        echo "❌ $config_file が見つかりません"
        echo "💡 'drop link <path>' で紐づけを作成してください"
        return 1
    end

    set -l entries (jq -r 'to_entries[] | "\(.key) -> \(.value)"' $config_file)
    if test -z "$entries"
        echo "（紐づけはありません）"
        return 0
    end
    printf '%s\n' $entries
end
