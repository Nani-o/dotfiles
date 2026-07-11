[![Checks](https://github.com/Nani-o/dotfiles/actions/workflows/checks.yml/badge.svg)](https://github.com/Nani-o/dotfiles/actions/workflows/checks.yml)

My dotfiles
===========

Keeping track of my dotfiles in a git repo after seeing [geerlingguy](https://github.com/geerlingguy/dotfiles) one's.

Checks
------

I use a GitHub Actions workflow for syntax checks and repository hygiene.
The same checks can be run locally:

```Shell
scripts/check.sh
```

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
