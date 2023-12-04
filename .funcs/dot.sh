function dot {
  case $1 in
  update|pull)
    __dot_pull
    ;;
  status)
    git -C ~/.dotfiles status
    ;;
  commit)
    __dot_commit "$2"
    ;;
  push)
    __dot_push
    ;;
  git)
    shift
    git -C ~/.dotfiles "$@"
    ;;
  link)
    ~/.dotfiles/symlinks.sh
    ;;
  reload)
    __dot_reload
    ;;
  help)
    __dot_help
    ;;
  *)
    echo -e "dot: '$1' is not a valid subcommand.\n"
    __dot_help
    ;;
  esac
}

function __dot_help {
    echo -e "usage: dot [subcommand]\n
Theses are dot subcommands:
  update:   download the latest commits of dotfiles and reload zsh
  status:   show the git status of dotfiles
  commit:   commit the local changes of dotfiles
  push:     push the local changes of dotfiles
  git:      run git command in dotfiles
  help:     show this help message
  reload:   reload zsh"
}

function __dot_reload {
  exec zsh -l
}

function __dot_pull {
  BEFORE="$(git -C ~/.dotfiles log -1 --oneline)"
  git -C ~/.dotfiles pull --rebase
  AFTER="$(git -C ~/.dotfiles log -1 --oneline)"
  if [[ "$BEFORE" != "$AFTER" ]]
  then
    ~/.dotfiles/symlinks.sh
    __dot_reload
  fi
}

function __dot_commit {
  [[ ! -z "$1" ]] && commit_args="-m $1"
  if [[ -n $(git -C ~/.dotfiles status --porcelain) ]]
  then
    git -C ~/.dotfiles add .
    git -C ~/.dotfiles commit --author=="Sofiane Medjkoune <sofiane@medjkoune.fr>" $commit_args
    __dot_reload
  fi
}
function __dot_push {
  if [[ -n $(git -C ~/.dotfiles diff --stat --cached origin/master) ]]
  then
    git -C ~/.dotfiles push
  fi
}
