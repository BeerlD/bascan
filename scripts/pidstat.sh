#!/bin/bash

source ././lib/colors.sh

PID=$1
LOG_FILE=$2

while ps -p $PID > /dev/null; do
    pidstat -h -p $PID 2 1 | awk -v cyan="$CYAN" -v nc="$NC" 'NR==4 {print "UP: " cyan $6 nc " KB/sec DOWN: " cyan $5 nc " KB/sec"}' > "$LOG_FILE"
    cp "$LOG_FILE" "$LOG_FILE.bak"
    sleep 2
done

rm "$LOG_FILE" "$LOG_FILE.bak" 1>/dev/null
