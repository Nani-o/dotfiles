#!/bin/zsh -e

REPO_PATH=~/.dotfiles

find "$REPO_PATH" -maxdepth 1 -type f \( -iname '.*' ! -iname '.travis.yml' ! -iname '.gitignore' \) \
    | xargs -I {} ln -fs "{}" "${HOME}/"

NESTED=$(find "$REPO_PATH" -mindepth 2 -type f \( -iname '*' ! -ipath '*.git/*' \))

while read -r broken_link
do
    target=$(readlink "$broken_link")
    [[ "$target" == "${HOME}/.dotfiles/"* ]] && unlink "$broken_link"
done <<< "$(find "${HOME}" -maxdepth 3 -type l ! -exec test -e {} \; -print)"

echo "${NESTED}" \
    | xargs dirname \
    | sed "s@$REPO_PATH/@${HOME}/@g" \
    | xargs -I {} mkdir -p "{}"

echo "${NESTED}" \
    | sed "s@$REPO_PATH/@@g" \
    | xargs -I {} ln -fs "${REPO_PATH}/{}" "${HOME}/{}"

