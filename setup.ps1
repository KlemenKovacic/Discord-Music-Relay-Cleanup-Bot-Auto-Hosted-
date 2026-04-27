$ErrorActionPreference = "Continue"
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
    Write-Host "  Mapa ze obstaja." -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Force -Path $BOT_DIR | Out-Null
    Write-Host "  Mapa ustvarjena." -ForegroundColor Green
}

# 2. Python
Write-Host "`n[2/6] Preverjam Python..."
$pythonExe = "C:\Python312\python.exe"
$pythonOk = $false

if (Test-Path $pythonExe) {
    $ver = & $pythonExe --version 2>&1
    Write-Host "  Python OK ($ver)" -ForegroundColor Green
    $pythonOk = $true
}

if (-not $pythonOk) {
    Write-Host "  Python 3.12 ni najden. Prenašam (~25MB)..."
    $pyInstaller = "$env:TEMP\python312.exe"

    $dots = 0
    $job = Start-Job {
        (New-Object System.Net.WebClient).DownloadFile(
            "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe",
            $using:pyInstaller
        )
    }
    while ($job.State -eq "Running") {
        $dots = ($dots % 3) + 1
        $size = if (Test-Path $pyInstaller) { [math]::Round((Get-Item $pyInstaller).Length / 1MB, 1) } else { 0 }
        Write-Host -NoNewline "`r  Prenasam$('.' * $dots) $size MB   "
        Start-Sleep -Milliseconds 500
    }
    Receive-Job $job | Out-Null
    Remove-Job $job
    Write-Host "`r  Prenos koncan.                    " -ForegroundColor Green

    Write-Host "  Namescam v C:\Python312..."
    $install = Start-Process $pyInstaller -ArgumentList "/quiet TargetDir=C:\Python312 InstallAllUsers=0 PrependPath=1" -PassThru
    $dots = 0
    while (-not $install.HasExited) {
        $dots = ($dots % 3) + 1
        Write-Host -NoNewline "`r  Namescam$('.' * $dots)   "
        Start-Sleep -Milliseconds 500
    }
    Write-Host "`r  Namestitev koncana.   " -ForegroundColor Green

    Start-Sleep -Seconds 2
    $env:Path = "C:\Python312;C:\Python312\Scripts;" + $env:Path
    [System.Environment]::SetEnvironmentVariable("Path", "C:\Python312;C:\Python312\Scripts;" + [System.Environment]::GetEnvironmentVariable("Path","Machine"), "Machine")
    $ver = & $pythonExe --version 2>&1
    Write-Host "  Python namescen: $ver" -ForegroundColor Green
}

# 3. Knjiznice
Write-Host "`n[3/6] Namescam knjiznice..."
& $pythonExe -m pip install --upgrade pip 2>&1 | Out-Null
& $pythonExe -m pip install discord.py yt-dlp 2>&1 | Out-Null
Write-Host "  Knjiznice namescene." -ForegroundColor Green

# 4. FFmpeg
Write-Host "`n[4/6] Preverjam FFmpeg..."
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "  FFmpeg ni najden. Prenasam..."
    $ffmpegZip = "$env:TEMP\ffmpeg.zip"
    $ffmpegDir = "C:\ffmpeg"

    $dots = 0
    $job = Start-Job {
        (New-Object System.Net.WebClient).DownloadFile(
            "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip",
            $using:ffmpegZip
        )
    }
    while ($job.State -eq "Running") {
        $dots = ($dots % 3) + 1
        $size = if (Test-Path $ffmpegZip) { [math]::Round((Get-Item $ffmpegZip).Length / 1MB, 1) } else { 0 }
        Write-Host -NoNewline "`r  Prenasam$('.' * $dots) $size MB   "
        Start-Sleep -Milliseconds 500
    }
    Receive-Job $job | Out-Null
    Remove-Job $job
    Write-Host "`r  Prenos koncan.                    " -ForegroundColor Green

    Write-Host "  Razpakiram..."
    Expand-Archive $ffmpegZip -DestinationPath $ffmpegDir -Force
    $ffmpegBin = (Get-ChildItem "$ffmpegDir\*\bin" -Directory | Select-Object -First 1).FullName
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$ffmpegBin", "Machine")
    $env:Path += ";$ffmpegBin"
    Write-Host "  FFmpeg namescen." -ForegroundColor Green
} else {
    Write-Host "  FFmpeg OK." -ForegroundColor Green
}

# 5. Prenesos skript
Write-Host "`n[5/6] Prenasam bot.py in watchbot.py..."
$REPO = "https://raw.githubusercontent.com/KlemenKovacic/Discord-Music-Relay-Cleanup-Bot-Auto-Hosted-/main"
(New-Object System.Net.WebClient).DownloadFile("$REPO/bot.py", "$BOT_DIR\bot.py")
(New-Object System.Net.WebClient).DownloadFile("$REPO/watchbot.py", "$BOT_DIR\watchbot.py")
Write-Host "  Skripte prenesene." -ForegroundColor Green

# 6. Task Scheduler
Write-Host "`n[6/6] Nastavljam Task Scheduler..."
$pythonw = "C:\Python312\pythonw.exe"

$action    = New-ScheduledTaskAction -Execute $pythonw -Argument "$BOT_DIR\watchbot.py" -WorkingDirectory $BOT_DIR
$trigStart = New-ScheduledTaskTrigger -AtStartup
$trigRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName "DiscordBotWatcher" -Action $action -Trigger @($trigStart, $trigRepeat) -Settings $settings -RunLevel Highest -Force | Out-Null
Write-Host "  Task Scheduler nastavljen." -ForegroundColor Green

# Zagon
Write-Host "`nZaganjam watchbot..."
Start-Process $pythonw -ArgumentList "$BOT_DIR\watchbot.py" -WorkingDirectory $BOT_DIR -WindowStyle Hidden

Write-Host "`n=== Namestitev koncana! ===" -ForegroundColor Cyan
Write-Host "  Uredi TOKEN in OWNER_ID v C:\bots\bot.py pred uporabo." -ForegroundColor Yellow
