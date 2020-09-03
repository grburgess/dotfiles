#  _____    _
# |__  /___| |__  _ __ ___
#   / // __| '_ \| '__/ __|
#  / /_\__ \ | | | | | (__
# /____|___/_| |_|_|  \___|


[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return


export PATH="/usr/local/sbin:/usr/local/bin:${PATH}"
export PATH="/usr/local/lib/ruby/gems/bin:/usr/local/lib/ruby/gems/2.6.0/bin:/Library/TeX/texbin:/opt/X11/bin:${PATH}"


source ~/.config/zsh/prompt.zsh


ZSH_DISABLE_COMPFIX='true'


#Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="false"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="false"


# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

setopt appendhistory autocd extendedglob
unsetopt notify

DISABLE_UNTRACKED_FILES_DIRTY="true"


TERM=xterm-24bits



###### EMACS

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='emacs'
else
    export EDITOR='emacs'
fi






#
# ME
#

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# VENV PYTHPN


# local
export ATOMDB=~/.threeml/atomdb
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export MPLBACKEND='Agg'



# # VENV 
VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3 
export WORKON_HOME=~/.venv

source /usr/local/bin/virtualenvwrapper.sh


export CMDSTAN=/home/jburgess/.cmdstanpy/cmdstan/

bindkey -e
# End of lines configured by zsh-newuser-install


# HDF5 Sucks....
export HDF5_DISABLE_VERSION_CHECK=1
export HDF5_DIR=/usr/local/opt/hdf5



# # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
export FZF_DEFAULT_COMMAND='fd -HI -L --exclude .git --color=always'
export FZF_DEFAULT_OPTS='
  --ansi
  --info inline
  --height 40%
  --reverse
  --border
  --multi
  --color fg:#1FF088,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f
  --color info:#83a598,prompt:#bdae93,spinner:#fabd2f,pointer:#83a598,marker:#fe8019,header:#665c54
'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview '(bat --theme ansi-dark --color always {} 2> /dev/null || exa --tree --color=always {}) 2> /dev/null | head -200'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
export FZF_ALT_C_OPTS="--preview 'exa --tree --color=always {} | head -200'"



# added by travis gem
[ -f /Users/jburgess/.travis/travis.sh ] && source /Users/jburgess/.travis/travis.sh




source ~/.config/zsh/plugins.zsh 

source ~/.config/zsh/emacs.zsh 



#eval "$(direnv hook zsh)"




