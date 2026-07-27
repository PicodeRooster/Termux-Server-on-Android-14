#!/bin/bash
symbols=("/" "—" "\\" "|")

cooldown() {
    local seconds=$1
    local end=$((SECONDS + seconds))
    local i=0

    echo -n "Cooling down... "

    while [ $SECONDS -lt $end ]; do
        local symbol="${symbols[$((i % ${#symbols[@]}))]}"
        printf "\r Cooldown... %s (%ds remaining) " "$symbol" "$((end - SECONDS))"
        sleep 0.15
        ((i++))
    done
}

main() {
    echo "=== Running ==="
    pkg update && pkg upgrade;    #see update list and upgrade it
    termux-battery-status;        #check phone battery health
    df -h;                        #see available storage
    termux-wifi-connectioninfo    #see network connection information
    sleep 2;
    echo "Diagnostics complete."
    echo "=========================="

    cooldown 30
}

# Loop forever, running main() then cooling down before repeating
while true; do
    main
done
