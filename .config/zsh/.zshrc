#  _____    _
# |__  /___| |__  _ __ ___
#   / // __| '_ \| '__/ __|
#  / /_\__ \ | | | | | (__
# /____|___/_| |_|_|  \___|


[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return


export PATH="/usr/local/sbin:/usr/local/bin:${PATH}"
export PATH="/usr/local/lib/ruby/gems/bin:/usr/local/lib/ruby/gems/2.6.0/bin:/Library/TeX/texbin:/opt/X11/bin:${PATH}"

SPACESHIP_PROMPT_ORDER=(
    time
    user
    host
    dir
    git
    venv
    pyenv
    line_sep
    char
)
# PROMPT
SPACESHIP_CHAR_SYMBOL=" "
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=true
SPACESHIP_PROMPT_PREFIXES_SHOW=true
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_PROMPT_DEFAULT_PREFIX="via "
SPACESHIP_PROMPT_DEFAULT_SUFFIX=" "
SPACESHIP_CHAR_COLOR_SUCCESS='049'



# TIME
SPACESHIP_TIME_SHOW=false
SPACESHIP_TIME_PREFIX="at "
SPACESHIP_TIME_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_TIME_FORMAT=false
SPACESHIP_TIME_12HR=false
SPACESHIP_TIME_COLOR="yellow"
# USER
SPACESHIP_USER_SHOW=true
SPACESHIP_USER_PREFIX="with "
SPACESHIP_USER_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_USER_COLOR="yellow"
SPACESHIP_USER_COLOR_ROOT="red"
# HOST
SPACESHIP_HOST_SHOW=true
SPACESHIP_HOST_PREFIX="at "
SPACESHIP_HOST_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_HOST_COLOR="green"
# DIR
SPACESHIP_DIR_SHOW=true
SPACESHIP_DIR_PREFIX="in "
SPACESHIP_DIR_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_DIR_TRUNC=3
SPACESHIP_DIR_COLOR="098"
# GIT
SPACESHIP_GIT_SHOW=true
SPACESHIP_GIT_PREFIX="on "
SPACESHIP_GIT_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_GIT_SYMBOL=" "
# GIT BRANCH
SPACESHIP_GIT_BRANCH_SHOW=true
SPACESHIP_GIT_BRANCH_PREFIX=" "
SPACESHIP_GIT_BRANCH_SUFFIX=""
SPACESHIP_GIT_BRANCH_COLOR="204"
# GIT STATUS
SPACESHIP_GIT_STATUS_SHOW=true
SPACESHIP_GIT_STATUS_PREFIX=" ["
SPACESHIP_GIT_STATUS_SUFFIX="]"
SPACESHIP_GIT_STATUS_COLOR="red"
SPACESHIP_GIT_STATUS_UNTRACKED="?"
SPACESHIP_GIT_STATUS_ADDED="+"
SPACESHIP_GIT_STATUS_MODIFIED="!"
SPACESHIP_GIT_STATUS_RENAMED="»"
SPACESHIP_GIT_STATUS_DELETED="✘"
SPACESHIP_GIT_STATUS_STASHED="$"
SPACESHIP_GIT_STATUS_UNMERGED="="
SPACESHIP_GIT_STATUS_AHEAD="⇡"
SPACESHIP_GIT_STATUS_BEHIND="⇣"
SPACESHIP_GIT_STATUS_DIVERGED="⇕"


# DOCKER
SPACESHIP_DOCKER_SHOW=true
SPACESHIP_DOCKER_PREFIX="on "
SPACESHIP_DOCKER_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_DOCKER_SYMBOL="🐳 "
SPACESHIP_DOCKER_COLOR="cyan"
# VENV
SPACESHIP_VENV_SHOW=true
SPACESHIP_VENV_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"
SPACESHIP_VENV_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_VENV_COLOR="228"

# PYENV
SPACESHIP_PYENV_SHOW=true
SPACESHIP_PYENV_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"
SPACESHIP_PYENV_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"
SPACESHIP_PYENV_SYMBOL="🐍 "
SPACESHIP_PYENV_COLOR="yellow"


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
VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
export WORKON_HOME=~/.environs

source /usr/local/bin/virtualenvwrapper.sh

export PATH=/usr/local/opt/python/libexec/bin:$PATH


# local
export ATOMDB=~/.threeml/atomdb
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export MPLBACKEND='Agg'



export CMDSTAN=/Users/jburgess/.cmdstanpy/cmdstan

bindkey -e
# End of lines configured by zsh-newuser-install

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

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



#source $(dirname $(gem which colorls))/tab_complete.sh

# added by travis gem
[ -f /Users/jburgess/.travis/travis.sh ] && source /Users/jburgess/.travis/travis.sh



eval "$(direnv hook zsh)"

### Added by Zinit's installer
if [[ ! -f $HOME/.config/zsh/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.config/zsh/.zinit" && command chmod g-rwX "$HOME/.config/zsh/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.config/zsh/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.config/zsh/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk
zinit ice svn
zinit snippet OMZ::plugins/osx

# zinit ice svn lucid
# zinit snippet OMZ::plugins/pip

# zinit ice svn lucid
# zinit snippet OMZ::plugins/emacs

# zinit ice svn lucid
# zinit snippet OMZ::plugins/iterm2

# zinit ice svn lucid
# zinit snippet OMZ::plugins/virtualenv


zinit load zsh-users/zsh-autosuggestions
zinit load zdharma/fast-syntax-highlighting

# Binaries
zinit from"gh-r" as"program" for junegunn/fzf-bin
zinit from"gh-r" as"program" mv"exa-* -> exa" for ogham/exa
zinit from"gh-r" as"program" mv"jq-* -> jq" for stedolan/jq
zinit from"gh-r" as"program" pick"*/rg" for BurntSushi/ripgrep
zinit from"gh-r" as"program" pick"*/bat" for @sharkdp/bat
# zinit from"gh-r" as"program" pick"*/**/terminal-notifier" for julienXX/terminal-notifier

# Oh-My-Zsh snippets
zinit is-snippet for OMZ::lib/directories.zsh
zinit is-snippet for OMZ::lib/theme-and-appearance.zsh
zinit is-snippet for OMZ::lib/key-bindings.zsh
zinit is-snippet for OMZ::lib/history.zsh
zinit is-snippet for OMZ::lib/git.zsh
zinit is-snippet for OMZ::plugins/git/git.plugin.zsh
zinit is-snippet for OMZ::plugins/pip/pip.plugin.zsh
zinit is-snippet for OMZ::plugins/iterm2/iterm2.plugin.zsh
zinit is-snippet for OMZ::plugins/virtualenv/virtualenv.plugin.zsh
zinit is-snippet for OMZ::plugins/emacs/emacs.plugin.zsh
zinit is-snippet for OMZ::plugins/thefuck/thefuck.plugin.zsh
zinit is-snippet for OMZ::plugins/history/history.plugin.zsh
zinit is-snippet for OMZ::plugins/extract/extract.plugin.zsh
# zinit atload"zpcompinit" lucid as"completion" for OMZ::plugins/docker/_docker

# Plugins
zinit for rupa/z
zinit for changyuheng/fz
zinit for changyuheng/zsh-interactive-cd
zinit wait lucid for zdharma/fast-syntax-highlighting
zinit pick"shell/completion.zsh" src"shell/key-bindings.zsh" for junegunn/fzf

# Spaceship theme
zinit ice lucid pick'spaceship.zsh' compile'{lib/*,sections/*,tests/*.zsh}'
zinit light denysdovhan/spaceship-prompt

zinit wait lucid for \
      is-snippet "${ZDOTDIR}/alias.zsh"



if "$ZSH/tools/require_tool.sh" emacsclient 24 2>/dev/null ; then
    export EMACS_PLUGIN_LAUNCHER="$ZSH/plugins/emacs/emacsclient.sh"

    # set EDITOR if not already defined.
    export EDITOR="${EDITOR:-${EMACS_PLUGIN_LAUNCHER}}"

    alias emacs="$EMACS_PLUGIN_LAUNCHER --no-wait"
    alias e=emacs
    # open terminal emacsclient
    alias te="$EMACS_PLUGIN_LAUNCHER -nw"

    # same than M-x eval but from outside Emacs.
    alias eeval="$EMACS_PLUGIN_LAUNCHER --eval"
    # create a new X frame
    alias eframe='emacsclient --alternate-editor "" --create-frame'


    # Write to standard output the path to the file
    # opened in the current buffer.
    function efile {
        local cmd="(buffer-file-name (window-buffer))"
        "$EMACS_PLUGIN_LAUNCHER" --eval "$cmd" | tr -d \"
    }

    # Write to standard output the directory of the file
    # opened in the the current buffer
    function ecd {
        local cmd="(let ((buf-name (buffer-file-name (window-buffer))))
                     (if buf-name (file-name-directory buf-name)))"

        local dir="$($EMACS_PLUGIN_LAUNCHER --eval $cmd | tr -d \")"
        if [ -n "$dir" ] ;then
            echo "$dir"
        else
            echo "can not deduce current buffer filename." >/dev/stderr
            return 1
        fi
    }
fi


