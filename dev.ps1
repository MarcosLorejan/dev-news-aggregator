# Start Vite + Rails for local development on Windows.
# Usage: .\dev.ps1
# Or double-click: start-app.bat
# Prerequisite: one-time setup via .\setup-local-env.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

function Disable-ConsoleQuickEdit {
    # Clicking a CMD/PowerShell window enables selection mode and pauses the script.
    $signature = @"
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll")]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll")]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
"@
    try {
        $api = Add-Type -MemberDefinition $signature -Name ConsoleQuickEdit -Namespace Native -PassThru
        $handle = $api::GetStdHandle(-10) # STD_INPUT_HANDLE
        $mode = [uint32]0
        if (-not $api::GetConsoleMode($handle, [ref]$mode)) { return }
        # ENABLE_EXTENDED_FLAGS (0x80), clear ENABLE_QUICK_EDIT_MODE (0x40)
        $mode = ($mode -bor [uint32]0x80) -band (-bnot [uint32]0x40)
        [void]$api::SetConsoleMode($handle, $mode)
    } catch {
        # Non-fatal if console APIs are unavailable.
    }
}

function Test-TcpPortOpen {
    param([int]$Port)

    # On Windows, Vite often listens on IPv6 [::1] only; Rails may use 127.0.0.1.
    $targets = @(
        @{ Address = "127.0.0.1"; Family = [System.Net.Sockets.AddressFamily]::InterNetwork },
        @{ Address = "::1"; Family = [System.Net.Sockets.AddressFamily]::InterNetworkV6 }
    )

    foreach ($target in $targets) {
        $client = $null
        try {
            $client = New-Object System.Net.Sockets.TcpClient($target.Family)
            $async = $client.BeginConnect($target.Address, $Port, $null, $null)
            $ok = $async.AsyncWaitHandle.WaitOne(400)
            if ($ok) {
                $client.EndConnect($async)
                if ($client.Connected) { return $true }
            }
        } catch {
            # try next address family
        } finally {
            if ($client) { $client.Close() }
        }
    }
    return $false
}

function Test-Postgres {
    # Fast check: avoid booting Rails just to probe the DB.
    return (Test-TcpPortOpen -Port 5432)
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

    if (-not (Wait-TcpPort -Port 5432 -TimeoutSeconds 30)) {
        Write-Host "PostgreSQL started but port 5432 is still closed." -ForegroundColor Red
        Write-Host "Try: .\setup-local-env.ps1" -ForegroundColor Yellow
        exit 1
    }
}

function Wait-TcpPort {
    param([int]$Port, [int]$TimeoutSeconds = 60)

    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
        if (Test-TcpPortOpen -Port $Port) { return $true }
        Start-Sleep -Milliseconds 500
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
    param([int]$Port = 3000, [string]$Url = "http://127.0.0.1:3000")

    # Run in-process so the browser opens in this Windows session (nested
    # powershell.exe -Command helpers often fail silently when launched from .bat).
    # Wait until Rails serves HTML *and* the Vite proxy responds — not just TCP bind.
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript({
        param([int]$Port, [string]$Url)

        function Test-HttpOk([string]$TargetUrl) {
            try {
                $request = [System.Net.HttpWebRequest]::Create($TargetUrl)
                $request.Method = "GET"
                $request.Timeout = 2000
                $request.ReadWriteTimeout = 2000
                $response = $request.GetResponse()
                $code = [int]$response.StatusCode
                $response.Close()
                return ($code -ge 200 -and $code -lt 400)
            } catch {
                return $false
            }
        }

        $deadline = (Get-Date).AddSeconds(180)
        while ((Get-Date) -lt $deadline) {
            $pageOk = Test-HttpOk ("http://127.0.0.1:{0}/" -f $Port)
            # With skipProxy, Vite assets are served from :3036 (not via Rails).
            $viteOk = Test-HttpOk "http://127.0.0.1:3036/vite-dev/@vite/client"
            if ($pageOk -and $viteOk) {
              Start-Process $Url
              return
            }
            Start-Sleep -Milliseconds 750
        }
    }).AddArgument($Port).AddArgument($Url)
    [void]$ps.BeginInvoke()
}

Disable-ConsoleQuickEdit

Start-PostgresIfNeeded

Write-Host "Starting Vite (port 3036) and Rails (port 3000)..." -ForegroundColor Cyan
Write-Host "Tip: don't click inside this window while it starts (that can pause it)." -ForegroundColor DarkGray
Write-Host "Press Ctrl+C here to stop Rails (Vite window closes too)." -ForegroundColor DarkGray

Write-Host "Launching Vite..." -ForegroundColor Cyan
$vite = Start-NpmRunDev -WorkingDirectory $root
Write-Host "Waiting for Vite on port 3036..." -ForegroundColor Cyan
if (-not (Wait-TcpPort -Port 3036 -TimeoutSeconds 60)) {
    Write-Host "Vite did not start on port 3036. Check the Vite window for errors." -ForegroundColor Red
    if ($vite -and -not $vite.HasExited) { Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue }
    exit 1
}

Start-BrowserWhenReady

try {
    Write-Host "Starting Rails (first boot can take 20-60s)..." -ForegroundColor Cyan
    Write-Host "Browser will open http://127.0.0.1:3000 when ready." -ForegroundColor Green
    # Do not set SOLID_QUEUE_IN_PUMA on Windows — Solid Queue's Puma plugin
    # calls fork(), which is not available (NotImplementedError).
    $env:RAILS_ENV = "development"
    Remove-Item Env:SOLID_QUEUE_IN_PUMA -ErrorAction SilentlyContinue
    bundle exec rails server -b 127.0.0.1 -p 3000
}
finally {
    if ($vite -and -not $vite.HasExited) {
        Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue
    }
}
