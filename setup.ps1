$ErrorActionPreference = "Stop"
$BOT_DIR = "C:\bots"

Write-Host "`n=== Discord Music Relay Bot — Namestitev ===" -ForegroundColor Cyan

# 0. Ustavi obstoječe bot procese
Write-Host "`n[0/6] Ustavljam obstoječe Python procese..."
$botProcesses = Get-Process -Name "python", "pythonw" -ErrorAction SilentlyContinue
if ($botProcesses) {
    $botProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "  Procesi ustavljeni." -ForegroundColor Green
} else {
    Write-Host "  Ni aktivnih procesov." -ForegroundColor Green
}

# 1. Ustvari C:\bots
Write-Host "`n[1/6] Ustvarjam mapo C:\bots..."
if (Test-Path $BOT_DIR) {
    Write-Host "  Mapa že obstaja." -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Force -Path $BOT_DIR | Out-Null
    Write-Host "  Mapa ustvarjena." -ForegroundColor Green
}

# 2. Python
Write-Host "`n[2/6] Preverjam Python..."
$pythonOk = $false
try {
    $ver = python --version 2>&1
    if ($ver -match "3\.1[2-9]|3\.[2-9]\d") { $pythonOk = $true }
} catch {}

if (-not $pythonOk) {
    Write-Host "  Python 3.12 ni najden. Prenašam (~25MB)..."
    $pyInstaller = "$env:TEMP\python312.exe"

    $webClient = New-Object System.Net.WebClient
    $webClient.add_DownloadProgressChanged({
        $percent = $_.ProgressPercentage
        $bar = "#" * [math]::Floor($percent / 5)
        $empty = "-" * (20 - [math]::Floor($percent / 5))
        Write-Host -NoNewline "`r  Prenos: [$bar$empty] $percent%   "
    })
    $task = $webClient.DownloadFileTaskAsync(
        "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe",
        $pyInstaller
    )
    while (-not $task.IsCompleted) { Start-Sleep -Milliseconds 200 }
    Write-Host "`r  Prenos: [####################] 100%   " -ForegroundColor Green

    Write-Host "  Nameščam v C:\Python312..."
    $install = Start-Process $pyInstaller -ArgumentList "/quiet TargetDir=C:\Python312 InstallAllUsers=0 PrependPath=1" -PassThru
    $dots = 0
    while (-not $install.HasExited) {
        $dots = ($dots % 3) + 1
        Write-Host -NoNewline "`r  Nameščam$('.' * $dots)   "
        Start-Sleep -Milliseconds 500
    }
    Write-Host "`r  Namestitev končana.   " -ForegroundColor Green

    Start-Sleep -Seconds 2
    $env:Path = "C:\Python312;C:\Python312\Scripts;" + $env:Path
    [System.Environment]::SetEnvironmentVariable("Path", "C:\Python312;C:\Python312\Scripts;" + [System.Environment]::GetEnvironmentVariable("Path","Machine"), "Machine")
    $ver = & "C:\Python312\python.exe" --version 2>&1
    Write-Host "  Python nameščen: $ver" -ForegroundColor Green
} else {
    Write-Host "  Python OK ($ver)" -ForegroundColor Green
}

# 3. Knjižnice
Write-Host "`n[3/6] Nameščam knjižnice..."
& "C:\Python312\python.exe" -m pip install --upgrade pip --quiet
& "C:\Python312\python.exe" -m pip install discord.py yt-dlp --quiet
Write-Host "  Knjižnice nameščene." -ForegroundColor Green

# 4. FFmpeg
Write-Host "`n[4/6] Preverjam FFmpeg..."
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "  FFmpeg ni najden. Prenašam..."
    $ffmpegZip = "$env:TEMP\ffmpeg.zip"
    $ffmpegDir = "C:\ffmpeg"
    Invoke-WebRequest "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $ffmpegZip
    Write-Host "  Razpakiram..."
    Expand-Archive $ffmpegZip -DestinationPath $ffmpegDir -Force
    $ffmpegBin = (Get-ChildItem "$ffmpegDir\*\bin" -Directory | Select-Object -First 1).FullName
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$ffmpegBin", "Machine")
    $env:Path += ";$ffmpegBin"
    Write-Host "  FFmpeg nameščen." -ForegroundColor Green
} else {
    Write-Host "  FFmpeg OK." -ForegroundColor Green
}

# 5. Prenesi skripte
Write-Host "`n[5/6] Prenašam bot.py in watchbot.py..."
$REPO = "https://raw.githubusercontent.com/KlemenKovacic/Discord-Music-Relay-Cleanup-Bot-Auto-Hosted-/main"
Invoke-WebRequest "$REPO/bot.py"      -OutFile "$BOT_DIR\bot.py"
Invoke-WebRequest "$REPO/watchbot.py" -OutFile "$BOT_DIR\watchbot.py"
Write-Host "  Skripte prenesene." -ForegroundColor Green

# 6. Task Scheduler
Write-Host "`n[6/6] Nastavljam Task Scheduler..."
$pythonwCmd = Get-Command pythonw.exe -ErrorAction SilentlyContinue
$pythonw = if ($pythonwCmd) { $pythonwCmd.Source } else { "pythonw.exe" }

$action   = New-ScheduledTaskAction -Execute $pythonw -Argument "$BOT_DIR\watchbot.py" -WorkingDirectory $BOT_DIR
$trigger  = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "DiscordBotWatcher" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null
Write-Host "  Task Scheduler nastavljen." -ForegroundColor Green

# Zaženi takoj
Write-Host "`nZaganjam watchbot..."
Start-Process $pythonw -ArgumentList "$BOT_DIR\watchbot.py" -WorkingDirectory $BOT_DIR -WindowStyle Hidden

Write-Host "`n=== Namestitev končana! ===" -ForegroundColor Cyan
Write-Host "⚠️  Uredi TOKEN in OWNER_ID v C:\bots\bot.py pred uporabo." -ForegroundColor Yellow
