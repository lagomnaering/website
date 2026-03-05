$port = 3000
$root = $PSScriptRoot
$projectRoot = Split-Path $root -Parent

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Lagom Naering dev server running at http://localhost:$port"

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webp" = "image/webp"
    ".gif"  = "image/gif"
    ".pdf"  = "application/pdf"
}

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    $urlPath = $req.Url.LocalPath
    if ($urlPath -eq "/") { $urlPath = "/index.html" }

    # Resolve path — allow serving from website/ and one level up (for images)
    $candidate = Join-Path $root $urlPath.TrimStart("/").Replace("/", "\")
    $candidate = [System.IO.Path]::GetFullPath($candidate)

    if (-not $candidate.StartsWith($projectRoot)) {
        $res.StatusCode = 403
        $res.Close()
        continue
    }

    if (Test-Path $candidate -PathType Leaf) {
        $ext  = [System.IO.Path]::GetExtension($candidate).ToLower()
        $mime = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { "application/octet-stream" }
        $bytes = [System.IO.File]::ReadAllBytes($candidate)
        $res.ContentType   = $mime
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $res.StatusCode = 404
        $body = [System.Text.Encoding]::UTF8.GetBytes("Not found: $urlPath")
        $res.OutputStream.Write($body, 0, $body.Length)
    }
    $res.Close()
}
