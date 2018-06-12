[![Build Status](https://travis-ci.org/Nani-o/dotfiles.svg?branch=master)](https://travis-ci.org/Nani-o/dotfiles)

My dotfiles
===========

Keeping track of my dotfiles in a git repo after seeing [geerlingguy](https://github.com/geerlingguy/dotfiles) one's.

Travis
------

I use a simple .travis.yml for running shellcheck on my shell functions file and some generic checks like tabulations or trailing characters.

Using
-----

I use an ansible [role](https://github.com/Nani-o/ansible-role-dotfiles) for deploying my dotfiles on my workstations/servers.

For example if your dotfiles is cloned in **~/dotfiles**, you can run :

```Shell
find dotfiles/ -maxdepth 1 -type f \( -iname '.*' ! -iname '.travis.yml' \) \
    | xargs readlink -f \
    | xargs -L 1 -I {} echo ln -s "{}" "${HOME}"
```

It will just output the **ln -s** commands, copy paste them or remove the echo to make actual symlinks.

License
-------

MIT

Author Information
------------------

Sofiane MEDJKOUNE
