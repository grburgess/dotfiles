### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

zinit ice svn
zinit snippet OMZ::plugins/macos

zinit ice blockf
zinit light zsh-users/zsh-completions

zinit load zsh-users/zsh-autosuggestions
zinit load zdharma-continuum/fast-syntax-highlighting

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

#zinit is-snippet for OMZ::



zinit is-snippet for OMZ::plugins/git/git.plugin.zsh
zinit is-snippet for OMZ::plugins/pip/pip.plugin.zsh
zinit is-snippet for OMZ::plugins/iterm2/iterm2.plugin.zsh
zinit is-snippet for OMZ::plugins/common-aliases/common-aliases.plugin.zsh


#zinit is-snippet for OMZ::plugins/emacs/emacs.plugin.zsh
zinit is-snippet for OMZ::plugins/thefuck/thefuck.plugin.zsh
zinit is-snippet for OMZ::plugins/history/history.plugin.zsh
zinit is-snippet for OMZ::plugins/extract/extract.plugin.zsh
# zinit atload"zpcompinit" lucid as"completion" for OMZ::plugins/docker/_docker

# Plugins
zinit for rupa/z
zinit for changyuheng/fz
zinit for changyuheng/zsh-interactive-cd
zinit wait lucid for zdharma-continuum/fast-syntax-highlighting
zinit pick"shell/completion.zsh" src"shell/key-bindings.zsh" for junegunn/fzf

zinit for iam4x/zsh-iterm-touchbar
zinit for bernardop/iterm-tab-color-oh-my-zsh

# it also works with turbo mode:
zinit ice wait lucid

zinit load redxtech/zsh-fzf-utils


#zinit load tysonwolker/iterm-tab-colors

zinit light Aloxaf/fzf-tab

zinit load wfxr/forgit

# zinit load leophys/zsh-plugin-fzf-finder


# Spaceship theme
#zinit ice lucid pick'spaceship.zsh' compile'{lib/*,sections/*,tests/*.zsh}'
#zinit light denysdovhan/spaceship-prompt
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure
zstyle :prompt:pure:prompt:success color '#00FF9A'
zstyle :prompt:pure:virtualenv color '#FF00C9'


zinit wait lucid for \
      is-snippet "${ZDOTDIR}/alias.zsh"

