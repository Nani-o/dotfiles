#!/bin/zsh -e

if (( $+commands[wget] )); then
  [[ ! -d "${HOME}/.oh-my-zsh" ]] && RUNZSH=no sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
else
  [[ ! -d "${HOME}/.oh-my-zsh" ]] && RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

REPO_PATH=~/.oh-my-zsh/custom/themes/powerlevel10k
REPO_URL="https://github.com/romkatv/powerlevel10k"

[[ -d "$REPO_PATH" ]] \
  || git clone "$REPO_URL" "$REPO_PATH"

REPO_PATH=~/.dotfiles
REPO_URL="https://github.com/Nani-o/dotfiles"

[[ -d "$REPO_PATH" ]] \
  && git -C "$REPO_PATH" pull \
  || git clone "$REPO_URL" "$REPO_PATH"

"${REPO_PATH}/symlinks.sh"

[[ "$0" == "zsh" ]] && exec zsh -l
