function dot {
  case $1 in
  setup)
    __dot_setup_workstation
    ;;
  update)
    __dot_update "$2"
    ;;
  pull)
    __dot_pull "$2"
    ;;
  status)
    git -C ~/.dotfiles status
    ;;
  commit)
    __dot_commit "$2"
    ;;
  push)
    __dot_push
    ;;
  git)
    shift
    git -C ~/.dotfiles "$@"
    ;;
  link)
    ~/.dotfiles/symlinks.sh
    ;;
  reload)
    __dot_reload
    ;;
  help)
    __dot_help
    ;;
  '')
    __dot_help
    ;;
  *)
    echo -e "dot: '$1' is not a valid subcommand.\n"
    __dot_help
    ;;
  esac
}

function __dot_help {
    echo -e "usage: dot [subcommand]\n
Theses are dot subcommands:
  setup:    setup this workstation
  update:   update dotfiles, packages, and system software
  pull:     download the latest commits of dotfiles and reload zsh
  status:   show the git status of dotfiles
  commit:   commit the local changes of dotfiles
  push:     push the local changes of dotfiles
  git:      run git command in dotfiles
  link:     link all dotfiles in the home folder
  help:     show this help message
  reload:   reload zsh"
}

function __dot_reload {
  exec zsh -l
}

function __dot_pull {
  BEFORE="$(git -C ~/.dotfiles log -1 --oneline)"
  git -C ~/.dotfiles pull --rebase
  AFTER="$(git -C ~/.dotfiles log -1 --oneline)"
  if [[ "$BEFORE" != "$AFTER" ]]
  then
    ~/.dotfiles/symlinks.sh
    [[ "$1" != "--no-reload" ]] && __dot_reload
  fi
}

# Test if binary exists using zsh
function __dot_exists {
  if [[ -x "$(command -v "$1")" ]]; then
    return 0
  else
    return 1
  fi
}

function __dot_setup_workstation {
  wsl_conf_custom_sha1="$(sha1sum $HOME/.dotfiles/other/wsl.conf 2>/dev/null | awk '{print $1}')"
  wsl_conf_current_sha1="$(sha1sum /etc/wsl.conf 2>/dev/null | awk '{print $1}')"
  if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop && $wsl_conf_custom_sha1 != $wsl_conf_current_sha1 ]]; then
    echo "[bash] WSL detected"
    read -q "REPLY?Do you want to install /etc/wsl.conf file ? [y/N]"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      __dot_setup_wsl
    fi
  fi

  # Install Homebrew
  if ! __dot_exists brew; then
    echo "[bash] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    source ~/.zshrc
  else
    echo "[bash] Homebrew is already installed"
  fi

  echo "[brew] Installing Homebrew packages..."
  brew bundle --file="$HOME/.dotfiles/Brewfile"
  rm -f "$HOME/.dotfiles/Brewfile.lock.json"

  __dot_install_ansible

  pipx_packages=(
    httpie
  )

  __dot_install_pipx_packages "${pipx_packages[@]}"
}

function __dot_install_ansible {
  # Install Ansible
  ansible_pipx_packages=(
    ansible-core
    ansible-lint
  )
  __dot_install_pipx_packages "${ansible_pipx_packages[@]}"
  pipx inject ansible-core ansible
}

function __dot_setup_wsl {
  echo "[bash] Installing /etc/wsl.conf file..."
  sudo cp "$HOME/.dotfiles/other/wsl.conf" /etc/wsl.conf
  read -q "REPLY?Do you want to stop WSL in order to changes to be applied ? [y/N]"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    wsl.exe --shutdown
  fi
}

function __dot_install_pipx_packages {
  # Install pipx packages
  pipx_packages=("$@")
  for package in "${pipx_packages[@]}"; do
    if pipx list | grep -q "$package"; then
      echo "[pipx] $package is already installed"
    else
      echo "[pipx] Installing $package..."
      pipx install "$package"
    fi
  done
}

function __dot_update {
  separator "update dotfiles"
  dot pull --no-reload
  separator "omz update"
  "$ZSH/tools/upgrade.sh"
  if __dot_exists brew
  then
    separator "brew update"
    brew update
    separator "brew upgrade"
    brew upgrade -y
  fi
  if __dot_exists pipx
  then
    separator "pipx upgrade-all"
    pipx upgrade-all
  fi
  if [[ -f /etc/debian_version ]]
  then
    separator "apt update"
    sudo apt -y update
    separator "apt upgrade"
    sudo apt -y upgrade
    separator "apt autoremove"
    sudo apt -y autoremove
  fi
  if [[ "$OSTYPE" == "darwin"* ]]
  then
    separator "softwareupdate -i -a"
    sudo softwareupdate -i -a
  fi
  [[ "$1" != "--no-reload" ]] && dot reload
}

function __dot_commit {
  [[ ! -z "$1" ]] && commit_args="-m $1"
  if [[ -n $(git -C ~/.dotfiles status --porcelain) ]]
  then
    git -C ~/.dotfiles add .
    git -C ~/.dotfiles commit --author=="Sofiane Medjkoune <sofiane@medjkoune.fr>" $commit_args
    __dot_reload
  fi
}
function __dot_push {
  if [[ -n $(git -C ~/.dotfiles diff --stat --cached origin/master) ]]
  then
    git -C ~/.dotfiles push
  fi
}
