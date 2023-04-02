function setup_workstation {
    # Install Homebrew
    if test ! $(which brew); then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew bundle --file=$HOME/.dotfiles/Brewfile

    # Install pipx
    if test ! $(which pipx); then
        echo "Installing pipx..."
        pip3 install pipx
    fi
    install_ansible
}

function install_ansible () {
    # Install Ansible
    pipx_packages=(
        ansible-core
        ansible-lint
    )
    install_pipx_packages ${pipx_packages[@]}
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
