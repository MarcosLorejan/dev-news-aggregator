---
type: Guide
title: Pre-commit hooks setup
description: Overcommit install and Conventional Commits enforcement for local hooks.
tags: [tooling, git, overcommit]
resource: .overcommit.yml
---

# Pre-commit Hooks Setup

This project uses [Overcommit](https://github.com/sds/overcommit) to manage Git hooks that run automatically before commits and when writing commit messages.

Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/) (see below). The commit-msg hook enforces that format.

## What Gets Checked

### Pre-commit Checks
- **RuboCop**: Lints Ruby code for style violations
- **Brakeman**: Fails on new Rails security warnings (see `config/brakeman.ignore` for baselined findings)
- **Typecheck**: Runs `npm run typecheck` when TypeScript or related config files are staged
- **Bundle Audit**: Checks for vulnerable gem dependencies
- **Bundle Check**: Verifies Gemfile dependencies are satisfied
- **YAML Syntax**: Validates YAML file syntax

### Commit Message Checks
- **Message Format**: Enforces Conventional Commits (`type: subject` / `type(scope): subject`)
- **Empty Message**: Prevents empty commit messages
- **Text Width**: Enforces max 72 characters for subject, 80 for body
- **Trailing Period**: Disallows trailing periods in subject line

`CapitalizedSubject` is disabled because Conventional Commits use a lowercase subject after the type prefix (e.g. `feat: add bookmarks`).

## Installation

Hooks are installed automatically by `bin/setup` and `.\setup-local-env.ps1`. You can also install them manually:

### First Time Setup

1. Install the gems (if not already done):
```bash
bundle install
```

2. Install the Git hooks:
```bash
bundle exec overcommit --install
```

3. Sign the configuration (required; `verify_signatures` is enabled):
```bash
bundle exec overcommit --sign
```

That's it! The hooks will now run automatically.

After pulling changes to `.overcommit.yml` (or custom hook plugins), run `bundle exec overcommit --sign` again so signature verification stays in sync.

## Usage

### Normal Workflow
Just commit as usual:
```bash
git add .
git commit -m "feat: add new feature"
```

The hooks will run automatically before the commit is created. Messages that do not match Conventional Commits are rejected by the commit-msg hook.

### Skipping Hooks
If you need to skip hooks (not recommended), use:
```bash
OVERCOMMIT_DISABLE=1 git commit -m "message"
```

Or skip specific hooks:
```bash
SKIP=RuboCop git commit -m "message"
```

### Running Hooks Manually
Test what the hooks will do before committing:
```bash
bundle exec overcommit --run
```

### Updating Hook Configuration
After pulling changes to `.overcommit.yml`:
```bash
bundle exec overcommit --sign
```

## Common Issues

### "Hook failed" Messages
If a hook fails, you'll see output explaining what went wrong:
- **RuboCop failures**: Fix the style issues or run `bin/rubocop -a` to auto-fix
- **Brakeman failures**: Fix or baseline new findings (see `config/brakeman.ignore`)
- **Typecheck failures**: Fix TypeScript errors (`npm run typecheck`)
- **Bundle Audit failures**: Update vulnerable gems in Gemfile
- **YAML syntax errors**: Fix syntax in the affected YAML file
- **Message Format failures**: Rewrite the subject to Conventional Commits (examples below)

### `invalid byte sequence in UTF-8` on Windows

If every commit aborts before any hook runs, with a stack trace through `win32_symlink?` and a "Report this bug" banner:

```
invalid byte sequence in UTF-8
.../overcommit/utils/file_utils.rb:67:in `win32_symlink?'
.../overcommit/utils.rb:268:in `broken_symlink?'
.git/hooks/pre-commit:80:in `<main>'
```

your console is using a legacy code page. On Windows, Overcommit detects symlinks by shelling out to `dir` and regex-matching the output, but `dir` emits text in the console code page (CP 850 on a pt-BR console) while Ruby tags it as UTF-8. Overcommit checks every modified file this way, so this fires on any commit, not just ones touching symlinks.

Switch the console to UTF-8:

```powershell
chcp.com 65001
```

`.\setup-local-env.ps1` does this for you, but only for the console you run it in. To make it permanent, add it to your PowerShell profile:

```powershell
Add-Content $PROFILE "`nchcp.com 65001 > `$null"
```

Tracked in [#446](https://github.com/MarcosLorejan/dev-news-aggregator/issues/446); the underlying encoding bug is in Overcommit itself, not this repo.

### Signature Verification Errors
If Overcommit reports that the configuration signature changed:
```bash
bundle exec overcommit --sign
```

Do not set `verify_signatures: false` to bypass this; signing keeps local hooks aligned with the shared config.

### Hooks Not Running
If hooks aren't running:
```bash
bundle exec overcommit --uninstall
bundle exec overcommit --install
bundle exec overcommit --sign
```

### Performance
The hooks are designed to be fast where possible:
- RuboCop only checks staged files
- Typecheck runs only when TypeScript-related files are staged
- Bundle checks use caching
- Hooks run in parallel when possible

Brakeman scans the app and is slower; skip it for an urgent commit with `SKIP=Brakeman` only when necessary.

## Conventional Commits

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type: subject

body (optional; prefer a one-line subject — see docs/DEVELOPMENT.md)
```

Optional scope and breaking-change marker:

```
type(scope): subject
type(scope)!: subject
```

### Commit Types
- `feat:` - New feature
- `fix:` - Bug fix
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements
- `ci:` - CI configuration
- `build:` - Build system or dependencies
- `revert:` - Revert a previous commit

### Examples
```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve database connection issue"
git commit -m "test: add tests for article model"
git commit -m "refactor: simplify news fetcher logic"
git commit -m "feat(api): add article dismiss endpoint"
```

Invalid (rejected by the commit-msg hook):
```bash
git commit -m "Add user authentication"         # missing type prefix
git commit -m "feat: Add user authentication"   # subject must start lowercase
git commit -m "feat:add auth"                   # missing space after colon
```

## Disabling Hooks Permanently (Not Recommended)

If you really need to disable hooks:
```bash
bundle exec overcommit --uninstall
```

To re-enable:
```bash
bundle exec overcommit --install
bundle exec overcommit --sign
```

## CI/CD Integration

The same checks that run locally also run in CI:
- RuboCop (lint job)
- Bundle Audit (scan_dependencies job)
- Brakeman security scan (scan_ruby job)
- TypeScript check (typecheck job)

This ensures consistent code quality whether committing locally or via pull requests.
