# Path
export "PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"

if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Editor
export EDITOR="$(which nano)"
if [[ -f '/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl' ]];
then
    export EDITOR='/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl'
    alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
elif [[ -f '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]];
then
    export EDITOR='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
    alias code='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
elif [[ -f '/mnt/c/Users/Nani/AppData/Local/Programs/Microsoft VS Code/bin/code' ]];
then
    export EDITOR='/mnt/c/Users/Nani/AppData/Local/Programs/Microsoft VS Code/bin/code'
    alias code='/mnt/c/Users/Nani/AppData/Local/Programs/Microsoft VS Code/bin/code'
fi

# Set TERM when not inside TMUX
[[ $TMUX = "" ]] && export TERM="xterm-256color"

# Set locales
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"

# Make sure HOSTNAME is lowercase
export HOSTNAME="$(hostname | tr '[:upper:]' '[:lower:]')"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
export CONTEXT_BACKGROUND=014
[[ ${HOSTNAME} == "mizuho"* ]] && export CONTEXT_BACKGROUND=014
[[ ${HOSTNAME} == "pi"* ]] && export CONTEXT_BACKGROUND=002
[[ ${HOSTNAME} == "dedinani"* ]] && export CONTEXT_BACKGROUND=001

[[ -n "$VSCODE_PROXY_URI" ]] && source ~/.p10k-vscode.zsh || source ~/.p10k.zsh

source $ZSH/oh-my-zsh.sh

# Load functions and customs
for file in ~/.funcs/* ; do
  if [ -f "$file" ] ; then
    . "$file"
  fi
done
[[ -f ~/.extras.sh ]] && source ~/.extras.sh