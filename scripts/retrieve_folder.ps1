# Install a folder from the server
$folderName = Read-Host "Enter folder name"
scp -r -P 8022 -i "$HOME\.ssh\id_ed25519" "u0_a209@10.0.0.85:~/storage/downloads/$folderName" "$HOME\Downloads\"
