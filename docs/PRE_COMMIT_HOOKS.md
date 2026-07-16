# Pre-commit Hooks Setup

This project uses [Overcommit](https://github.com/sds/overcommit) to manage Git hooks that run automatically before commits and when writing commit messages.

## What Gets Checked

### Pre-commit Checks
- **RuboCop**: Lints Ruby code for style violations
- **Brakeman**: Fails on new Rails security warnings (see `config/brakeman.ignore` for baselined findings)
- **Bundle Audit**: Checks for vulnerable gem dependencies
- **Bundle Check**: Verifies Gemfile dependencies are satisfied
- **YAML Syntax**: Validates YAML file syntax

### Commit Message Checks
- **Capitalized Subject**: Ensures commit message starts with capital letter
- **Empty Message**: Prevents empty commit messages
- **Text Width**: Enforces max 72 characters for subject, 80 for body
- **Trailing Period**: Disallows trailing periods in subject line

## Installation

### First Time Setup

1. Install the gems (if not already done):
```bash
bundle install
```

2. Install the Git hooks:
```bash
bundle exec overcommit --install
```

3. Sign the configuration (one-time):
```bash
bundle exec overcommit --sign
```

That's it! The hooks will now run automatically.

## Usage

### Normal Workflow
Just commit as usual:
```bash
git add .
git commit -m "feat: add new feature"
```

The hooks will run automatically before the commit is created.

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
- **Bundle Audit failures**: Update vulnerable gems in Gemfile
- **YAML syntax errors**: Fix syntax in the affected YAML file

### Hooks Not Running
If hooks aren't running:
```bash
bundle exec overcommit --uninstall
bundle exec overcommit --install
bundle exec overcommit --sign
```

### Performance
The hooks are designed to be fast:
- RuboCop only checks staged files
- Bundle checks use caching
- Hooks run in parallel when possible

## Conventional Commits

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type: subject

body (optional)
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

### Examples
```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve database connection issue"
git commit -m "test: add tests for article model"
git commit -m "refactor: simplify news fetcher logic"
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

This ensures consistent code quality whether committing locally or via pull requests.
