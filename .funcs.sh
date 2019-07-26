# A collection of shell functions

# Event then action

function git_pull_then_playbook {
  clear
  while true
  do
    pull=$(git -C "${1}" pull)
    echo "${pull}" | grep -q 'Already up-to-date'
    if [[ "$?" == 1 ]]; then
      clear
      ansible-playbook "${2}"
    fi
  done
}

# History search

function h {
    COMMAND=$(history | sed -E 's/^\ *[0-9]*\ *([0-9]*\/){2}[0-9]{4}\ [0-9]{2}:[0-9]{2}\ *//g' | tac | fzf --layout=reverse)
    # shellcheck disable=SC2153
    ${=COMMAND}  # Zsh word splitting see : http://zsh.sourceforge.net/FAQ/zshfaq03.html
}

# Folder navigation

if which fzf > /dev/null
then
    unalias d 2>/dev/null
    function d {
        RECENT_FOLDERS=$(dirs -v)
        NB_RECENT_FOLDERS=$(echo "${RECENT_FOLDERS}" | wc -l)
        PREVIEW_WINDOW_SIZE=$(($(tput lines)-NB_RECENT_FOLDERS-4))
        PREVIEW_COMMAND="tree -L 1 -C {}"
        cd "$(echo "${RECENT_FOLDERS}" | \
                sed 's/[0-9]*[[:space:]]//' | \
                xargs -L 1 -I {} -P 1 bash -c 'echo {}' | \
                fzf --layout=reverse --preview-window down:"${PREVIEW_WINDOW_SIZE}" --preview="${PREVIEW_COMMAND}")" || return
    }
fi

# Wrapper for reloading a screen with a command at any hit key

function press_to_reload {
    [[ -z "${1}" ]] && echo "Usage: press_to_reload [-t auto_reload] command" && return
    [[ "${1}" == "-t" ]] && AUTO_RELOAD="${2}" && shift 2 || AUTO_RELOAD=3600
    [[ -n "${ZSH_VERSION}" ]] && READ_ARGS="-k" || READ_ARGS="-n"
    local KEY_PRESSED

    press_to_reload_runner "$@"
    while read -s -r "${READ_ARGS}" 1 -t "${AUTO_RELOAD}" "KEY_PRESSED" || :; do
        [[ "${KEY_PRESSED}" == "q" || "${KEY_PRESSED}" == "Q" ]] && break
        press_to_reload_runner "$@"
    done
}

function press_to_reload_runner {
    clear
    echo "run : $* | auto_reload : ${AUTO_RELOAD}"
    "$@"
    echo -e "\n${TXTBOLD}${TXTGREEN}Press any key to reload,${TXTRED} q for exiting${TXTNORMAL}"
}

# Wrapper for retrying command until it works

function retry {
    [[ -z "${1}" ]] && echo "Usage: retry command" && return
    while true; do
        "${@}" && break
        sleep 1
    done
}

# Mosh

function kill_idle_mosh {
    pgrep "mosh-server" | xargs -r --verbose kill -TERM
    # ps -e | grep "mosh-server" | grep -v "^$PPID" | awk '{print $1}' | xargs -r --verbose kill -TERM
}

# List crontabs for all user

function cron_all_users {
    while read -r cron_user; do
        sudo crontab -u "${cron_user}" -l
    done <<< "$(grep -ve '^#' /etc/passwd | cut -f1 -d:)"
}

# Scanning new or expanded disks in a VM

function scan_new_disk {
    BEFORE=$(sudo lsblk -r -n)
    for scsi_host in /sys/class/scsi_host/*; do
        sudo bash -c "echo '- - -' > ${scsi_host}/scan"
    done
    AFTER=$(lsblk -r -n)
    NEW_DISKS=$(echo -e "${AFTER}\n${BEFORE}" | sort | uniq -c | grep '^\ *1 ' | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    [[ -z "$NEW_DISKS" ]] && echo "Pas de nouveaux disques détectés" || echo "Le(s) disque(s) $NEW_DISKS ont été détectés"
}

function rescan_disks {
    BEFORE=$(sudo lsblk -r -n)
    for scsi_device in /sys/class/scsi_device/*; do
        sudo bash -c "echo 1 > ${scsi_device}/device/rescan"
    done
    AFTER=$(sudo lsblk -r -n)

    diff -y <(echo "$BEFORE") <(echo "$AFTER") | grep '|' | awk '{print $1": "$4" => "$11}'
}

# Ansible shortcuts

function ansible_role {
    ansible_role="${1}"
    ansible_target="${2}"
    shift 2
    temp_playbook=$(mktemp)
cat > "${temp_playbook}" <<- EOM
---
- hosts: ${ansible_target}
  roles:
    - ${ansible_role}
EOM
    if ! unbuff_binary="$(which unbuffer)"
    then
      unbuff_binary=""
    fi
    $unbuff_binary ansible-playbook "${temp_playbook}" "${@}"
    rm -rf "${temp_playbook}"
}

# Travis

function travis_overview {
    local GREP_PATTERN
    for item in "$@"; do
        GREP_PATTERN="${GREP_PATTERN}${item}|"
    done
    GREP_PATTERN="${GREP_PATTERN%?}"
    GREP_PATTERN="${GREP_PATTERN:-*}"

    # shellcheck disable=SC2016
    travis repos -a | grep '/' | awk '{print $1}' | grep -Ei "${GREP_PATTERN}" \
        | xargs -L 1 -P 10 -I {} sh -c 'printf "%-28s%s\n" "$(echo {} | cut -d / -f 2)" "$(travis history -i --limit 1 -r {})"'
}

# Screen

function screen_ctl {
    action="${1}" && shift
    screen_name="${1}" && shift
    if [[ "${action}" == "connect" ]]
    then
        if ! screen -rd "${screen_name}"
        then
            screen -S "${screen_name}"
        fi
    elif [[ "${action}" == "cmd" ]]
    then
        cmd="${*}\n"
        screen -S "${screen_name}" -X stuff "${cmd}"
    fi
}

function device_as_screen {
    device_name="${1}" && shift
    [[ "${1}" == "connect" ]] && screen_ctl connect "${device_name}" && return
    screen_ctl cmd "${device_name}" "${@}"
}

alias iphone='device_as_screen iphone'
alias ipad='device_as_screen ipad'

# Tmux

function aoc2018 {
    if ! tmux has-session -t aoc &> /dev/null
    then
        tmux new-session -s aoc -n aoc -d 'zsh -c "cd github/others/adventofcode2018; zsh -i; export TERM=screen"'
        tmux split-window -d -h -p 40 -t aoc 'zsh -c "cd github/others/adventofcode2018; source ~/.zshrc ; press_to_reload tox -q; zsh -i"'
    fi

    tmux attach-session -t aoc
}

fawk() {
    first="awk '{print "
    last="}' $2"
    cmd="${first}\$${1}${last}"
    eval "$cmd"
}

secondstoduration() {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( D > 0 )) && printf '%d jours ' $D
    (( H > 0 )) && printf '%d heures ' $H
    (( M > 0 )) && printf '%d minutes ' $M
    (( D > 0 || H > 0 || M > 0 )) && printf 'and '
    printf '%d secondes\n' $S
}

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

# Aliases
alias rto='press_to_reload -t 300 travis_overview'
alias lg='lazygit'
