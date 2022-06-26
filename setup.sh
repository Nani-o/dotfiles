#!/usr/bin/env zsh

REPO_PATH=~/.dotfiles
REPO_URL="https://github.com/Nani-o/dotfiles"

[[ -d "$REPO_PATH" ]] \
  && git -C "$REPO_PATH" pull \
  || git clone "$REPO_URL" "$REPO_PATH"

find "$REPO_PATH" -maxdepth 1 -type f \( -iname '.*' ! -iname '.travis.yml' ! -iname '.gitignore' \) \
    | xargs -I {} ln -fs "{}" "${HOME}/"

NESTED=$(find "$REPO_PATH" -mindepth 2 -type f \( -iname '*' ! -ipath '*.git/*' \))

echo "${NESTED}" \
    | xargs dirname \
    | sed "s@$REPO_PATH/@${HOME}/@g" \
    | xargs -I {} readlink {} \
    | xargs -I {} unlink "{}"

echo "${NESTED}" \
    | xargs dirname \
    | sed "s@$REPO_PATH/@${HOME}/@g" \
    | xargs -I {} mkdir -p "{}"

echo "${NESTED}" \
    | sed "s@$REPO_PATH/@@g" \
    | xargs -I {} ln -fs "${REPO_PATH}/{}" "${HOME}/{}"
