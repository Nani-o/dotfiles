# Chart for tput colors
# inspired by https://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/

function tput_colors {
    local REG CMD LBL TPT
    printf "%s%-10s%-10s%-10s%-10s%s\n" "${TXTBOLD}" regular bold underline tput-command-colors "${TXTNORMAL}"

    for i in $(seq 1 7); do
        REG="$(tput setaf "${i}")"
        CMD="\$(tput setaf ${i})"
        printf "%s%-10s%s" "${REG}" "Text" "${TXTNORMAL}"
        printf "%s%s%-10s%s" "${REG}" "${TXTBOLD}" "Text" "${TXTNORMAL}"
        printf "%s%s%s%s" "${REG}" "${TXTUNDERLINE}" "Text" "${TXTNORMAL}"
        printf "%21s\n" "${CMD}"
    done
    for item in "Bold:bold" "Underline:smul" "Reset:sgr0"; do
        LBL="$(echo ${item} | cut -d ':' -f1)"
        TPT="$(echo ${item} | cut -d ':' -f2)"
        printf "%-30s%s\n" "${LBL}" "\$(tput ${TPT})"
    done
}

# ANSI Escape sequence for color stored as variables with tput

if which tput > /dev/null
then
    TXTBLACK=$(tput setaf 0)
    TXTRED=$(tput setaf 1)
    TXTGREEN=$(tput setaf 2)
    TXTLIME_YELLOW=$(tput setaf 190)
    TXTYELLOW=$(tput setaf 3)
    TXTPOWDER_BLUE=$(tput setaf 153)
    TXTBLUE=$(tput setaf 4)
    TXTMAGENTA=$(tput setaf 5)
    TXTCYAN=$(tput setaf 6)
    TXTWHITE=$(tput setaf 7)
    TXTBLINK=$(tput blink)
    TXTREVERSE=$(tput smso)
    TXTBOLD=$(tput bold)
    TXTUNDERLINE=$(tput smul)
    TXTNORMAL=$(tput sgr0)
fi
