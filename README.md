[![Build Status](https://travis-ci.org/Nani-o/dotfiles.svg?branch=master)](https://travis-ci.org/Nani-o/dotfiles)

My dotfiles
===========

Keeping track of my dotfiles in a git repo after seeing [geerlingguy](https://github.com/geerlingguy/dotfiles) one's.

Travis
------

I use a simple .travis.yml for running shellcheck on my shell functions file and some generic checks like tabulations or trailing characters.

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
