function dot {
  case $1 in
  update|pull)
    __update_dotfiles
    ;;
  status)
    git -C ~/.dotfiles status
    ;;
  commit)
    __commit_dotfiles "$2"
    ;;
  push)
    __push_dotfiles
    ;;
  reload)
    __reload_dotfiles
    ;;
  *)
    echo "dot: '$1' command unrecognized"
    ;;
  esac
}

function __reload_dotfiles {
  exec zsh -l
}

function __update_dotfiles {
  BEFORE="$(git -C ~/.dotfiles log -1 --oneline)"
  git -C ~/.dotfiles pull --rebase
  AFTER="$(git -C ~/.dotfiles log -1 --oneline)"
  if [[ "$BEFORE" != "$AFTER" ]]
  then
    ~/.dotfiles/symlinks.sh
    __reload_dotfiles
  fi
}

function __commit_dotfiles {
  [[ ! -z "$1" ]] && commit_args="-m $1"
  if [[ -n $(git -C ~/.dotfiles status --porcelain) ]]
  then
    git -C ~/.dotfiles add .
    git -C ~/.dotfiles commit --author=="Sofiane Medjkoune <sofiane@medjkoune.fr>" $commit_args
    __reload_dotfiles
  fi
}
function __push_dotfiles {
  if [[ -n $(git -C ~/.dotfiles diff --stat --cached origin/master) ]]
  then
    git -C ~/.dotfiles push
  fi
}
