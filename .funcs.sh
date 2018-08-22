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

# Ansible shortcuts

function ansible_role {
    ansible_role="${1}"
    ansible_target="${2}"
    shift 2
    temp_playbook=$(mktemp -p /tmp --suffix '.yml')
cat > "${temp_playbook}" <<- EOM
---
- hosts: ${ansible_target}
  roles:
    - ${ansible_role}
EOM
    ansible-playbook "${temp_playbook}" "${@}"
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
        screen -rd ${screen_name}
        [[ "${?}" != 0 ]] && screen -S ${screen_name}
    elif [[ "${action}" == "cmd" ]]
    then
        cmd="${@}\n"
        screen -S ${screen_name} -X stuff "${cmd}"
    fi
}

function device_as_screen {
    device_name="${1}" && shift
    [[ "${1}" == "connect" ]] && screen_ctl connect ${device_name} && return
    screen_ctl cmd ${device_name} "${@}"
}

alias iphone='device_as_screen iphone'
alias ipad='device_as_screen ipad'

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

# Some aliases for funcs
alias rto='press_to_reload -t 300 travis_overview'
alias lg='lazygit'