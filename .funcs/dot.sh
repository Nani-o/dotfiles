function dot {
  case $1 in
  update)
    __update_dotfiles
    ;;
  status)
    git -C ~/.dotfiles status
    ;;
  commit|push)
    __commit_and_push_dotfiles "$2"
    ;;
  *)
    echo "dot: '$1' command unrecognized"
    ;;
  esac
}

function __update_dotfiles {
  BEFORE="$(git -C ~/.dotfiles log -1 --oneline)"
  git -C ~/.dotfiles pull --rebase
  AFTER="$(git -C ~/.dotfiles log -1 --oneline)"
  if [[ "$BEFORE" != "$AFTER" ]]
  then
    ~/.dotfiles/symlinks.sh
    source ~/.zshrc
  fi
}

function __commit_and_push_dotfiles {
  [[ ! -z "$1" ]] && commit_args="-m $1"
  if [[ -n $(git -C ~/.dotfiles status --porcelain) ]]
  then
    git -C ~/.dotfiles add .
    git -C ~/.dotfiles commit --author=="Sofiane Medjkoune <sofiane@medjkoune.fr>" $commit_args
  fi
  if [[ -n $(git -C ~/.dotfiles diff --stat --cached origin/master) ]]
  then
    echo git -C ~/.dotfiles push
  fi
}
