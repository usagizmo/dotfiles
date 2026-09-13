function __wtcd_worktrees -d "現在のリポジトリの worktree を path と branch で出す"
    command git rev-parse --git-dir >/dev/null 2>&1
    or return 1

    set -l path
    set -l branch
    set -l skip 0

    for line in (command git worktree list --porcelain -z | string split0)
        if test -z "$line"
            __wtcd_emit "$path" "$branch" $skip
            set path
            set branch
            set skip 0
            continue
        end

        switch $line
            case 'worktree *'
                if string match -q -r '[\t\n]' -- $line
                    set -l bad (string replace -r '^worktree ' '' -- $line | string collect --no-trim-newlines)
                    echo "❌ worktree パスに tab または改行が含まれます: $bad" >&2
                    set skip 1
                else
                    set path (string replace -r '^worktree ' '' -- $line)
                end
            case 'branch *'
                set -l ref (string replace -r '^branch ' '' -- $line)
                set branch (string replace -r '^refs/heads/' '' -- $ref)
            case detached
                set branch
            case bare 'prunable' 'prunable *'
                set skip 1
        end
    end

    __wtcd_emit "$path" "$branch" $skip
end

function __wtcd_emit -a path branch skip
    if test -z "$path"; or test "$skip" -ne 0
        return
    end
    printf '%s\t%s\n' "$path" "$branch"
end

function __wtcd_keys -a path branch
    set -l keys
    set -l base (path basename -- "$path")
    if test -n "$branch"
        set -a keys "$branch"
    end
    if not contains -- "$base" $keys
        set -a keys "$base"
    end
    printf '%s\n' $keys
end

function __wtcd_label -a branch
    if test -n "$branch"
        printf '%s\n' $branch
    else
        printf '%s\n' '(detached)'
    end
end
