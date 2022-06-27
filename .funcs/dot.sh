function dot {
  case $1 in
  update)
    __update_dotfiles
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
