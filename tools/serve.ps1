param(
    [int]$Port = 8000,
    [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$listener = [System.Net.HttpListener]::new()
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2" = "font/woff2"
    ".mp3"  = "audio/mpeg"
    ".wav"  = "audio/wav"
}

function Send-Text($response, [int]$statusCode, [string]$text) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($text)
    $response.StatusCode = $statusCode
    $response.ContentType = "text/plain; charset=utf-8"
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
}

Write-Host "Serving $rootPath at $prefix"
Write-Host "Press Ctrl+C to stop."
$listener.Start()

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart("/"))
        if ([string]::IsNullOrWhiteSpace($requestPath)) {
            $requestPath = "index.html"
        }

        $localPath = Join-Path $rootPath ($requestPath -replace "/", [IO.Path]::DirectorySeparatorChar)
        $resolved = $null
        if (Test-Path -LiteralPath $localPath -PathType Leaf) {
            $resolved = (Resolve-Path -LiteralPath $localPath).Path
        }

        if (-not $resolved -or -not $resolved.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
            Send-Text $context.Response 404 "Not found"
            $context.Response.Close()
            continue
        }

        $ext = [IO.Path]::GetExtension($resolved).ToLowerInvariant()
        $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
        $bytes = [IO.File]::ReadAllBytes($resolved)
        $context.Response.StatusCode = 200
        $context.Response.ContentType = $contentType
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $context.Response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
