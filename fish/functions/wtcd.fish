function wtcd -d "git worktree へ移動"
    argparse h/help -- $argv
    or return 1

    if set -q _flag_help
        echo "使用方法: wtcd [query]"
        echo "現在のリポジトリの worktree へ cd する"
        echo "引数なし: fzf で選ぶ"
        echo "query: ブランチ名またはディレクトリ名（部分一致）"
        return 0
    end

    set -l rows (__wtcd_worktrees)
    or begin
        echo "❌ git リポジトリではありません" >&2
        return 1
    end
    if test (count $rows) -eq 0
        echo "❌ worktree がありません" >&2
        return 1
    end

    set -l query (string join ' ' -- $argv)
    set -l chosen

    if test -z "$query"
        set chosen (__wtcd_pick $rows)
        or return $status
        test -n "$chosen"; or return 0
    else
        set -l matched (__wtcd_filter $query $rows)
        switch (count $matched)
            case 0
                echo "❌ 一致する worktree がありません: $query" >&2
                __wtcd_list $rows >&2
                return 1
            case 1
                set chosen $matched[1]
            case '*'
                set chosen (__wtcd_pick $matched)
                or return $status
                test -n "$chosen"; or return 0
        end
    end

    set -l dest (string split \t -- $chosen)[1]
    cd -- $dest
end

function __wtcd_filter
    set -l query $argv[1]
    set -l rows $argv[2..]
    set -l q (string lower -- $query)
    set -l q_re (string escape --style=regex -- $q)
    set -l exact
    set -l partial

    for row in $rows
        set -l parts (string split \t -- $row)
        set -l path $parts[1]
        set -l branch $parts[2]
        set -l hit_exact 0
        set -l hit_partial 0
        for k in (__wtcd_keys "$path" "$branch")
            set -l kl (string lower -- $k)
            if test "$kl" = "$q"
                set hit_exact 1
            end
            if string match -q -r -- $q_re $kl
                set hit_partial 1
            end
        end
        if test $hit_exact -eq 1
            set -a exact $row
        else if test $hit_partial -eq 1
            set -a partial $row
        end
    end

    if test (count $exact) -gt 0
        printf '%s\n' $exact
        return
    end
    if test (count $partial) -gt 0
        printf '%s\n' $partial
    end
end

function __wtcd_pick
    if not command -v fzf >/dev/null 2>&1
        echo "❌ fzf コマンドが見つかりません" >&2
        return 1
    end

    set -l tab (printf '\t')
    set -l lines
    for row in $argv
        set -l parts (string split \t -- $row)
        set -l path $parts[1]
        set -l branch $parts[2]
        set -l keys (__wtcd_keys "$path" "$branch" | string join ' ')
        set -a lines "$path$tab$keys"
    end

    set -l selected (
        printf '%s\n' $lines \
            | fzf --border --delimiter=$tab --with-nth=2 \
            --preview 'printf "%s\n" {1}; ls -la -- {1}' --select-1 --exit-0
    )
    set -l rc $status
    switch $rc
        case 0
            if test -n "$selected"
                printf '%s\n' $selected
            end
        case 1 130
            return 0
        case '*'
            return $rc
    end
end

function __wtcd_list
    for row in $argv
        set -l parts (string split \t -- $row)
        printf '  %s  %s\n' (__wtcd_label "$parts[2]") "$parts[1]"
    end
end
