[![Checks our dotfiles](https://github.com/Nani-o/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Nani-o/dotfiles/actions/workflows/shellcheck.yml)

My dotfiles
===========

Keeping track of my dotfiles in a git repo after seeing [geerlingguy](https://github.com/geerlingguy/dotfiles) one's.

Using
-----

I used to run an ansible [role](https://github.com/Nani-o/ansible-role-dotfiles) for deploying my dotfiles, I now use a setup script :

```Shell
zsh -ec "$(wget https://raw.githubusercontent.com/Nani-o/dotfiles/master/install.sh -O -)"
```

or :

```Shell
zsh -ec "$(curl -fsSL https://raw.githubusercontent.com/Nani-o/dotfiles/master/install.sh)"
```

What this script does is :
  - Installing Oh My Zsh
  - Installing powelevel10k theme
  - Cloning this repo in HOME/.dotfiles
  - Link all dotfiles from this repo in the HOME folder

License
-------

MIT

Author Information
------------------

Sofiane MEDJKOUNE
