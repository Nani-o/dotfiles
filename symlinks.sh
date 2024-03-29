#!/bin/zsh -e

# Repo path
REPO_PATH=~/.dotfiles

# Temp file to store symlinks created
TMPFILE=$(mktemp -t symlinks.XXXXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

# Where the symlinks list is stored
EXISTING_SYMLINKS="${REPO_PATH}/.symlinks"
touch "${EXISTING_SYMLINKS}"

# List of files to symlink and folders to create
ROOT_FILES=$(find "$REPO_PATH" -maxdepth 1 -type f \( -iname '.*' ! -iname '.travis.yml' ! -iname '.gitignore' \))
NESTED_FILES=$(find "$REPO_PATH" -mindepth 2 -type f \( -iname '*' -ipath ${REPO_PATH}'/.*/*' ! -ipath '*.git/*' ! -ipath '*.github/workflows/*' \))
NESTED_FOLDERS=$(echo "${NESTED_FILES}" | xargs dirname | sort | uniq)

# Create root level symlinks
while read -r FILE
do
    RELATIVE_PATH="${FILE//${REPO_PATH}\//}"
    ln -fs "${REPO_PATH}/${RELATIVE_PATH}" "${HOME}/${RELATIVE_PATH}"
    echo "${HOME}/${RELATIVE_PATH}" >> "${TMPFILE}"
done <<< "${ROOT_FILES}"

# Create nested folders
while read -r FOLDER
do
    mkdir -p "${HOME}/${FOLDER//${REPO_PATH}\//}"
done <<< "${NESTED_FOLDERS}"

# Create nested symlinks
while read -r FILE
do
    RELATIVE_PATH="${FILE//${REPO_PATH}\//}"
    ln -fs "${REPO_PATH}/${RELATIVE_PATH}" "${HOME}/${RELATIVE_PATH}"
    echo "${HOME}/${RELATIVE_PATH}" >> "${TMPFILE}"
done <<< "${NESTED_FILES}"

# Remove symlinks that are no longer in the repo
[[ "${OSTYPE}" == *"darwin"* ]] && xargs_flag="" || xargs_flag="--no-run-if-empty"
diff "${TMPFILE}" "${EXISTING_SYMLINKS}" | grep '>' | sed 's/^> //g' | xargs ${xargs_flag} unlink

# Update the list of symlinks installed
cat "${TMPFILE}" > "${EXISTING_SYMLINKS}"
