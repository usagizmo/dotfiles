function fzf_ghq -d "ghqで管理しているリポジトリを選択してディレクトリ移動"
    if not command -v ghq >/dev/null 2>&1
        echo "❌ ghq コマンドが見つかりません"
        return 1
    end

    if not command -v fzf >/dev/null 2>&1
        echo "❌ fzf コマンドが見つかりません"
        return 1
    end

    set selected_repo (ghq list | fzf --border --preview "ls -la (ghq root)/{}")

    if test -n "$selected_repo"
        set repo_path (ghq root)/$selected_repo
        cd "$repo_path"
        commandline -f repaint
    end
end