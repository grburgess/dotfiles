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

zinit ice blockf
zinit light zsh-users/zsh-completions

zinit load zsh-users/zsh-autosuggestions
zinit load zdharma/fast-syntax-highlighting

source ~/.config/zsh/highlight.zsh

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
#zinit ice lucid pick'spaceship.zsh' compile'{lib/*,sections/*,tests/*.zsh}'
#zinit light denysdovhan/spaceship-prompt
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure
zstyle :prompt:pure:prompt:success color '#00FFA2'
zstyle :prompt:pure:virtualenv color '#BA00FF'


zinit wait lucid for \
      is-snippet "${ZDOTDIR}/alias.zsh"

