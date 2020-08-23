#!/usr/bin/env bash

#
#   BGDO: DO things in deferred way   
#

# GLOBALS
EXP_TIME=10
BASEDIR=~/bgdo/test/
#TMPFILE=`mktemp -t $BASEDIR`
MSGTMPL="Alert:\n\n\tResults in Dir: "
PIPE=~/tmp/alert_socket

# reqs
NOTIFY_SEND=$(command -v notify-send)


# UTILS
rand_string() {
    # Generate random string of $1 length

    local len=${1:-6}
    cat /dev/urandom | tr -cd 'a-f0-9' | head -c $len
}

rand_filename() {
    # Generate a filename of variable length $2 with path prefixed $1

    local prefix=${1:-`pwd`}
    local len=${2:-6}

    out="$prefix/$(rand_string $len)"
    echo $out 
}

bgdo() {
    # Do things in the background

    # create out location
    # TODO: make only if successfull?
    #       or
    #       make in /tmp and then mv it 
    #           (but prone to fail if cmd break in middle)

    # Create where to place results
    TMPDIR=$(rand_filename $BASEDIR)
    mkdir $TMPDIR
    TMPOUT="$TMPDIR/out"
    TMPERR="$TMPDIR/err"

    # Do the thing
    "$@" 1>$TMPOUT 2>$TMPERR

    # Note Completion
    _alert_local "low" "$MSGTMPL : $TMPDIR"
    _alert_remote "low" "$MSGTMPL : $TMPDIR"
}

_alert_remote () {
    echo "$@" > $PIPE
}

_alert_local() {
    # Wrapper for triggering machine-local alert

    # vars
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <sev> <msg>"
        return
    fi 

    local urg=$1
    local msg=${@:2}

    if [ -x "$NOTIFY_SEND" ]; then
        notify-send         \
            --icon=gtk-info \
            -u $1         \
            "BGDO"          \
            "$msg"
    fi;
}

start_listening(){
    # Called by listener wanting to get msgs from server $1
    #   called always from local to host
    #
    # ref: https://unix.stackexchange.com/questions/194224

    # check params
    if [ "$#" -lt 1 ]; then
        echo "Need host to send msg"
        return
    fi;

    local hostname=$1

    # TODO: add notification user on systems
    ssh $hostname 'while cat '"$PIPE"'; do : ; done;' | \
    while read sev msg; do\
        #echo "$sev" "$msg";
        _alert_local "$sev" "$msg";
    done;

}

# Refs:
# *  https://unix.stackexchange.com/questions/194224/how-can-i-alert-on-completion-of-a-long-task-over-ssh

