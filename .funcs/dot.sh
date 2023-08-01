function dot {
  case $1 in
  update)
    __update_dotfiles
    ;;
  status)
    git -C ~/.dotfiles status
    ;;
  *)
    echo "dot: '$1' command unrecognized"
    ;;
  esac
}

function __update_dotfiles {
  BEFORE="$(git -C ~/.dotfiles log -1 --oneline)"
  git -C ~/.dotfiles pull
  AFTER="$(git -C ~/.dotfiles log -1 --oneline)"
  if [[ "$BEFORE" != "$AFTER" ]]
  then
    ~/.dotfiles/symlinks.sh
    source ~/.zshrc
  fi
}

function __commit_and_push_dotfiles {
  # Check if there are any changes in ~/.dotfiles repository
  if [[ -n $(git -C ~/.dotfiles status --porcelain) ]]
  then
    git -C ~/.dotfiles add .
    git -C ~/.dotfiles commit
    git -C ~/.dotfiles push
  fi
}