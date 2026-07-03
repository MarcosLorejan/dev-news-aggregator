# React with Vite Setup

This project now uses React with Vite for the frontend.

## Prerequisites

- Node.js 18+ and npm
- Ruby and Bundler

## Installation

1. Install Ruby dependencies:
```bash
bundle install
```

2. Install Node dependencies:
```bash
npm install
```

## Development

To run the application in development mode with hot module replacement:

```bash
# Terminal 1: Start Vite dev server (port 3036)
npm run dev

# Terminal 2: Start Rails server (port 3000)
bundle exec rails server
```

### Windows

On Windows, `bin/rails` does not run directly in CMD/PowerShell. Use one of:

```powershell
# Recommended: setup once, then start both servers
.\setup-local-env.ps1
.\dev.ps1

# Or manually:
bundle exec rails server
# or
bin\rails.bat server
```

PostgreSQL must be running first (`docker compose up -d db` or local Postgres 15).

Open **http://localhost:3000** (Rails). Vite runs on port 3036 and is proxied by Rails in development.

## Building for Production

```bash
npm run build
```

This will compile the React application and output the assets to `public/builds`.

## Project Structure

```
app/frontend/
├── entrypoints/       # Vite entrypoints
│   └── application.tsx
├── components/        # React components
│   └── App.tsx
└── ...
```

## Configuration Files

- `vite.config.ts` - Vite configuration
- `tsconfig.json` - TypeScript configuration
- `config/vite.json` - Vite Ruby configuration
- `package.json` - Node dependencies and scripts
