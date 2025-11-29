# DirectDLX_CLI - Direct Media Downloader
# Developer: Lakshan Rukantha
# Version: 1.0

# Display banner
function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "║              DirectDLX_CLI Media Downloader              ║" -ForegroundColor Green
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "║              Developer: Lakshan Rukantha                 ║" -ForegroundColor Yellow
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Create download directory if it doesn't exist
function Initialize-DownloadFolder {
    $downloadPath = Join-Path $PSScriptRoot "DirectDLX_CLI_Downloads"
    if (-not (Test-Path $downloadPath)) {
        New-Item -ItemType Directory -Path $downloadPath | Out-Null
        Write-Host "[INFO] Created download folder: $downloadPath" -ForegroundColor Green
    }
    return $downloadPath
}

# Get MIME type extension mapping
function Get-ExtensionFromMime {
    param([string]$mimeType)
    
    $mimeMap = @{
        'video/mp4' = '.mp4'
        'video/webm' = '.webm'
        'video/x-matroska' = '.mkv'
        'video/quicktime' = '.mov'
        'video/x-msvideo' = '.avi'
        'video/x-flv' = '.flv'
        'image/jpeg' = '.jpg'
        'image/png' = '.png'
        'image/gif' = '.gif'
        'image/webp' = '.webp'
        'image/bmp' = '.bmp'
        'image/svg+xml' = '.svg'
        'audio/mpeg' = '.mp3'
        'audio/wav' = '.wav'
        'audio/ogg' = '.ogg'
        'audio/webm' = '.weba'
        'audio/aac' = '.aac'
        'audio/flac' = '.flac'
        'application/pdf' = '.pdf'
        'application/zip' = '.zip'
        'application/x-rar-compressed' = '.rar'
        'text/plain' = '.txt'
    }
    
    return $mimeMap[$mimeType]
}

# Extract filename from URL or detect from MIME type
function Get-FileName {
    param(
        [string]$url,
        [string]$contentType = ""
    )
    
    $uri = [System.Uri]$url
    $filename = [System.IO.Path]::GetFileName($uri.LocalPath)
    
    # Check if filename has a valid extension
    if ([string]::IsNullOrEmpty($filename) -or $filename -notmatch '\.[a-zA-Z0-9]+$') {
        # Try to get extension from MIME type
        $extension = ""
        if (-not [string]::IsNullOrEmpty($contentType)) {
            $mimeType = $contentType -split ';' | Select-Object -First 1
            $mimeType = $mimeType.Trim()
            $extension = Get-ExtensionFromMime -mimeType $mimeType
        }
        
        if ([string]::IsNullOrEmpty($extension)) {
            $extension = ".bin"
        }
        
        $filename = "DirectDLX_CLI_$(Get-Date -Format 'yyyyMMdd_HHmmss')$extension"
    }
    
    return $filename
}

