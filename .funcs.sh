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
    echo -e "\n${txtbold}${txtgreen}Press any key to reload,${txtred} q for exiting${txtnormal}"
}

# Wrapper for retrying command until it works

function retry {
    [[ -z "${1}" ]] && echo "Usage: retry command" && return
    while true; do
        "${@}" && break
        sleep 1
    done
}

# List crontabs for all user

function cron_all_users {
    while read -r cron_user; do
        sudo crontab -u "${cron_user}" -l
    done <<< "$(cut -f1 -d: /etc/passwd)"
}

# Scanning new or expanded disks in a VM

function scan_new_disk {
    for scsi_host in /sys/class/scsi_host/*; do
        sudo bash -c "echo '- - -' > /sys/class/scsi_host/${scsi_host}/scan"
    done
}

function rescan_disks {
    for scsi_device in /sys/class/scsi_device/*; do
        sudo bash -c "echo 1 > /sys/class/scsi_device/${scsi_device}/device/rescan"
    done
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

# Chart for tput colors
# inspired by https://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/

function tput_colors {
    printf "$(tput bold)%-10s%-10s%-10s%-10s$(tput sgr0)\n" regular bold underline tput-command-colors
    for i in $(seq 1 7); do
        local REG="$(tput setaf $i)%-10s$(tput sgr0)"
        local BLD="$(tput bold)$(tput setaf $i)%-10s$(tput sgr0)"
        local UND="$(tput smul)$(tput setaf $i)%s$(tput sgr0)"
        local CMD="%21s"
        printf "${REG}${BLD}${UND}${CMD}\n" "Text" "Text" "Text" "\$(tput setaf $i)"

    done
    for item in "Bold:bold" "Underline:smul" "Reset:sgr0"; do
        local LBL="$(echo ${item} | cut -d ':' -f1)"
        local TPT="$(echo ${item} | cut -d ':' -f2)"
        printf "%-30s%s\n" "${LBL}" "\$(tput ${TPT})"
    done
}

# ANSI Escape sequence for color stored as variables with tput

txtblack=$(tput setaf 0)
txtred=$(tput setaf 1)
txtgreen=$(tput setaf 2)
txtlime_yellow=$(tput setaf 190)
txtyellow=$(tput setaf 3)
txtpowder_blue=$(tput setaf 153)
txtblue=$(tput setaf 4)
txtmagenta=$(tput setaf 5)
txtcyan=$(tput setaf 6)
txtwhite=$(tput setaf 7)
txtblink=$(tput blink)
txtreverse=$(tput smso)
txtbold=$(tput bold)
txtunderline=$(tput smul)
txtnormal=$(tput sgr0)

# Some aliases for funcs
alias rto='press_to_reload -t 300 travis_overview'
