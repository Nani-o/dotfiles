# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/home/nani/.oh-my-zsh
export EDITOR=/bin/nano

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel9k/powerlevel9k"

# https://github.com/bhilburn/powerlevel9k/wiki/Troubleshooting
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs virtualenv)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
POWERLEVEL9K_DIR_HOME_FOREGROUND="ffffff"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="ffffff"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="ffffff"
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="ffffff"
POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND="ffffff"
POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND="red"
POWERLEVEL9K_CONTEXT_SEPARATOR="blue"
POWERLEVEL9K_VCS_CLEAN_FOREGROUND='black'
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='black'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='black'
POWERLEVEL9K_VIRTUALENV_FOREGROUND='ffffff'
POWERLEVEL9K_VIRTUALENV_BACKGROUND='magenta'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%K{white}%k"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%K{red} $%k%F{red}\ue0B0%f "

ENABLE_CORRECTION="true"
HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
)

source $ZSH/oh-my-zsh.sh
source ~/.funcs.sh
