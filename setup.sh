#!/bin/sh

# editor and terminal
mkdir -p ~/.config/emacs/



ln -s ~/dotfiles/.zshenv ~/.zshenv
ln -s ~/dotfiles/.config/zsh ~/.config/zsh
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/.config/bat ~/.config/bat

ln -s ~/dotfiles/.config/emacs/init.org ~/.config/emacs.d/init.org 
cp ~/dotfiles/extra/init.el ~/.config/emacs/init.el

# get a modern terminal color going
cp ~/dotfiles/terminfo-24bit.src ~/terminfo-24bit.src
tic -x -o ~/.terminfo terminfo-24bit.src

if [[ "$OSTYPE" == "darwin"* ]]; then

    # install basic brew packages
    brew install openssl coreutils the fuck
    brew install git tmux zsh starship
    brew install exa bat rg fd
    brew install glances jq fx htop httpie tree gpg graphviz
    brew install rsync
    brew install open-mpi

#brew install emacs-plus@27 --with-xwidgets --with-no-frame-refocus --with-no-titlebar --with-retro-sink-bw-icon

    brew install python

    pip install virtualenvwrapper ipython

    mkdir -p ~/.environs


    VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
    export WORKON_HOME=~/.environs

    source /usr/local/bin/virtualenvwrapper.sh


    cp ~/dotfiles/.environs/reqs.txt ~/.environs/reqs.txt
    cp ~/dotfiles/.environs/postmkvirtualenv ~/.environs/postmkvirtualenv 
fi
