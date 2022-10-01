
export EMACS_PLUGIN_LAUNCHER="${ZDOTDIR}/emacsclient.sh"

# set EDITOR if not already defined.
export EDITOR="${EDITOR:-${EMACS_PLUGIN_LAUNCHER}}"

alias emacs="$EMACS_PLUGIN_LAUNCHER --no-wait -c"
alias e=emacs
# open terminal emacsclient
alias te="$EMACS_PLUGIN_LAUNCHER -nw"

# same than M-x eval but from outside Emacs.
alias eeval="$EMACS_PLUGIN_LAUNCHER --eval"
# create a new X frame
alias eframe='emacsclient --alternate-editor "" --create-frame'

alias ec=eframe

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