# Download file with progress
function Get-File {
    param(
        [string]$url,
        [string]$outputPath
    )
    
    try {
        $request = [System.Net.HttpWebRequest]::Create($url)
        $response = $request.GetResponse()
        $contentType = $response.ContentType
        $totalBytes = $response.ContentLength
        
        # Get proper filename with extension
        $detectedFilename = Get-FileName -url $url -contentType $contentType
        if ($detectedFilename -ne (Split-Path $outputPath -Leaf)) {
            $outputPath = Join-Path (Split-Path $outputPath -Parent) $detectedFilename
        }
        
        $filename = Split-Path $outputPath -Leaf
        
        Write-Host "`n[DOWNLOAD] Starting download: $filename" -ForegroundColor Cyan
        Write-Host "[URL] $url" -ForegroundColor Gray
        
        if ($totalBytes -gt 0) {
            Write-Host "[SIZE] $("{0:N2}" -f ($totalBytes / 1MB)) MB" -ForegroundColor Gray
        }
        
        Write-Host ""
        
        $responseStream = $response.GetResponseStream()
        $fileStream = [System.IO.File]::Create($outputPath)
        
        $buffer = New-Object byte[] 8192
        $totalRead = 0
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastUpdate = [DateTime]::Now
        $lastBytes = 0
        
        while (($read = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
            $totalRead += $read
            
            # Update progress every 100ms
            $now = [DateTime]::Now
            if (($now - $lastUpdate).TotalMilliseconds -ge 100) {
                $elapsed = $sw.Elapsed.TotalSeconds
                
                if ($elapsed -gt 0) {
                    # Calculate speed
                    $speed = ($totalRead - $lastBytes) / $elapsed
                    $lastBytes = $totalRead
                    $sw.Restart()
                    
                    # Format speed
                    if ($speed -gt 1MB) {
                        $speedStr = "{0:N2} MB/s" -f ($speed / 1MB)
                    } elseif ($speed -gt 1KB) {
                        $speedStr = "{0:N2} KB/s" -f ($speed / 1KB)
                    } else {
                        $speedStr = "{0:N0} B/s" -f $speed
                    }
                    
                    # Calculate percentage and progress bar
                    if ($totalBytes -gt 0) {
                        $percent = [math]::Floor(($totalRead / $totalBytes) * 100)
                        $barLength = 40
                        $filled = [math]::Floor(($percent / 100) * $barLength)
                        $bar = ("#" * $filled).PadRight($barLength, "-")
                        
                        $downloadedMB = $totalRead / 1MB
                        $totalMB = $totalBytes / 1MB
                        
                        Write-Host "`r[$bar] $percent% | $speedStr | $("{0:N2}" -f $downloadedMB)MB / $("{0:N2}" -f $totalMB)MB" -NoNewline -ForegroundColor Green
                    } else {
                        # Unknown size
                        $downloadedMB = $totalRead / 1MB
                        Write-Host "`r[Downloading...] $speedStr | $("{0:N2}" -f $downloadedMB)MB downloaded" -NoNewline -ForegroundColor Green
                    }
                }
                
                $lastUpdate = $now
            }
        }
        
        # Final update
        if ($totalBytes -gt 0) {
            $barLength = 40
            $bar = "#" * $barLength
            $totalMB = $totalBytes / 1MB
            Write-Host "`r[$bar] 100% | Complete | $("{0:N2}" -f $totalMB)MB / $("{0:N2}" -f $totalMB)MB" -ForegroundColor Green
        }
        
        $fileStream.Close()
        $responseStream.Close()
        $response.Close()
        
        Write-Host "`n[SUCCESS] Download completed!" -ForegroundColor Green
        Write-Host "[SAVED] $outputPath" -ForegroundColor Cyan
        
    }
    catch {
        Write-Host "`n`n[ERROR] Download failed: $($_.Exception.Message)" -ForegroundColor Red
        if (Test-Path $outputPath) {
            Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main script
Show-Banner

# Initialize download folder
$downloadFolder = Initialize-DownloadFolder

# Main loop
do {
    Write-Host "`nEnter the direct media URL (or 'exit' to quit):" -ForegroundColor Yellow
    $url = Read-Host "URL"
    
    if ($url -eq 'exit') {
        Write-Host "`nThank you for using DirectDLX_CLI!" -ForegroundColor Cyan
        break
    }
    
    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "[ERROR] URL cannot be empty!" -ForegroundColor Red
        continue
    }
    
    # Validate URL
    if ($url -notmatch '^https?://') {
        Write-Host "[ERROR] Invalid URL format. Must start with http:// or https://" -ForegroundColor Red
        continue
    }
    
    # Get initial filename (may be updated after detecting MIME type)
    $filename = Get-FileName -url $url
    $outputPath = Join-Path $downloadFolder $filename
    
    # Check if file already exists
    if (Test-Path $outputPath) {
        Write-Host "[WARNING] File already exists: $filename" -ForegroundColor Yellow
        $overwrite = Read-Host "Overwrite? (y/n)"
        if ($overwrite -ne 'y') {
            Write-Host "[SKIPPED] Download cancelled." -ForegroundColor Gray
            continue
        }
    }
    
    # Download the file
    Get-File -url $url -outputPath $outputPath
    
    Write-Host ""
    
} while ($true)