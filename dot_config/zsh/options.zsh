# Shell options, history, keybindings, prompt symbol.

# Completion behavior (consumed by plugins / OMZ snippets).
ZSH_DISABLE_COMPFIX='true'
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# History.
HISTFILE="${HOME}/.histfile"
HISTSIZE=100000
SAVEHIST=100000

setopt appendhistory autocd extendedglob sharehistory
setopt hist_ignore_all_dups hist_ignore_space hist_reduce_blanks hist_verify
unsetopt notify

# Emacs keybindings.
bindkey -e

# Prompt symbol for pure prompt.
export PURE_PROMPT_SYMBOL=⚥
