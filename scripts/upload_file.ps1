# Upload a file to the server
$fileName = Read-Host "Enter file path and name"

if (-not (Test-Path -LiteralPath $fileName)) {
    Write-Error "File not found: $fileName"
    exit 1
}

scp -P 8022 -i "$HOME\.ssh\id_ed25519" $fileName "u0_a209@10.0.0.85:~/storage/downloads/"
