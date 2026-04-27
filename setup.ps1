# Zaženi PowerShell kot Administrator!
# PowerShell: Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup.ps1
# irm https://raw.githubusercontent.com/KlemenKovacic/Discord-Music-Relay-Cleanup-Bot-Auto-Hosted-/main/setup.ps1 | iex

$ErrorActionPreference = "Stop"
$BOT_DIR = "C:\bots"

Write-Host "`n=== Discord Music Relay Bot — Namestitev ===" -ForegroundColor Cyan

# 1. Ustvari C:\bots
Write-Host "`n[1/5] Ustvarjam mapo C:\bots..."
New-Item -ItemType Directory -Force -Path $BOT_DIR | Out-Null

# 2. Preveri ali je Python 3.12+ nameščen, če ne — namesti
Write-Host "`n[2/5] Preverjam Python..."
$pythonOk = $false
try {
    $ver = python --version 2>&1
    if ($ver -match "3\.1[2-9]|3\.[2-9]\d") { $pythonOk = $true }
} catch {}

if (-not $pythonOk) {
    Write-Host "  Python 3.12 ni najden. Prenašam..."
    $pyInstaller = "$env:TEMP\python312.exe"
    Invoke-WebRequest "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe" -OutFile $pyInstaller
    Start-Process $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    Write-Host "  Python 3.12 nameščen." -ForegroundColor Green
} else {
    Write-Host "  Python OK ($ver)" -ForegroundColor Green
}

# 3. Namesti knjižnice
Write-Host "`n[3/5] Nameščam knjižnice..."
python -m pip install --upgrade pip --quiet
python -m pip install discord.py yt-dlp --quiet
Write-Host "  discord.py in yt-dlp nameščena." -ForegroundColor Green

# 4. Namesti FFmpeg
Write-Host "`n[4/5] Preverjam FFmpeg..."
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "  FFmpeg ni najden. Prenašam..."
    $ffmpegZip = "$env:TEMP\ffmpeg.zip"
    $ffmpegDir = "C:\ffmpeg"
    Invoke-WebRequest "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $ffmpegZip
    Expand-Archive $ffmpegZip -DestinationPath $ffmpegDir -Force
    $ffmpegBin = (Get-ChildItem "$ffmpegDir\*\bin" -Directory | Select-Object -First 1).FullName
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$ffmpegBin", "Machine")
    $env:Path += ";$ffmpegBin"
    Write-Host "  FFmpeg nameščen." -ForegroundColor Green
} else {
    Write-Host "  FFmpeg OK." -ForegroundColor Green
}

# 5. Prenesi bot.py in watchbot.py iz GitHuba
Write-Host "`n[5/5] Prenašam skripte..."
$REPO = "https://raw.githubusercontent.com/KlemenKovacic/Discord-Music-Relay-Cleanup-Bot-Auto-Hosted-/main"
Invoke-WebRequest "$REPO/bot.py"      -OutFile "$BOT_DIR\bot.py"
Invoke-WebRequest "$REPO/watchbot.py" -OutFile "$BOT_DIR\watchbot.py"
Write-Host "  bot.py in watchbot.py v C:\bots\" -ForegroundColor Green

# 6. Task Scheduler
Write-Host "`nNastavljam Task Scheduler..."
$pythonwCmd = Get-Command pythonw.exe -ErrorAction SilentlyContinue
$pythonw = if ($pythonwCmd) { $pythonwCmd.Source } else { "pythonw.exe" }
if (-not $pythonw) { $pythonw = "pythonw.exe" }

$action  = New-ScheduledTaskAction -Execute $pythonw -Argument "$BOT_DIR\watchbot.py" -WorkingDirectory $BOT_DIR
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "DiscordBotWatcher" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null
Write-Host "  Task Scheduler nastavljen." -ForegroundColor Green

# Zaženi takoj
Write-Host "`nZaganjam watchbot zdaj..."
Start-Process $pythonw -ArgumentList "$BOT_DIR\watchbot.py" -WorkingDirectory $BOT_DIR -WindowStyle Hidden

Write-Host "`n=== Namestitev končana! ===" -ForegroundColor Cyan
Write-Host "Uredi token in OWNER_ID v C:\bots\bot.py pred uporabo." -ForegroundColor Yellow
