#!/bin/sh

# editor and terminal
mkdir -p ~/.config
mkdir -p ~/.emacs.d/

ln -s ~/dotfiles/.zshenv ~/.zshenv
ln -s ~/dotfiles/.config/zsh ~/.config/zsh
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf

ln -s ~/dotfiles/.config/emacs/init.org ~/.emacs.d/init.org 
cp ~/dotfiles/extra/init.el ~/.emacs.d/init.el 




# install basic brew packages
brew install openssl coreutils
brew install git tmux zsh starship
brew install exa bat rg fd
brew install glances jq fx htop httpie tree gpg graphviz
brew install rsync
brew install open-mpi

brew install emacs-plus@27 --with-xwidgets --with-no-frame-refocus --with-no-titlebar --with-retro-sink-bw-icon

brew install python

pip install virtualenvwrapper ipython

mkdir -p ~/.environs


VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
export WORKON_HOME=~/.environs

source /usr/local/bin/virtualenvwrapper.sh


cp ~/dotfiles/.environs/reqs.txt ~/.environs/reqs.txt
cp ~/dotfiles/.environs/postmkvirtualenv ~/.environs/postmkvirtualenv 
