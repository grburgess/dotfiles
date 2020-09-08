


alias gofermi="ssh -Y fermi@ds54.mpe.mpg.de"
alias golocal="ssh ga-ws71.mpe.mpg.de"
alias necromancer="ssh -X necromancer.mpe.mpg.de"

#alias emacs="/usr/local/bin/emacs -nw"
alias notebook="jupyter notebook"


alias ..="cd .."
alias ...="cd ../.."

alias f="fd"
alias g="git"
alias j="z"
alias l="exa -lbF --git"
alias n=notebook
alias i="ipython"
alias wo="workon"
alias p="python"
alias s="rg"
alias t="tmux"
alias y="yarn"






alias rm="rm -vi"
#alias headas="source $HEADAS/headas-init.sh"

# alias 3ml="source ~/.3ml.sh"

# start the fermi docker
alias fermi="docker run -it --rm -p 8888:8888 -v ${PWD}:/workdir -w /workdir grburgess/fermi"


alias notebook="jupyter notebook"
alias et='te'
alias rm="rm -vi"
#alias headas="source $HEADAS/headas-init.sh"

alias 3ml="source ~/.3ml.sh"

# start the fermi docker
alias fermi="docker run -it --rm -p 8888:8888 -v ${PWD}:/workdir -w /workdir grburgess/fermi"

#source $(dirname $(gem which colorls))/tab_complete.sh

# alias ls='colorls --sort-dirs'
# alias lc='colorls --tree'
alias ls="exa"
alias ll="exa --long --header --git --time-style long-iso --color-scale"


# alias weather='curl http://v2.wttr.in'



alias use_conda='export PATH=${PATH_WITH_CONDA}; export PATH="$PATH:$HOME/.rvm/bin"' 
alias no_conda='export PATH=${PATH_WITHOUT_CONDA}; export PATH="$PATH:$HOME/.rvm/bin"'
