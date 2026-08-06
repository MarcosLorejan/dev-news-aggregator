---
type: Log
title: Knowledge changelog
description: Dated history of knowledge-doc creates, updates, and deprecations (newest first).
tags: [knowledge, log]
---

# Knowledge changelog

Dated history of **project knowledge** changes (guides, decisions, maps). Newest first. One bullet per create, update, or deprecate.

Update this file in the **same PR** when you add or materially change knowledge under `docs/` (see [KNOWLEDGE.md](KNOWLEDGE.md)). Do not log every typo; do log new decisions, new guides, and structural doc moves.

## 2026-08-06

- Documented the Windows UTF-8 code page requirement for Overcommit in [PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md); a legacy code page aborts every commit ([#446](https://github.com/MarcosLorejan/dev-news-aggregator/issues/446)).
- Raised the Node.js floor from 20 to 24 in [DEVELOPMENT.md](DEVELOPMENT.md) and [REACT_SETUP.md](REACT_SETUP.md); jsdom 30 dropped Node 20 ([#418](https://github.com/MarcosLorejan/dev-news-aggregator/pull/418)).

## 2026-08-04

- Evaluated `okf` 1.12.0 against `docs/`; **deferred** requiring it in CI — keep `bin/check-docs` ([#410](https://github.com/MarcosLorejan/dev-news-aggregator/issues/410)).
- Added `bin/check-docs` (broken relative links + knowledge-map orphans), wired into `bin/validate` and CI `docs_check` ([#411](https://github.com/MarcosLorejan/dev-news-aggregator/issues/411)).

## 2026-08-03

- Created [decisions/](decisions/) with six durable *why* records (React/Vite, keyword interests, Agent API thin contract, YouTube Atom-first, Solid Queue on Windows, fetch orchestration) ([#409](https://github.com/MarcosLorejan/dev-news-aggregator/issues/409)).
- Created [index.md](index.md) knowledge map and light YAML frontmatter on maintained guides ([#408](https://github.com/MarcosLorejan/dev-news-aggregator/issues/408)).
- Created [KNOWLEDGE.md](KNOWLEDGE.md) OKF-inspired conventions ([#406](https://github.com/MarcosLorejan/dev-news-aggregator/issues/406)).
- Created this [log.md](log.md) ([#407](https://github.com/MarcosLorejan/dev-news-aggregator/issues/407)).

## 2026-08-02

- Documented YouTube ingestion paths and quota strategy in [YOUTUBE.md](YOUTUBE.md) ([#388](https://github.com/MarcosLorejan/dev-news-aggregator/issues/388)).

## Earlier (seed)

- [KEYWORD_FILTERS.md](KEYWORD_FILTERS.md) — interest presets and feed filter params.
- [AGENT_API.md](AGENT_API.md) — stable `/api/v1` JSON contract for agents.
- [AGENTS.md](../AGENTS.md) — standing instructions for coding agents (milestone [AI agent friendliness](https://github.com/MarcosLorejan/dev-news-aggregator/milestone/14)).
- [DEVELOPMENT.md](DEVELOPMENT.md), [REPO_STRUCTURE.md](REPO_STRUCTURE.md), [REACT_SETUP.md](REACT_SETUP.md), [PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md), [SUMMARIZER.md](SUMMARIZER.md) — existing how-to corpus.
