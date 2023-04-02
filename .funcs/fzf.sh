# Open file in editor

function s {
    FILES_PATH="."
    if [[ -d "$1" ]]; then
        FILES_PATH="$(cd "$1" && pwd)"
    elif [[ -f "$1" || ! -z "$1" ]]; then
        "$EDITOR" "$1"
        return
    fi

    FILE_TO_OPEN="$(find "$FILES_PATH" -type f -not -path '*/\.*' | \
        fzf --reverse --preview 'bat --color=always {}' --preview-window down:85%)"
    [[ -f "$FILE_TO_OPEN" ]] && $EDITOR "$FILE_TO_OPEN"
}

# History search

function h {
    COMMAND=($(history | sed -E 's/^\ *[0-9]*\ *([0-9]*\/){2}[0-9]{4}\ [0-9]{2}:[0-9]{2}\ *//g' | tac | fzf --layout=reverse))
    clear
    echo "${TXTCYAN}Executing${TXTNORMAL} :" "${COMMAND[@]}"
    eval "${COMMAND[@]}" # ${=COMMAND}  # Zsh word splitting see : http://zsh.sourceforge.net/FAQ/zshfaq03.html
}

# Folder navigation

if which fzf > /dev/null
then
    unalias d 2>/dev/null
    function d {
        RECENT_FOLDERS=$(dirs -v | sed '1d')
        NB_RECENT_FOLDERS=$(echo "${RECENT_FOLDERS}" | wc -l)
        PREVIEW_WINDOW_SIZE=$(($(tput lines)-NB_RECENT_FOLDERS-4))
        PREVIEW_COMMAND="tree -L 1 -C {}"
        cd "$(echo "${RECENT_FOLDERS}" | \
                sed 's/[0-9]*[[:space:]]//' | \
                xargs -L 1 -I {} -P 1 bash -c 'echo {}' | \
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
        echo "$FILES_TO_DELETE" | tr '\n' '\0' | xargs -0 -L 1 -P 1 -I {} echo rm -rf "{}"
        echo
        echo -n "This will free : "
        echo "$FILES_TO_DELETE" | tr '\n' '\0' | xargs -0 -P 1 du -ch | tail -1 | awk '{print $1}'
        echo -n "Are you sure ? [y/n] : "
        read -r CHOICE
        CHOICE="$(echo $CHOICE | tr 'a-z' 'A-Z')"
        [[ ${CHOICE} == "Y" ]] && echo "$FILES_TO_DELETE" | tr '\n' '\0' | xargs -0 -L 1 -P 1 -I {} rm -rf "{}"
    done
}