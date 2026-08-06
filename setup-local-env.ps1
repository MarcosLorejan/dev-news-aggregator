# One-time / repeat local setup for Windows development.
# Usage: .\setup-local-env.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

$envExample = Join-Path $root ".env.example"
$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    if (Test-Path $envExample) {
        Write-Host "==> Creating .env from .env.example..." -ForegroundColor Cyan
        Copy-Item $envExample $envFile
        Write-Host "    Fill optional REDDIT_CLIENT_ID / REDDIT_CLIENT_SECRET for OAuth scores." -ForegroundColor DarkGray
    } else {
        Write-Host "Missing .env.example — skip creating .env." -ForegroundColor Yellow
    }
} else {
    Write-Host "==> .env already present (left unchanged)." -ForegroundColor DarkGray
}

Write-Host "==> Installing Ruby gems..." -ForegroundColor Cyan
bundle install

Write-Host "==> Installing npm packages..." -ForegroundColor Cyan
npm install

Write-Host "==> Installing Overcommit Git hooks..." -ForegroundColor Cyan
bundle exec overcommit --install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Overcommit install failed. See docs/PRE_COMMIT_HOOKS.md" -ForegroundColor Red
    exit 1
}
bundle exec overcommit --sign
if ($LASTEXITCODE -ne 0) {
    Write-Host "Overcommit sign failed. See docs/PRE_COMMIT_HOOKS.md" -ForegroundColor Red
    exit 1
}
Write-Host "    Conventional Commits are enforced; see docs/PRE_COMMIT_HOOKS.md" -ForegroundColor DarkGray

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "==> Starting PostgreSQL via Docker..." -ForegroundColor Cyan
    # --wait blocks until the healthcheck passes (first boot can take 1-2 min)
    docker compose up -d --wait db 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "PostgreSQL container did not become healthy in time." -ForegroundColor Red
        Write-Host "Check logs: docker compose logs db" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "Docker not found in PATH." -ForegroundColor Yellow
    Write-Host "Install Docker Desktop, or run PostgreSQL 15 locally with:" -ForegroundColor Yellow
    Write-Host "  user: dev_news_user  password: dev_password  db: dev_news_aggregator_development" -ForegroundColor Yellow
}

$env:RAILS_ENV = "development"
Write-Host "==> Preparing database..." -ForegroundColor Cyan
bundle exec rails db:prepare 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Database setup failed. Is PostgreSQL running on localhost:5432?" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setup complete. Start the app with:" -ForegroundColor Green
Write-Host "  .\dev.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Or in two terminals:" -ForegroundColor Green
Write-Host "  npm run dev" -ForegroundColor White
Write-Host "  bundle exec rails server" -ForegroundColor White
