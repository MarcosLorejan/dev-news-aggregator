---
type: Decision
title: React SPA with Vite two-process development
description: Why the UI is a Vite React SPA with a separate HMR process, not asset-pipeline-only.
tags: [frontend, vite, react, decision]
resource: app/frontend/
---

# React SPA with Vite two-process development

## Context

The app needed a responsive SPA for filtering, bookmarks, and source management. Shipping that through the classic Rails asset pipeline alone made HMR slow and left blank-page failure modes when many module requests queued behind a few Puma threads.

## Decision

- Frontend lives under `app/frontend/` as a React + Vite app.
- Local full stack runs **two processes**: Vite (HMR, port 3036) and Rails (port 3000). `bin/dev` stays Rails-only on purpose.
- Development uses `skipProxy: true` in `config/vite.json` so the browser talks to Vite directly.

## Consequences

- Contributors (and agents) who only start `bin/dev` get Rails without the React UI — use `npm run dev` + Rails, or `.\dev.ps1` / `start-app.bat` on Windows.
- Deploy still builds Vite assets into the Rails image; the two-process split is a **dev** ergonomics choice.
- Frontend and Rails change at different cadences; keep API contracts and page props explicit.

## See also

- How-to: [REACT_SETUP.md](../REACT_SETUP.md), [DEVELOPMENT.md](../DEVELOPMENT.md)
