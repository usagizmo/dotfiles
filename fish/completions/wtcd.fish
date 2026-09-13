function __wtcd_complete
    for row in (__wtcd_worktrees 2>/dev/null)
        set -l parts (string split \t -- $row)
        set -l path $parts[1]
        set -l branch $parts[2]
        for k in (__wtcd_keys "$path" "$branch")
            printf '%s\t%s\n' "$k" "$path"
        end
    end
end

complete -c wtcd -s h -l help -d "使い方を表示"
complete -c wtcd -f -a '(__wtcd_complete)'
