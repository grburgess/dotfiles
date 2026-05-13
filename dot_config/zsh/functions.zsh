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
