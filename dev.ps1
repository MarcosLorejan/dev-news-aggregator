# Start Vite + Rails for local development on Windows.
# Usage: .\dev.ps1
# Or double-click: start-app.bat
# Prerequisite: one-time setup via .\setup-local-env.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

function Test-Postgres {
    $env:RAILS_ENV = "development"
    bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function Start-PostgresIfNeeded {
    if (Test-Postgres) { return }

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "PostgreSQL is not reachable and Docker was not found." -ForegroundColor Red
        Write-Host "Run: .\setup-local-env.ps1" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Starting PostgreSQL via Docker..." -ForegroundColor Cyan
    docker compose up -d --wait db
    if ($LASTEXITCODE -ne 0) {
        Write-Host "PostgreSQL container did not become healthy." -ForegroundColor Red
        Write-Host "Check logs: docker compose logs db" -ForegroundColor Yellow
        exit 1
    }

    if (-not (Test-Postgres)) {
        Write-Host "PostgreSQL started but Rails still cannot connect." -ForegroundColor Red
        Write-Host "Try: .\setup-local-env.ps1" -ForegroundColor Yellow
        exit 1
    }
}

function Wait-TcpPort {
    param([int]$Port, [int]$TimeoutSeconds = 60)

    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
        if (Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue |
            Select-Object -ExpandProperty TcpTestSucceeded) {
            return $true
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Get-NpmCmdPath {
    $node = Get-Command node -ErrorAction Stop
    $npmCmd = Join-Path (Split-Path $node.Source -Parent) "npm.cmd"
    if (-not (Test-Path $npmCmd)) {
        throw "npm.cmd not found at $npmCmd"
    }
    return $npmCmd
}

function Start-NpmRunDev {
    param([string]$WorkingDirectory)

    # PowerShell resolves "npm" to npm.ps1, which Start-Process cannot run.
    # Use npm.cmd beside node.exe instead.
    $npmCmd = Get-NpmCmdPath
    return Start-Process -FilePath $npmCmd -ArgumentList "run", "dev" `
        -WorkingDirectory $WorkingDirectory -PassThru
}

function Start-BrowserWhenReady {
    param([int]$Port = 3000, [string]$Url = "http://localhost:3000")

    # Hidden helper so Rails can stay in the foreground.
    $arg = @"
`$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt `$deadline) {
  try {
    `$r = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue
    if (`$r.TcpTestSucceeded) {
      Start-Process '$Url'
      exit 0
    }
  } catch {}
  Start-Sleep -Seconds 1
}
"@
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $arg |
        Out-Null
}

Start-PostgresIfNeeded

Write-Host "Starting Vite (port 3036) and Rails (port 3000)..." -ForegroundColor Cyan
Write-Host "Browser will open http://localhost:3000 when ready." -ForegroundColor Green
Write-Host "Press Ctrl+C here to stop Rails (Vite window closes too)." -ForegroundColor DarkGray

$vite = Start-NpmRunDev -WorkingDirectory $root
if (-not (Wait-TcpPort -Port 3036 -TimeoutSeconds 30)) {
    Write-Host "Vite did not start on port 3036. Check the Vite window for errors." -ForegroundColor Red
    if ($vite -and -not $vite.HasExited) { Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue }
    exit 1
}

Start-BrowserWhenReady

try {
    $env:RAILS_ENV = "development"
    $env:SOLID_QUEUE_IN_PUMA = "1"
    bundle exec rails server -b 127.0.0.1 -p 3000
}
finally {
    if ($vite -and -not $vite.HasExited) {
        Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue
    }
}
