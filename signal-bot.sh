#!/bin/bash

SIGNAL=1
GROUP=""
MESSAGE=""
MFILE=""
GFILE=""
SIGNALEMOJI=":signal_strength:"
ROBOTEMOJI=":robot_face:"


function usage() {
    echo    
    echo "Usage: $0 [ -g GROUP FILE PATH ] [ -f MESSAGE FILE PATH ]" 2>&1
    echo
    exit 1
}


while getopts ":g:f:h" OPTIONS; do
    case "${OPTIONS}" in
        g)
            GFILE=${OPTARG}
            ;;
        f)
            MFILE=${OPTARG}
            ;;
        h)
            usage
            ;;
    esac
done


function getgroup() {
    GROUP=$(grep "GROUP" $GFILE | cut -d "=" -f 2 | xargs)
}


function getmessage() {
    NUMBER=$(wc -l $MFILE | cut -d " " -f 1)
    DOW=$(date +%u) #$(date +%A)
    LINENUMBER=0
    MAXRANDOM=32767
    MAX=0
    MIN=0

    case $DOW in
        1)
            echo "Monday"
            MAX=120
            MIN=1
            ;; 
        2)
            echo "Tuesday"
            MAX=242
            MIN=122
            ;; 
        3)
            echo "Wednesday"
            MAX=363
            MIN=243
            ;; 
        4)
            echo "Thursday"
            MAX=484
            MIN=364
            ;; 
        5)
            echo "Friday"
            MAX=605
            MIN=485
            ;; 
    esac

    LINENUMBER=$(echo "scale=1; $RANDOM / $MAXRANDOM * ($MAX - $MIN) + $MIN" | bc | cut -d "." -f 1)
    VIRGIN=$(sed -n "${LINENUMBER}p" $MFILE | grep -Eo "^[0-1]{1}")

    while [[ "$VIRGIN" -eq "1" ]]; do
        if [[ "$LINENUMBER" -eq "$NUMBER" ]]; then
            LINENUMBER=1
        fi

        LINENUMBER=$(( LINENUMBER + 1 ))

        VIRGIN=$(sed -n "${LINENUMBER}p" $MFILE | grep -Eo "^[0-1]{1}")
    done

    MESSAGE=$(sed -n "${LINENUMBER}p" $MFILE | grep -Eo ":{1}[0-9a-z_]*:{1}")
    TEMPMSG=$(sed -n "${LINENUMBER}p" $MFILE)
    REPL="${TEMPMSG:0:2}"
    sed "$LINENUMBER s/^$REPL/1:/" $MFILE > "$MFILE.bak"
    cp "$MFILE.bak" "$MFILE"
    echo "$LINENUMBER is $MESSAGE"
}


function sendmessage() {
    # GRAB SIGNAL PID
    SIGNALPID=$(ps -aux | grep "signal-desktop" | head -1 | grep -Eo "matthew\s+[0-9]+" | grep -Eo "[0-9]+")
    echo "Signal PID: $SIGNALPID"

    # GRAB WINDOWID OF SIGNAL APP
    WINDOWID=$(xdotool search -all --pid "$SIGNALPID" | tail -1)
    echo "Signal WINDOWID: $WINDOWID"

    # ACTIVATE SIGNAL WINDOW
    xdotool windowmove "$WINDOWID" 0 0
    xdotool windowactivate --sync "$WINDOWID"
    xdotool mousemove --sync 120 150 
    xdotool click --window "$WINDOWID" 1 

    # SEARCH FOR GROUP
    xdotool type "$1"
    sleep 1

    # SEND TAB AND ENTER TO SELECT GROUP
    xdotool key --window "$WINDOWID" "Tab"
    sleep 1
    xdotool key --window "$WINDOWID" "Return"
    sleep 1
    xdotool mousemove --sync 456 639

    # TYPE IN SMILEY FACE
    xdotool type --window "$WINDOWID" "$2"
    sleep 1
    xdotool type --window "$WINDOWID" "  -  "
    sleep 1
    xdotool type --window "$WINDOWID" "$SIGNALEMOJI"
    sleep 1
    xdotool type --window "$WINDOWID" "$ROBOTEMOJI"
    sleep 1

    # SEND EMOJI
    xdotool key --window "$WINDOWID" "Return"
    sleep 11

    # KILL SIGNAL 
    echo "signal bot out!"
    kill -9 "$SIGNALPID"
}


function issignalrunning() {
    
    LOGTIME=$(grep "App loaded" ~/.config/Signal/logs/main.log | tail -1 | cut -d ":" -f 3-4 | sed 's/"//g')
    CURRENTTIME=$(date -u +"%Y-%m-%dT%H:%M")
    
    if [[ "$LOGTIME" == "$CURRENTTIME" ]]; then
        SIGNAL=0
    fi
}


function main() {
    # GREET THY MASTER
    printf "Good morning. I am signal bot. I am here to serve you ...\n\n"

    # GET GROUP TO SEND TO
    getgroup

    # SEED RANDOM NUMBER GENERATOR
    SEED=$(date +%s%N | cut -b 16-19)
    RANDOM=$SEED

    # GET MESSAGE TO SEND
    getmessage

    # CHECK IF SIGNAL IS RUNNING
    ps -aux | grep "signal-desktop" | grep -v grep  >/dev/null

    if [[ "$?" -eq 0 ]]; then
        echo "Signal is running ... I will send this $MESSAGE to $GROUP"
        sleep 3
        sendmessage "$GROUP" "$MESSAGE"
    else
        echo -ne "Signal is not running."
        echo -ne " Starting."
        gnome-terminal -- bash -c "signal-desktop" &
        while [[ "$SIGNAL" -eq 1 ]]; do 
            issignalrunning
            echo -ne "."
            sleep 1
        done
        echo -e ".\nSignal is running ... sleeping until 0449"
        sleep 10

        ## THIS BLOCK IS NEW, IF IT BREAKS TOMORROW REMOVE
        CURRENTTIME=$(date +%M)
        STOPTIME="49"
        while [[ "$CURRENTTIME" < "$STOPTIME" ]]; do
            sleep 15
            echo "Waiting ..."
            CURRENTTIME=$(date +%M)
        done     
        ## END BLOCK

        echo "I will send this $MESSAGE to $GROUP at $(date)"
        sendmessage "$GROUP" "$MESSAGE"
    fi
}


# START THE PROGRAM
main
