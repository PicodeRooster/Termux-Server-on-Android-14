#!/bin/bash
#Install a folder from the server
read -p "Enter folder name (with quotes if it has spaces): " folder_name
scp -r -P 8022 -i ~/.ssh/id_ed25519 u0_a209@192.168.1.12:~/storage/downloads/$folder_name ~/Downloads/