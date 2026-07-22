# Upload a folder to the server
$folderName = Read-Host "Enter folder path"

if (-not (Test-Path -LiteralPath $folderName -PathType Container)) {
    Write-Error "Folder not found: $folderName"
    exit 1
}

scp -P 8022 -i "$HOME\.ssh\id_ed25519" -r $folderName "u0_a209@10.0.85:~/storage/downloads/"