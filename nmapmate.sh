#!/bin/bash

clear
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with root privileges."
    exit 1
fi

rlwrap -f commands/autocomplete.txt  ./main.sh
