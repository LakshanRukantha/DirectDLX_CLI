# DirectDLX_CLI - Direct Media Downloader
# Developer: Lakshan Rukantha
# Version: 2.0

function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DirectDLX_CLI - Direct Media Downloader v2.0             ║" -ForegroundColor Green
    Write-Host "║              Developer: Lakshan Rukantha                 ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

function Get-MimeExtension {
    param([string]$mime)
    $map = @{
        'video/mp4'='.mp4';'video/webm'='.webm';'image/jpeg'='.jpg';'image/png'='.png'
        'image/gif'='.gif';'audio/mpeg'='.mp3';'audio/wav'='.wav';'application/pdf'='.pdf'
    }
    return $map[$mime.Split(';')[0].Trim()]
}

function Get-File {
    param([string]$url, [string]$partFile)
    
    try {
        $startByte = if (Test-Path $partFile) { (Get-Item $partFile).Length } else { 0 }
        
        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.Timeout = 30000
        if ($startByte -gt 0) { 
            $request.AddRange($startByte)
            Write-Host "[RESUME] From $([math]::Round($startByte/1MB, 2)) MB`n" -ForegroundColor Yellow
        }
        
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength + $startByte
        $ext = Get-MimeExtension $response.ContentType
        
        # Detect filename with extension
        if ($partFile -notmatch '\.\w+\.part$' -and $ext) {
            $newPartFile = $partFile -replace '\.part$', "$ext.part"
            if ($startByte -gt 0 -and (Test-Path $partFile)) { Move-Item $partFile $newPartFile -Force }
            $partFile = $newPartFile
        }
        
        $fileName = Split-Path $partFile -Leaf
        $fileName = $fileName -replace '\.part$', ''
        
        Write-Host "[DOWNLOAD] $fileName" -ForegroundColor Cyan
        Write-Host "[SIZE] $([math]::Round($totalBytes/1MB, 2)) MB`n" -ForegroundColor Gray
        
        $stream = $response.GetResponseStream()
        $fileMode = if ($startByte -gt 0) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }
        $file = [System.IO.File]::Open($partFile, $fileMode)
        
        $buffer = New-Object byte[] 65536
        $totalRead = $startByte
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastBytes = $totalRead
        $lastTime = [DateTime]::Now
        
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $file.Write($buffer, 0, $read)
            $totalRead += $read
            
            if (([DateTime]::Now - $lastTime).TotalMilliseconds -ge 200) {
                $speed = ($totalRead - $lastBytes) / $sw.Elapsed.TotalSeconds
                $speedStr = if ($speed -gt 1MB) { "$([math]::Round($speed/1MB, 2)) MB/s" } else { "$([math]::Round($speed/1KB, 2)) KB/s" }
                $percent = [math]::Floor(($totalRead / $totalBytes) * 100)
                $bar = ("#" * [math]::Floor($percent * 40 / 100)).PadRight(40, "-")
                Write-Host "`r[$bar] $percent% | $speedStr | $([math]::Round($totalRead/1MB, 2))MB / $([math]::Round($totalBytes/1MB, 2))MB" -NoNewline -ForegroundColor Green
                $lastBytes = $totalRead
                $lastTime = [DateTime]::Now
                $sw.Restart()
            }
        }
        
        $file.Close(); $stream.Close(); $response.Close()
        
        $finalFile = $partFile -replace '\.part$', ''
        if (Test-Path $finalFile) { Remove-Item $finalFile -Force }
        Move-Item $partFile $finalFile -Force
        
        Write-Host "`n[SUCCESS] Download completed!`n[SAVED] $finalFile`n" -ForegroundColor Green
        return $true
    }
    catch {
        if ($file) { try { $file.Close() } catch {} }
        if ($stream) { try { $stream.Close() } catch {} }
        if ($response) { try { $response.Close() } catch {} }
        
        $errMsg = $_.Exception.Message
        $shortErr = if ($errMsg -match "No such host|Unable to resolve") { "No internet" }
                    elseif ($errMsg -match "timeout|did not properly respond|Unable to read") { "Connection lost" }
                    elseif ($errMsg -match "403") { "Access denied" }
                    elseif ($errMsg -match "404") { "File not found" }
                    else { "Download interrupted" }
        
        Write-Host "`n[ERROR] $shortErr" -ForegroundColor Red
        
        if (Test-Path $partFile) {
            $size = [math]::Round((Get-Item $partFile).Length/1MB, 2)
            Write-Host "[INFO] Saved: $size MB`n" -ForegroundColor Yellow
            
            $retry = Read-Host "Resume? (y/n)"
            if ($retry -eq 'y') {
                Write-Host ""
                return Get-File -url $url -partFile $partFile
            }
        }
        return $false
    }
}

# Main
Show-Banner

$downloadFolder = Join-Path $PSScriptRoot "DirectDLX_CLI_Downloads"
if (-not (Test-Path $downloadFolder)) { 
    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
    Write-Host "[INFO] Created: $downloadFolder`n" -ForegroundColor Green
}

while ($true) {
    Write-Host "Enter URL (or 'exit'):" -ForegroundColor Yellow
    $url = Read-Host "URL"
    
    if ($url -eq 'exit') { 
        Write-Host "`nThank you for using DirectDLX_CLI!" -ForegroundColor Cyan
        break 
    }
    
    if ([string]::IsNullOrWhiteSpace($url)) { 
        Write-Host "[ERROR] URL required!`n" -ForegroundColor Red
        continue 
    }
    
    if ($url -notmatch '^https?://') { 
        Write-Host "[ERROR] Invalid URL`n" -ForegroundColor Red
        continue 
    }
    
    # Check for existing partial files
    $partials = Get-ChildItem "$downloadFolder\*.part" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    if ($partials) {
        $latest = $partials[0]
        $size = [math]::Round($latest.Length/1MB, 2)
        Write-Host "[INFO] Found: $($latest.Name) ($size MB)" -ForegroundColor Yellow
        
        $resume = Read-Host "Resume this? (y/n)"
        if ($resume -eq 'y') {
            $success = Get-File -url $url -partFile $latest.FullName
            
            # Cleanup old partials
            if ($success -and $partials.Count -gt 1) {
                Write-Host "[CLEANUP] Removing old files..." -ForegroundColor Gray
                $partials | Select-Object -Skip 1 | ForEach-Object { 
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            continue
        }
        
        $delete = Read-Host "Delete and start fresh? (y/n)"
        if ($delete -ne 'y') { 
            Write-Host "[SKIPPED]`n" -ForegroundColor Gray
            continue 
        }
        Remove-Item $latest.FullName -Force
    }
    
    # New download
    $partFile = Join-Path $downloadFolder "DirectDLX_CLI_$(Get-Date -Format 'yyyyMMdd_HHmmss').part"
    Get-File -url $url -partFile $partFile
}