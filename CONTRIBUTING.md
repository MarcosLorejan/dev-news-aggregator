# Contributing

Thanks for improving Dev News Aggregator. This file is the short entry point; keep detailed project conventions in the existing docs.

## Start Here

- [docs/index.md](docs/index.md) for the knowledge map (one-line purpose per doc).
- [AGENTS.md](AGENTS.md) for AI-agent workflow, scope, and verification guardrails.
- [docs/KNOWLEDGE.md](docs/KNOWLEDGE.md) for OKF-inspired knowledge conventions (what belongs in guides vs decision/concept docs).
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for setup, architecture, coding standards, tests, and git conventions.
- [docs/REPO_STRUCTURE.md](docs/REPO_STRUCTURE.md) for the repository map. Update it when you change project structure.
- [docs/PRE_COMMIT_HOOKS.md](docs/PRE_COMMIT_HOOKS.md) for Overcommit setup and local hook usage.

## Workflow

1. Create a descriptive branch from `master`; never commit directly to `master`.
2. Keep changes focused on one issue or behavior.
3. Follow the conventional commit format documented in `docs/DEVELOPMENT.md`.
4. Run the relevant tests, lint, and security checks before opening a pull request.
5. Open a pull request with `gh pr create`, reference the issue, and wait for review before merging.

Use `docs/DEVELOPMENT.md` as the source of truth when this summary and the full guide differ.
