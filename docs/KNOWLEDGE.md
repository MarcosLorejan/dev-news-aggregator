---
type: Guide
title: Knowledge conventions (OKF-inspired)
description: What we borrow from OKF for durable project knowledge without requiring the okf gem.
tags: [knowledge, agents, conventions]
---

# Knowledge conventions (OKF-inspired)

How this repo stores durable project knowledge for humans and coding agents.

We borrow practices from the [Open Knowledge Format (OKF)](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing) and [okf-gem](https://okfgem.com/), without adopting the gem or a full OKF bundle yet. Milestone: [Knowledge as code (OKF-inspired)](https://github.com/MarcosLorejan/dev-news-aggregator/milestone/20).

## Instructions vs curated knowledge

| Layer | Lives in | Holds |
|-------|----------|--------|
| Standing instructions | `AGENTS.md`, Cursor rules/skills, `CONTRIBUTING.md` | Workflow, scope, verification, “always/never” guardrails |
| How-to guides | `docs/*.md` (e.g. `DEVELOPMENT.md`, `YOUTUBE.md`) | Setup, APIs, operational steps |
| Curated *why* | `docs/decisions/` (and future concept files) | Trade-offs and reasoning agents cannot recover from code alone |
| Code map | `docs/REPO_STRUCTURE.md` | Directory layout and structural maintenance rules |

Do **not** dump long domain reasoning into `AGENTS.md`. Keep that file short and point here (and to focused docs) instead.

`REPO_STRUCTURE.md` remains the **code** map. The knowledge map ([index.md](index.md)) is complementary: one-line summaries of knowledge docs, not a second file-tree.

## Practices we adopt

### One concept = one file

Prefer focused docs (like `AGENT_API.md`, `KEYWORD_FILTERS.md`, `YOUTUBE.md`) over growing `DEVELOPMENT.md` further. New durable topics get their own file; link out instead of duplicating.

### Progressive disclosure

Agents should orient from a short map first, then open only the files they need.

- Start: [index.md](index.md) (one line per doc)
- Then: [AGENTS.md](../AGENTS.md) → this file → focused guides as needed
- Code layout stays in [REPO_STRUCTURE.md](REPO_STRUCTURE.md)

### Links are edges

Cross-link related guides and concepts with relative Markdown links. A link to a concept that does not exist yet is demand (backlog), not something to paper over. Prefer fixing or filing over leaving silent rot.

### Knowledge changelog

Keep a dated [log.md](log.md) (newest first, ISO day headings, one bullet per create/update/deprecate). Append in the **same PR** when you add or materially change knowledge under `docs/` (new guides, decisions, maps, or structural moves). Skip pure typos and formatting-only edits.

### Light frontmatter (optional)

Concept-oriented docs may use YAML frontmatter. Recommended keys:

```yaml
---
type: Guide          # or Decision, Playbook, Concept, …
title: Short title
description: One-line summary for maps and listings.
tags: [ingestion, youtube]
resource: app/services/news_fetchers/   # code or path this knowledge describes
---
```

`type` and `description` are the most useful. Frontmatter must stay valid YAML and must not break GitHub Markdown rendering. Do not require full OKF conformance yet.

### Drift checks

Run the dependency-free checker locally (also wired into `bin/validate` / `bin/validate --fast` and CI `docs_check`):

```bash
bin/check-docs
```

It fails on broken relative Markdown links under `docs/` (plus `AGENTS.md` / `CONTRIBUTING.md`) and on `docs/**/*.md` files missing from [index.md](index.md).

Continue updating `REPO_STRUCTURE.md` in the same change when project structure changes (existing rule).

## okf gem evaluation (deferred)

Spike against this tree with `okf` **1.12.0** ([#410](https://github.com/MarcosLorejan/dev-news-aggregator/issues/410)):

| Check | Result |
|-------|--------|
| `okf validate docs/` | **Fail** — `log.md` requires ISO `YYYY-MM-DD` headings only (our `## Earlier (seed)` is intentional seed text) |
| `okf lint docs/` | Exit 0 with noise — parent links like `../AGENTS.md` look “missing” because the bundle root is `docs/`, not the repo root |
| Frontmatter / types | Mostly fine (guides + decisions recognized) |

**Decision: do not add `okf` as a required CI dependency.** Keep `bin/check-docs` as the gate.

Reasons:

1. `docs/` is a **mixed** corpus (how-to + decisions + pointers to repo-root `AGENTS.md` / `CONTRIBUTING.md`), not a self-contained OKF bundle.
2. Making validate green would mean restructuring (dedicated sub-bundle, rewriting the log seed, treating root entry files as in-bundle concepts) for little gain over link/orphan checks we already run.
3. Lint’s parent-path “missing concept” warnings are false positives for our layout.
4. Revisit only if we extract something like `docs/knowledge/` (or `.okf/`) as a true OKF bundle and want graph/search/skill tooling.

Optional local experiment (not CI): `gem install okf` then `okf validate docs/` / `okf lint docs/`.

## What we skip for now

- Installing `okf` as a required dependency or CI job
- Rewriting guides into a full `.okf/` or OKF-conformant tree
- Graph server, registry, or Claude plugin from okf-gem
- Replacing `REPO_STRUCTURE.md` with an OKF index

## Writing durable *why*

Capture decisions agents cannot infer from code: trade-offs, rejected alternatives, operational quirks, API thinness vs richness.

Suggested shape for a concept/decision file:

1. **Context** — what forced the choice  
2. **Decision** — what we did  
3. **Consequences** — what follows (including footguns)  
4. Links to how-to guides + `resource:` path to code  

Initial decision set: [docs/decisions/](decisions/) ([#409](https://github.com/MarcosLorejan/dev-news-aggregator/issues/409)).

## Implementation roadmap

| Step | Issue |
|------|--------|
| Conventions (this doc) | [#406](https://github.com/MarcosLorejan/dev-news-aggregator/issues/406) |
| `docs/index.md` + light frontmatter on guides | [#408](https://github.com/MarcosLorejan/dev-news-aggregator/issues/408) |
| Durable why / decision concept files | [#409](https://github.com/MarcosLorejan/dev-news-aggregator/issues/409) |
| `docs/log.md` knowledge changelog | [#407](https://github.com/MarcosLorejan/dev-news-aggregator/issues/407) |
| Lightweight link / orphan checks | [#411](https://github.com/MarcosLorejan/dev-news-aggregator/issues/411) |
| Evaluate `okf` gem for CI | [#410](https://github.com/MarcosLorejan/dev-news-aggregator/issues/410) — **deferred** (see [okf gem evaluation](#okf-gem-evaluation-deferred)) |

## References

- [Why OKF](https://okfgem.com/docs/why-okf)
- [Bundle anatomy](https://okfgem.com/docs/bundle-anatomy)
- Closed milestone: [AI agent friendliness](https://github.com/MarcosLorejan/dev-news-aggregator/milestone/14)
