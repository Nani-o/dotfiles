#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

section() {
  printf '\n==> %s\n' "$1"
}

section "zsh syntax"
zsh -n \
  install.sh \
  symlinks.sh \
  .zshrc \
  .p10k.zsh \
  .p10k-vscode.zsh \
  .funcs/*.sh

section "shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/check.sh
else
  echo "shellcheck not found; skipping"
fi

check_pattern() {
  local label="$1"
  local pattern="$2"
  local found=0
  local file

  while IFS= read -r -d '' file; do
    [[ -f "$file" ]] || continue
    if grep -nIH -I "$pattern" "$file"; then
      found=1
    fi
  done < <(git ls-files -z --cached --others --exclude-standard)

  if (( found )); then
    echo "$label found" >&2
    exit 1
  fi
}

section "tab characters"
check_pattern "tab characters" $'\t'

section "trailing whitespace"
check_pattern "trailing whitespace" '[[:blank:]]$'
