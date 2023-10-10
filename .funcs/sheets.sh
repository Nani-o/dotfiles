function sheets {
  case $1 in
  help)
    __sheets_help
    ;;
  new)
    __sheets_new
    ;;
  local_new)
    __sheets_local_new
    ;;
  "")
    __sheets
    ;;
  *)
    echo -e "sheets: '$1' is not a valid subcommand.\n"
    __sheets_help
    ;;
  esac
}

alias s=sheets

function __sheets_new {
    echo -n "How do you want to name these file : "
    read FILE
    if [[ -f ~/.cheatsheets/"$FILE".md ]]
    then
        echo "Already exists"
    else
        [[ "$FILE" == *.md ]] \
          && "$EDITOR" ~/.dotfiles/.cheatsheets/"${FILE}" \
          || "$EDITOR" ~/.dotfiles/.cheatsheets/"${FILE}".md
        dot link
    fi
}

function __sheets_local_new {
    echo -n "How do you want to name these local file : "
    read FILE
    if [[ -f ~/.cheatsheets/"$FILE".md ]]
    then
        echo "Already exists"
    else
        [[ "$FILE" == *.md ]] \
          && "$EDITOR" ~/.cheatsheets/"${FILE}" \
          || "$EDITOR" ~/.cheatsheets/"${FILE}".md
    fi
}

function __sheets_help {
    echo -e "usage: sheets [subcommand]\n
Theses are sheets subcommands:
  help:     show this help message"
}

function __file_from_title {
    file=$(echo "$1" | sed 's@\ *|\ *@_@' | sed 's/\ /_/g')
    echo ~/.cheatsheets/"$file".md
}

function __preview_sheets_from_title {
    file=$(echo "$1" | sed 's@\ *|\ *@_@' | sed 's/\ /_/g')
    [[ "$COLUMNS" -gt $(($LINES*2)) ]] && width=$(echo $(($COLUMNS*0.7-5)) | cut -d "." -f 1)
    [[ "$COLUMNS" -le $((LINES*2)) ]] && width=$(echo $(($COLUMNS-5)) | cut -d "." -f 1)
    rich -w $width ~/.cheatsheets/"$file".md --force-terminal
}

function __sheets {
    [[ "$COLUMNS" -gt $(($LINES*2)) ]] && preview_windows=right,70%
    [[ "$COLUMNS" -le $((LINES*2)) ]] && preview_windows=down,90%
    sheets_list=$(fd . ~/.cheatsheets -e md | sed 's/.*.cheatsheets\///g' | sed 's@_@ | @' | column -t | sed 's/_/ /g' | sed 's/.md$//g')
    sheet_file=$(echo "$sheets_list" | fzf --layout=reverse --preview "source ~/.funcs/sheets.sh;__preview_sheets_from_title {}" \
                              --preview-window $preview_windows --ansi --no-scrollbar)

    if [[ ! -z "$sheet_file" ]]
    then
        "$EDITOR" $(__file_from_title "$sheet_file")
    fi
}
