# Standalone shell functions.

# SSH into a host and attach to (or create) a tmux session.
shmux() {
    if [ $# -eq 0 ]; then
        echo "Usage: shmux <username@hostname>"
        return 1
    fi
    local server=$1
    ssh -t "$server" 'tmux -CC new -A -s main'
}

# Periodically rsync a remote file to a local destination.
periodic_remote_rsync() {
    local remote_host="$1"
    local remote_source_file="$2"
    local local_destination="$3"
    local interval="$4"

    if [[ -z "$remote_host" || -z "$remote_source_file" || -z "$local_destination" || -z "$interval" ]]; then
        echo "Usage: periodic_remote_rsync <remote_host> <remote_source_file> <local_destination> <interval_in_seconds>"
        return 1
    fi

    while true; do
        rsync -av "$remote_host:$remote_source_file" "$local_destination"
        sleep "$interval"
    done
}

# Launch JupyterLab from the dedicated `jupyter` env regardless of current env.
# iTerm2: orange tab + Jupyter profile while running; resets on exit/Ctrl-C.
jlab() {
    emulate -L zsh
    setopt LOCAL_TRAPS

    if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        printf '\033]6;1;bg;red;brightness;230\a'
        printf '\033]6;1;bg;green;brightness;120\a'
        printf '\033]6;1;bg;blue;brightness;30\a'
        printf '\033]50;SetProfile=Jupyter\a'

        trap '
            printf "\033]6;1;bg;*;default\a"
            printf "\033]50;SetProfile=Default\a"
        ' EXIT INT
    fi

    # Direct binary call avoids `mamba run`'s `exec --` bash-builtin bug (mamba 2.5.x).
    /opt/homebrew/Caskroom/mambaforge/base/envs/jupyter/bin/jupyter lab "$@"
}
