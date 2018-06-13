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
    [[ -z "$@" ]] && echo "Usage: press_to_reload [-t auto_reload] command" && return
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
    [[ -z "${@}" ]] && echo "Usage: retry command" && return
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
    # shellcheck disable=SC2016
    travis repos -a | grep '/' | awk '{print $1}' | xargs -L 1 -P 10 -I {} sh -c 'printf "%-28s%s\n" "$(echo {} | cut -d / -f 2)" "$(travis history -i --limit 1 -r {})"'
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
