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
    BUFFERED=0
    AUTO_RELOAD=3600
    while getopts 'bt:' opt; do
        case $opt in
                b) BUFFERED=1;;
                t) AUTO_RELOAD=$OPTARG;;
        esac
    done

    shift $((OPTIND-1))

    [[ -z "${1}" ]] && echo "Usage: press_to_reload [-t auto_reload] command" && return
    [[ -n "${ZSH_VERSION}" ]] && READ_ARGS="-k" || READ_ARGS="-n"
    local KEY_PRESSED

    press_to_reload_runner "$@"
    while read -s -r "${READ_ARGS}" 1 -t "${AUTO_RELOAD}" "KEY_PRESSED" || :; do
        [[ "${KEY_PRESSED}" == "q" || "${KEY_PRESSED}" == "Q" ]] && break
        press_to_reload_runner "$@"
    done
}

function press_to_reload_runner {
    [[ "$BUFFERED" == 1 ]] && BUFFER=$("$@")
    clear
    echo "run : $* | auto_reload : ${AUTO_RELOAD}s"
    [[ "$BUFFERED" == 1 ]] && echo "$BUFFER" || "$@"
    echo -e "\n${TXTBOLD}${TXTGREEN}Press any key to reload,${TXTRED} q for exiting${TXTNORMAL}"
}

function watchnrun {
    WATCH="${1}"
    shift
    RUN=("${@}")
    HASH=""
    [[ (( $+commands[gfind] )) ]] && FIND_BIN=gfind || FIND_BIN=find
    while true
    do
        NEW_HASH=$("${FIND_BIN}" "${WATCH}" -type f -not -path "*.git/*" -printf '%m%c%p' | md5sum)
        if [[ "${HASH}" != "${NEW_HASH}" && "${HASH}" != "" ]]; then
            "${RUN[@]}"
        fi
        HASH="${NEW_HASH}"
        sleep 2
    done
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
    temp_playbook=$(mktemp -p $(pwd))
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

# LXD

function lxc_create_aliases {
    LAB_CONTAINERS=$(lxc list lab- -c n --format csv | tr '\n' ' ' | sed 's/\ $//')
    lxc alias remove stop-lab
    lxc alias add stop-lab "stop -f --timeout 5 ${LAB_CONTAINERS}"
    lxc alias remove start-lab
    lxc alias add start-lab "start ${LAB_CONTAINERS}"
}

# Docker OS X

if [[ "${OSTYPE}" == *"darwin"* ]]; then
    function is_docker_running {
        pgrep Docker >/dev/null 2>&1
        return $?
    }

    function docker_start {
        is_docker_running && echo "Docker already started" && return
        open -a Docker
        echo "Docker starting"
        START="$(date +%s)"
    }

    function docker_stop {
        is_docker_running && osascript -e 'quit app "Docker"' && echo "Docker stopped" && return
        echo "Docker already stopped"
    }

    function docker_purge {
        if is_docker_running; then
            CONTAINERS=$(docker ps -a -q | tr '\n' ' ')
            [[ ! -z "${CONTAINERS}" ]] && docker rm --force ${=CONTAINERS}
            docker system prune --all --force
        else
            echo "Docker is not running"
        fi
    }
fi

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
        cmd="${*}"
        screen -S "${screen_name}" -X stuff "${cmd}"$(echo -ne '\015')
    fi
}

function device_as_screen {
    device_name="${1}" && shift
    [[ "${1}" == "connect" ]] && screen_ctl connect "${device_name}" && return
    screen_ctl cmd "${device_name}" "${@}"
}

# Tmux

function dshell {
    session="dshell"
    pwd=$(pwd)
    if tmux has-session -t $session &> /dev/null
    then
        tmux kill-session -t $session
    fi
    tmux new-session -s $session -n $session -d "zsh -c \"cd $pwd; source ~/.zshrc ; touch dshell.sh ; nano dshell.sh ; rm dshell.sh\""
    tmux split-window -d -h -p 40 -t $session "zsh -c \"cd $pwd; source ~/.zshrc ; watchnrun dshell.sh zsh dshell.sh\""

    tmux attach-session -t $session
}

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

# Videos

function video2gif {
    palette="/tmp/palette.png"
    filters="fps=15,scale=1080:-1:flags=lanczos"
    ffmpeg -v warning -i $1 -vf "$filters,palettegen" -y $palette
    ffmpeg -v warning -i $1 -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y $2
    rm $palette
}

# Text

function remove_blank_lines {
    sed -i '/^[[:space:]]*$/d' "$1"
}
