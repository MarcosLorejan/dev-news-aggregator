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
# Terminal 1: Start Vite dev server
npm run dev

# Terminal 2: Start Rails server
bin/rails server
```

Or use the Rails bin/dev command if configured with Foreman/Overmind.

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
