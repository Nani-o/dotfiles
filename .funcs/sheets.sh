function sheets {
  case $1 in
  help)
    __sheets_help
    ;;
  new)
    __sheets_new
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
    width=$(echo $(($COLUMNS*0.7-5)) | cut -d "." -f 1)
    rich -w $width ~/.cheatsheets/"$file".md --force-terminal
}

function __sheets {
    sheets_list=$(fd . ~/.cheatsheets -e md | sed 's/.*.cheatsheets\///g' | sed 's@_@ | @' | column -t | sed 's/_/ /g' | sed 's/.md$//g')
    sheet_file=$(echo "$sheets_list" | fzf --preview "source ~/.funcs/sheets.sh;__preview_sheets_from_title {}" \
                              --preview-window right,70% --ansi --no-scrollbar)

    if [[ ! -z "$sheet_file" ]]
    then
        "$EDITOR" $(__file_from_title "$sheet_file")
    fi
}
