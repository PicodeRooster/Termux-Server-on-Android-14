# Retrieve a file from the server
$fileName = Read-Host "Enter file name (spaces are fine, no quotes needed)"

$sshKey = Join-Path $HOME ".ssh\id_ed25519"
$destination = Join-Path $HOME "Downloads"

scp -P 8022 -i $sshKey "u0_a209@10.0.0.85:~/storage/$fileName" $destination
