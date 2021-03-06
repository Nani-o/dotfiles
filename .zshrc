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
ZSH_THEME="powerlevel9k/powerlevel9k"

# https://github.com/bhilburn/powerlevel9k/wiki/Troubleshooting
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs virtualenv)
PROMPT_CONTEXT_COLOR="magenta"
[[ "${HOSTNAME}" == "dedinani.net" ]] && PROMPT_CONTEXT_COLOR="red"
[[ "${HOSTNAME}" == "narusegawa" ]] && PROMPT_CONTEXT_COLOR="cyan"
[[ "${HOSTNAME}" == "pikachu" ]] && PROMPT_CONTEXT_COLOR="yellow"
POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND="$PROMPT_CONTEXT_COLOR"
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%K{white}%k"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%K{$PROMPT_CONTEXT_COLOR} $ %k%F{$PROMPT_CONTEXT_COLOR}\ue0B0%f "
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="ffffff"
POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND="ffffff"
POWERLEVEL9K_CONTEXT_SEPARATOR="blue"
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
POWERLEVEL9K_DIR_HOME_FOREGROUND="ffffff"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="ffffff"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="ffffff"
POWERLEVEL9K_VCS_CLEAN_FOREGROUND='black'
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='black'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='black'
POWERLEVEL9K_VIRTUALENV_FOREGROUND='ffffff'
POWERLEVEL9K_VIRTUALENV_BACKGROUND='magenta'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_HOME_ICON=''
POWERLEVEL9K_HOME_SUB_ICON=''
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_ETC_ICON=''

# ENABLE_CORRECTION="true"
HIST_STAMPS="mm/dd/yyyy"
DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
)

eval $(thefuck --alias)

source $ZSH/oh-my-zsh.sh
[[ -f ~/.extras.sh ]] && source ~/.extras.sh
source ~/.funcs.sh
[[ -f ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh
