#!/usr/bin/env bash

#
#   BGDO: DO things in deferred way   
#

EXP_TIME=10

BASEDIR=~/bgdo/test/
#TMPFILE=`mktemp -t $BASEDIR`
MSGTMPL="Job Done."


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

    #TMPDIR=$(rand_filename $BASEDIR)
    TMPDIR=$(rand_filename)
    #echo $TMPDIR
    mkdir $TMPDIR
    TMPOUT="$TMPDIR/out"
    TMPERR="$TMPDIR/err"

    # Do the thing
    "$@" 1>$TMPOUT 2>$TMPERR

    # Notify
    local_notify $msg $

}

local_notify() {

    # local
    local msg=$1
    local urg=${2:-low}
    notify-send         \
        --icon=gtk-info \
        -t $EXP_TIME    \
        -u $urg         \
        -a "BGDO"       \
        "$MSGTMPL $msg"

   # remote
}

send_to_remote(){
    # Called by a remote ssh, ie listener, wanting to get messages from socket
    # Send to remote

    socat UNIX-RECV:~/tmp/alert_socket -

}

start_listening(){
    # Called by listener wanting to get msgs 
    # from server $1
    #
    # ref: https://unix.stackexchange.com/questions/194224

    # check params
    if [ "$#" -lt 2 ]; then
        echo "Need host to send msg"
        return
    fi;

    local hostname=$1

    ssh $hostname 'socat UNIX-RECV:~/tmp/alert_socket -' | \
    while read msg sev; do\
        local_notify "$msg" "$sev";
    done;

}

# Refs:
# *  https://unix.stackexchange.com/questions/194224/how-can-i-alert-on-completion-of-a-long-task-over-ssh

