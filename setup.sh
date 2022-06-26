#!/usr/bin/env zsh

REPO_PATH=~/.dotfiles
REPO_URL="https://github.com/Nani-o/dotfiles"

[[ -d "$REPO_PATH" ]] \
  && git -C "$REPO_PATH" pull \
  || git clone "$REPO_URL" "$REPO_PATH"

find "$REPO_PATH" -maxdepth 1 -type f \( -iname '.*' ! -iname '.travis.yml' ! -iname '.gitignore' \) \
    | xargs -L 1 -I {} ln -fs "{}" "${HOME}/"

NESTED=$(find "$REPO_PATH" -mindepth 2 -type f \( -iname '*' ! -ipath '*.git/*' \))
echo "${NESTED}" \
    | xargs dirname \
    | sed "s@$REPO_PATH/@@g" \
    | xargs -L 1 -I {} mkdir -p "${HOME}/{}"

echo "${NESTED}" \
    | sed "s@$REPO_PATH/@@g" \
    | xargs -L 1 -I {} ln -fs "${REPO_PATH}/{}" "${HOME}/{}"
