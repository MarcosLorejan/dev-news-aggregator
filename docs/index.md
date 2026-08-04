# Knowledge map

One-line index of maintained project knowledge. Orient here, then open only what you need.

Conventions: [KNOWLEDGE.md](KNOWLEDGE.md). Code layout: [REPO_STRUCTURE.md](REPO_STRUCTURE.md). Agent workflow: [../AGENTS.md](../AGENTS.md).

## Entry points

| Doc | Purpose |
|-----|---------|
| [KNOWLEDGE.md](KNOWLEDGE.md) | OKF-inspired conventions: instructions vs curated *why*, roadmap |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Setup, architecture, coding standards, tests, git workflow |
| [REPO_STRUCTURE.md](REPO_STRUCTURE.md) | Living directory map; update when structure changes |
| [../AGENTS.md](../AGENTS.md) | Standing instructions for coding agents (`bin/validate`, scope) |
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | Contributor entry point and PR workflow |

## Guides

| Doc | Purpose |
|-----|---------|
| [REACT_SETUP.md](REACT_SETUP.md) | React/Vite frontend install and two-process dev |
| [AGENT_API.md](AGENT_API.md) | Stable `/api/v1` JSON contract for agents |
| [KEYWORD_FILTERS.md](KEYWORD_FILTERS.md) | Interest presets, keyword query params, feed filters |
| [YOUTUBE.md](YOUTUBE.md) | Channel Atom vs Data API, quota, Sources UI |
| [SUMMARIZER.md](SUMMARIZER.md) | Optional pluggable article summarizer providers |
| [PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md) | Overcommit setup, Conventional Commits hooks |

## Decisions (*why*)

| Doc | Purpose |
|-----|---------|
| [decisions/react-vite-two-process.md](decisions/react-vite-two-process.md) | Why Vite SPA + two-process local dev |
| [decisions/keyword-interests.md](decisions/keyword-interests.md) | Why interests are presets + query params |
| [decisions/agent-api-thin-contract.md](decisions/agent-api-thin-contract.md) | Why `/api/v1` stays thinner than the rich feed |
| [decisions/youtube-atom-first.md](decisions/youtube-atom-first.md) | Why channel Atom precedes Data API search |
| [decisions/solid-queue-windows.md](decisions/solid-queue-windows.md) | Why Solid Queue in Puma is skipped on Windows |
| [decisions/fetch-orchestration.md](decisions/fetch-orchestration.md) | Why orchestrator vs per-source fetchers |

## Planned (milestone)

| Area | Issue |
|------|--------|
| Knowledge changelog (`log.md`) | [#407](https://github.com/MarcosLorejan/dev-news-aggregator/issues/407) |
| Link / orphan drift checks | [#411](https://github.com/MarcosLorejan/dev-news-aggregator/issues/411) |
