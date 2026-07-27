#!/usr/bin/env bash
# Upload a folder to the server
set -euo pipefail

read -r -p "Enter folder path: " folderName

if [ ! -d "$folderName" ]; then
    echo "Folder not found: $folderName" >&2
    exit 1
fi

scp -P 8022 -i "$HOME/.ssh/id_ed25519" -r "$folderName" "u0_a209@192.168.1.12:~/storage/downloads/"