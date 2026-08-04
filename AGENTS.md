# AGENTS.md

Guidance for AI coding agents working in this repository. Keep this file concise and defer details to the maintained docs.

## Read First

- `docs/index.md`: knowledge map (one line per doc — start here for orientation).
- `CONTRIBUTING.md`: contributor entry point and pull request workflow.
- `docs/KNOWLEDGE.md`: OKF-inspired conventions for durable project knowledge (instructions vs *why*, concept files, roadmap).
- `docs/DEVELOPMENT.md`: setup, architecture, coding standards, test expectations, and git conventions.
- `docs/REPO_STRUCTURE.md`: repository map. Update it in the same change when structure changes.
- `docs/PRE_COMMIT_HOOKS.md`: Overcommit setup and local hook checks.

## Work Rules

- Create a branch from `master`; never commit directly to `master`.
- Keep pull requests focused. Avoid broad roadmap, cleanup, or refactor work unless the issue asks for it.
- Follow the existing package and Rails boundaries. Prefer service objects for aggregation logic and keep controllers thin.
- Do not commit credentials, API tokens, database dumps, private customer data, or local machine paths.
- When adding or moving files, update `docs/REPO_STRUCTURE.md` if the structure map changes.

## Local full-stack server

- `bin/dev` starts **Rails only** (`bin/rails server`). It does **not** start Vite.
- Full stack (Rails + Vite HMR): `npm run dev` in one terminal and `bin/rails server` (or `SOLID_QUEUE_IN_PUMA=1 bin/rails server`) in another; on Windows use `.\dev.ps1`.
- Details: `docs/DEVELOPMENT.md` and `docs/REACT_SETUP.md`.

## Verification

Prefer the CI-equivalent local wrapper before opening a pull request:

```bash
bin/validate
```

For quick iteration, use fast mode (skips Brakeman and Rails tests):

```bash
bin/validate --fast
```

Or run the checks relevant to your change individually:

```bash
bin/rails test
bin/rubocop
bin/brakeman
npm test
npm audit --omit=dev --audit-level=moderate
```

For hook parity with local contributors, install and run Overcommit as described in `docs/PRE_COMMIT_HOOKS.md`.
