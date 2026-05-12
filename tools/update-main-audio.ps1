param(
    [string]$AudioDir = "audio/main",
    [string]$JsonPath = "data/main/main.json",
    [switch]$RequireAll
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path ".").Path
$audioRoot = Join-Path $root $AudioDir
$jsonFile = Join-Path $root $JsonPath

if (-not (Test-Path -LiteralPath $audioRoot)) {
    throw "Audio folder not found: $AudioDir"
}

if (-not (Test-Path -LiteralPath $jsonFile)) {
    throw "JSON file not found: $JsonPath"
}

$mimeByExt = @{
    ".mp3"  = "audio/mp3"
    ".wav"  = "audio/wav"
    ".ogg"  = "audio/ogg"
    ".m4a"  = "audio/mp4"
    ".aac"  = "audio/aac"
    ".flac" = "audio/flac"
}

$existing = Get-Content -LiteralPath $jsonFile -Raw | ConvertFrom-Json
$updated = [ordered]@{}
$changed = 0
$missing = @()

for ($i = 0; $i -lt 32; $i++) {
    $key = "$i.mp3"
    $match = Get-ChildItem -LiteralPath $audioRoot -File |
        Where-Object { $_.BaseName -eq [string]$i -and $mimeByExt.ContainsKey($_.Extension.ToLowerInvariant()) } |
        Sort-Object Name |
        Select-Object -First 1

    if ($match) {
        $ext = $match.Extension.ToLowerInvariant()
        $bytes = [IO.File]::ReadAllBytes($match.FullName)
        $updated[$key] = "data:$($mimeByExt[$ext]);base64,$([Convert]::ToBase64String($bytes))"
        $changed++
    } elseif ($existing.PSObject.Properties.Name -contains $key) {
        $updated[$key] = $existing.$key
        $missing += $i
    } elseif ($RequireAll) {
        throw "Missing audio file for $key"
    }
}

if ($RequireAll -and $missing.Count -gt 0) {
    throw "Missing replacement files for: $($missing -join ', ')"
}

$json = $updated | ConvertTo-Json -Depth 2
Set-Content -LiteralPath $jsonFile -Value $json -Encoding UTF8

Write-Host "Updated $changed item(s) in $JsonPath"
if ($missing.Count -gt 0) {
    Write-Host "Kept existing audio for: $($missing -join ', ')"
}
