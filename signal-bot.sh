#!/bin/bash

SIGNAL=1
GROUP=""
MESSAGE=""
MFILE=""
GFILE=""
DOW=$(date +%A)
NUMBER=0
LINE_NUMBER=0

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

    case $DOW in
        Monday)
            echo "Monday"
            LINE_NUMBER=$(echo "scale=1; $RANDOM / 32767 * (120 - 1) + 1" | bc | cut -d "." -f 1)
            MESSAGE=$(sed -n "${LINE_NUMBER}p" $MFILE) 
            echo "$LINE_NUMBER is $MESSAGE"
            ;; 
        Tuesday)
            echo "Tuesday"
            LINE_NUMBER=$(echo "scale=1; $RANDOM / 32767 * (242 - 122) + 122" | bc | cut -d "." -f 1)
            MESSAGE=$(sed -n "${LINE_NUMBER}p" $MFILE) 
            echo "$LINE_NUMBER is $MESSAGE"
            ;; 
        Wednesday)
            echo "Wednesday"
            LINE_NUMBER=$(echo "scale=1; $RANDOM / 32767 * (363 - 243) + 243" | bc | cut -d "." -f 1)
            MESSAGE=$(sed -n "${LINE_NUMBER}p" $MFILE) 
            echo "$LINE_NUMBER is $MESSAGE"
            ;; 
        Thursday)
            echo "Thursday"
            LINE_NUMBER=$(echo "scale=1; $RANDOM / 32767 * (484 - 364) + 364" | bc | cut -d "." -f 1)
            MESSAGE=$(sed -n "${LINE_NUMBER}p" $MFILE) 
            echo "$LINE_NUMBER is $MESSAGE"
            ;; 
        Friday)
            echo "Friday"
            LINE_NUMBER=$(echo "scale=1; $RANDOM / 32767 * (605 - 485) + 485" | bc | cut -d "." -f 1)
            MESSAGE=$(sed -n "${LINE_NUMBER}p" $MFILE) 
            echo "$LINE_NUMBER is $MESSAGE"
            ;; 
    esac
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
    sleep 0.5

    # SEND TAB AND ENTER TO SELECT GROUP
    xdotool key --window "$WINDOWID" "Tab"
    sleep 0.5
    xdotool key --window "$WINDOWID" "Return"
    sleep 0.5
    xdotool mousemove --sync 456 639

    # TYPE IN SMILEY FACE
    xdotool type --window "$WINDOWID" "$2"

    # SEND EMOJI
    xdotool key --window "$WINDOWID" "Return"
    sleep 11
    echo "signal bot out!"

    # KILL SIGNAL
    kill -9 "$SIGNALPID"
}


function issignalrunning() {
    LOGTIME=$(grep "https://storage.signal.org/v1/storage/manifest/version/" ~/.config/Signal/logs/app.log | tail -1 | cut -d ":" -f 3-4 | sed 's/"//g')
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
        sleep 1
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
        sendmessage "$GROUP" "$MESSAGE"
    fi
}


# START THE PROGRAM
main
