function fzf_history -d "コマンド履歴をfzfで選択（入力中のテキストを維持）"
    if not command -v fzf >/dev/null 2>&1
        echo "❌ fzf コマンドが見つかりません"
        return 1
    end

    # 現在のコマンドラインのテキストを取得
    set current_buffer (commandline)

    # 履歴から選択（重複を除去し、現在の入力をクエリとして使用）
    set selected_history (history | fzf --border --query="$current_buffer" --select-1 --exit-0)

    if test -n "$selected_history"
        # 選択された履歴をコマンドラインに設定
        commandline -r "$selected_history"
    end
end