# Open file in editor

function f {
    FILES_PATH="."
    if [[ -d "$1" ]]; then
        FILES_PATH="$(cd "$1" && pwd)"
    elif [[ -f "$1" || ! -z "$1" ]]; then
        "$EDITOR" "$1"
        return
    fi

    FILE_TO_OPEN="$(fd "$FILES_PATH" --type f | \
        fzf --reverse --preview 'bat --color=always {}' --preview-window down:85%)"
    [[ -f "$FILE_TO_OPEN" ]] && $EDITOR "$FILE_TO_OPEN"
}

# History search

function h {
    COMMAND=($(history | sed -E 's/^\ *[0-9]*\ *//g' | tac | fzf --layout=reverse))
    clear
    echo "${TXTCYAN}Executing${TXTNORMAL} :" "${COMMAND[@]}"
    eval "${COMMAND[@]}" # ${=COMMAND}  # Zsh word splitting see : http://zsh.sourceforge.net/FAQ/zshfaq03.html
}

# Folder navigation

if which fzf > /dev/null
then
    function remove_deleted_folders_from_d {
        sqlite_db="${HOME}/.local/d.db"
        [[ ! -d "$1" ]] && sqlite3 "${sqlite_db}" "DELETE FROM d WHERE path='${1}';"
    }

    add_folder_for_d() {
        sqlite_db="${HOME}/.local/d.db"
        sqlite3 "${sqlite_db}" "CREATE TABLE IF NOT EXISTS d (path TEXT UNIQUE, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);"
        sqlite3 "${sqlite_db}" "INSERT OR REPLACE INTO d (path) VALUES ('${PWD}');"
        FUNCS=$(functions remove_deleted_folders_from_d);sqlite3 "${sqlite_db}" "select path from d ORDER BY timestamp DESC;" | xargs -I{} zsh -c "eval $FUNCS; remove_deleted_folders_from_d {}"
    }

    typeset -gaU chpwd_functions
    chpwd_functions+=add_folder_for_d

    unalias d 2> /dev/null
    unset -f d 2> /dev/null
    function d {
        RECENT_FOLDERS=$(sqlite3 ~/.local/d.db "select path from d ORDER BY timestamp DESC;" | grep -v "^${PWD}$")
        NB_RECENT_FOLDERS=$(echo "${RECENT_FOLDERS}" | wc -l)
        PREVIEW_WINDOW_SIZE=$(($(tput lines)-NB_RECENT_FOLDERS-4))
        PREVIEW_COMMAND="tree -L 1 -C {}"
        cd "$(echo "${RECENT_FOLDERS}" | \
                fzf --layout=reverse --preview-window down:"${PREVIEW_WINDOW_SIZE}" --preview="${PREVIEW_COMMAND}")" || return
    }
fi

function c {
    FILES_PATH="."
    if [[ -d "$1" ]]; then
        FILES_PATH="$(cd "$1" && pwd)"
    elif [[ -f "$1" || ! -z "$1" ]]; then
        "$EDITOR" "$1"
        return
    fi
    while true
    do
        FILES_TO_DELETE="$(find -L "$FILES_PATH" -mindepth 1 -not -path '*/\.*' | \
                        fzf --reverse -m --preview 'du -Lsh {}' --preview-window up:1%)"
        clear
        [[ ${FILES_TO_DELETE} == "" ]] && break
        echo "You are about to run :"
        echo "$FILES_TO_DELETE" | tr '\n' '\0' | xargs -0 -P 1 -I {} echo rm -rf "{}"
        echo
        echo -n "This will free : "
        echo "$FILES_TO_DELETE" | tr '\n' '\0' | xargs -0 -P 1 du -ch | tail -1 | awk '{print $1}'
        echo -n "Are you sure ? [y/n] : "
        read -r CHOICE
        CHOICE="$(echo $CHOICE | tr 'a-z' 'A-Z')"
        [[ ${CHOICE} == "Y" ]] && echo "$FILES_TO_DELETE" | tr '\n' '\0' | xargs -0 -P 1 -I {} rm -rf "{}"
    done
}
