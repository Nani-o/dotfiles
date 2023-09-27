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

    pipx_packages=(
        rich
        httpie
    )

    install_pipx_packages
}

function install_ansible () {
    # Install Ansible
    ansible_pipx_packages=(
        ansible-core
        ansible-lint
    )
    # shellcheck disable=SC2068
    install_pipx_packages ${ansible_pipx_packages[@]}
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
  rich "update dotfiles" --rule --rule-style "green" --style "green"
  dot update
  rich "omz update" --rule --rule-style "green" --style "green"
  omz update --unattended
  if exists brew
  then
    rich "brew upgrade" --rule --rule-style "green" --style "green"
    brew upgrade
  fi
  if exists pipx
  then
    rich "pipx upgrade-all" --rule --rule-style "green" --style "green"
    pipx upgrade-all
  fi
  if [[ -f /etc/debian_version ]]
  then
    rich "apt update" --rule --rule-style "green" --style "green"
    sudo apt -y update
    rich "apt upgrade" --rule --rule-style "green" --style "green"
    sudo apt -y upgrade
    rich "apt autoremove" --rule --rule-style "green" --style "green"
    sudo apt -y autoremove
  fi
  if [[ "$OSTYPE" == "darwin"* ]]
  then
    rich "softwareupdate -i -a" --rule --rule-style "green" --style "green"
    sudo softwareupdate -i -a
  fi
}
