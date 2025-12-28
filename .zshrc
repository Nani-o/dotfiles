# Path
export "PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"

if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
#  alias brew='sudo -Hi --preserve-env="https_proxy,http_proxy,ftp_proxy,PATH" -u brew -- /home/linuxbrew/.linuxbrew/bin/brew'
fi

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

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
export CONTEXT_BACKGROUND=002
OS_FLAVOR=$(uname)
[[ ${OS_FLAVOR} == "Darwin" ]] && export CONTEXT_BACKGROUND=014
[[ ${OS_FLAVOR} == "Linux" ]] && export CONTEXT_BACKGROUND=001
[[ -f "/etc.defaults/VERSION" ]] && export CONTEXT_BACKGROUND=003
[[ -n "$VSCODE_PROXY_URI" ]] && source ~/.p10k-vscode.zsh || source ~/.p10k.zsh

plugins=(pass)

source $ZSH/oh-my-zsh.sh

# Load functions and customs
for file in ~/.funcs/* ; do
  if [ -f "$file" ] ; then
    . "$file"
  fi
done
if [ -f ~/.extras.sh ] ; then
    source ~/.extras.sh
fi
