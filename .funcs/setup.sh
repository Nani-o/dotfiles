#!/usr/bin/env zsh

# Test if binary exists using zsh
function exists () {
    if [[ -x "$(command -v $1)" ]]; then
        return 0
    else
        return 1
    fi
}

function setup_workstation {
    wsl_conf_custom_sha1="$(sha1sum $HOME/.dotfiles/other/wsl.conf 2>/dev/null | awk '{print $1}')"
    wsl_conf_current_sha1="$(sha1sum /etc/wsl.conf 2>/dev/null | awk '{print $1}')"
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop && $wsl_conf_custom_sha1 != $wsl_conf_current_sha1 ]]; then
        echo "[bash] WSL detected"
        read -q "REPLY?Do you want to install /etc/wsl.conf file ? [y/N]"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_wsl
        fi
    fi

    # Install Homebrew
    if ! exists brew; then
        echo "[bash] Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        source ~/.zshrc
    else
        echo "[bash] Homebrew is already installed"
    fi

    echo "[brew] Installing Homebrew packages..."
    brew bundle --file=$HOME/.dotfiles/Brewfile
    rm -rf $HOME/.dotfiles/Brewfile.lock.json

    # Install pipx
    if ! exists pipx; then
        echo "[pip3] Installing pipx..."
        pip3 install pipx
    else
        echo "[pip3] pipx is already installed"
    fi
    install_ansible
}

function install_ansible () {
    # Install Ansible
    pipx_packages=(
        ansible-core
        ansible-lint
    )
    # shellcheck disable=SC2068
    install_pipx_packages ${pipx_packages[@]}
}

function setup_wsl () {
    echo "[bash] Installing /etc/wsl.conf file..."
    sudo cp $HOME/.dotfiles/other/wsl.conf /etc/wsl.conf
    read -q "REPLY?Do you want to stop WSL in order to changes to be applied ? [y/N]"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        wsl.exe --shutdown
    fi
}

function install_pipx_packages () {
    # Install pipx packages
    pipx_packages=("$@")
    for package in "${pipx_packages[@]}"; do
        if pipx list | grep -q $package; then
            echo "[pipx] $package is already installed"
        else
            echo "[pipx] Installing $package..."
            pipx install $package
        fi
    done
}

function update {
  echo "${TXTCYAN}update dotfiles${TXTNORMAL}"
  dot update
  echo -e "\n${TXTCYAN}omz update${TXTNORMAL}"
  omz update
  if exists brew
  then
    echo -e "\n${TXTCYAN}brew upgrade${TXTNORMAL}"
    brew upgrade
  fi
  if exists pipx
  then
    echo -e "\n${TXTCYAN}pipx upgrade-all${TXTNORMAL}"
    pipx upgrade-all
  fi
  if [[ -f /etc/debian_version ]]
  then
    echo -e "\n${TXTCYAN}apt update${TXTNORMAL}"
    sudo apt -y update
    echo -e "\n${TXTCYAN}apt upgrade${TXTNORMAL}"
    sudo apt -y upgrade
    echo -e "\n${TXTCYAN}apt autoremove${TXTNORMAL}"
    sudo apt -y autoremove
  fi
  if [[ "$OSTYPE" == "darwin"* ]]
  then
    echo -e "\n${TXTCYAN}softwareupdate -i -a${TXTNORMAL}"
    sudo softwareupdate -i -a
  fi
}
