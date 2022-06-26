# Path
export "PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"

# Editor
export EDITOR="$(which nano)"
if [[ -f '/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl' ]];
then
    export EDITOR='/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl'
    alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
fi

# Set TERM when not inside TMUX
[[ $TMUX = "" ]] && export TERM="xterm-256color"

# Make sure HOSTNAME is lowercase
export HOSTNAME="$(hostname | tr '[:upper:]' '[:lower:]')"

# Load functions and customs
source ~/.funcs.sh
[[ -f ~/.extras.sh ]] && source ~/.extras.sh

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
export CONTEXT_BACKGROUND=014
[[ ${HOSTNAME} == "mizuho"* ]] && export CONTEXT_BACKGROUND=014
[[ ${HOSTNAME} == "pi"* ]] && export CONTEXT_BACKGROUND=002
[[ ${HOSTNAME} == "dedinani"* ]] && export CONTEXT_BACKGROUND=001
source ~/.p10k.zsh

source $ZSH/oh-my-zsh.sh
