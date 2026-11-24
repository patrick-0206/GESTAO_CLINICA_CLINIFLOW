$port = 3000
# Pasta do próprio script (antes era um caminho fixo C:\Users\Escola\...)
$basePath = [System.IO.Path]::GetFullPath($PSScriptRoot)

$mime = @{
    ".html" = "text/html; charset=utf-8";  ".js"   = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8";   ".json" = "application/json; charset=utf-8"
    ".svg"  = "image/svg+xml";             ".png"  = "image/png"
    ".jpg"  = "image/jpeg";                ".jpeg" = "image/jpeg"
    ".webp" = "image/webp";                ".avif" = "image/avif"
    ".ico"  = "image/x-icon";              ".woff2" = "font/woff2"
}
# Arquivos estáticos (imagens, fontes, CSS, JS) podem ficar em cache; o HTML sempre revalida
$cacheLongo = ".js", ".css", ".svg", ".png", ".jpg", ".jpeg", ".webp", ".avif", ".woff2", ".ico"

function Send-Text($response, [int]$status, [string]$text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $response.StatusCode = $status
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
    Write-Output "SERVER_STARTED on http://localhost:$port/"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        try {
            $localPath = [System.Uri]::UnescapeDataString($context.Request.Url.LocalPath)
            if ($localPath -eq "/") { $localPath = "/index.html" }
            $filePath = [System.IO.Path]::GetFullPath((Join-Path $basePath $localPath.TrimStart('/')))

            # Bloqueia "../" para fora da pasta do projeto
            if (-not $filePath.StartsWith($basePath, [System.StringComparison]::OrdinalIgnoreCase)) {
                Send-Text $response 403 "403 Forbidden"
            }
            elseif (Test-Path -LiteralPath $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                if ($mime.ContainsKey($ext)) { $response.ContentType = $mime[$ext] }
                $response.Headers.Add("Cache-Control", $(if ($cacheLongo -contains $ext) { "public, max-age=86400" } else { "no-cache" }))
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            else {
                Send-Text $response 404 "404 Not Found"
            }
        }
        catch { Write-Warning $_ }   # um erro numa requisição não derruba o servidor
        finally { $response.Close() }
    }
}
catch {
    Write-Error $_
}
finally {
    $listener.Stop()
}
