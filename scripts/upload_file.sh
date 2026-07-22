#!/bin/bash
# Upload a file to the server
read -p "Enter file path and name: " file_name
scp -P 8022 -i ~/.ssh/id_ed25519 "$file_name" u0_a209@10.0.0.85:~/storage/downloads/