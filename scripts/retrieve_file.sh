#!/bin/bash
#Install a file from the server
read -p "Enter file name (with quotes if it has spaces): " file_name
scp -P 8022 -i ~/.ssh/id_ed25519 u0_a209@192.168.1.12:~/storage/downloads/$file_name ~/Downloads/