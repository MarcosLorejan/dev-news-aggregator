# Start Vite + Rails for local development on Windows.
# Usage: .\dev.ps1
# Prerequisite: PostgreSQL running (.\setup-local-env.ps1)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

function Test-Postgres {
    $env:RAILS_ENV = "development"
    bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function Wait-ViteDevServer {
    param([int]$Port = 3036, [int]$TimeoutSeconds = 30)

    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
        if (Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue | Select-Object -ExpandProperty TcpTestSucceeded) {
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

if (-not (Test-Postgres)) {
    Write-Host "PostgreSQL is not reachable." -ForegroundColor Red
    Write-Host "Run: .\setup-local-env.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting Vite (port 3036) and Rails (port 3000)..." -ForegroundColor Cyan
Write-Host "Open http://localhost:3000" -ForegroundColor Green
Write-Host "Press Ctrl+C here to stop Rails (Vite window closes too)." -ForegroundColor DarkGray

$vite = Start-NpmRunDev -WorkingDirectory $root
if (-not (Wait-ViteDevServer)) {
    Write-Host "Vite did not start on port 3036. Check the Vite window for errors." -ForegroundColor Red
    if ($vite -and -not $vite.HasExited) { Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue }
    exit 1
}
try {
    $env:RAILS_ENV = "development"
    bundle exec rails server -b 127.0.0.1 -p 3000
}
finally {
    if ($vite -and -not $vite.HasExited) {
        Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue
    }
}
