# If you come from bash you might have to change your $PATH.
export "PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"
[[ ${HOSTNAME} == "mizuho"* ]] && export CONTEXT_BACKGROUND=014
[[ ${HOSTNAME} == "pi"* ]] && export CONTEXT_BACKGROUND=002
[[ ${HOSTNAME} == "dedinani"* ]] && export CONTEXT_BACKGROUND=001
source ~/.p10k.zsh

[[ -f ~/.extras.sh ]] && source ~/.extras.sh
source ~/.funcs.sh
[[ -f ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh
source $ZSH/oh-my-zsh.sh
