# Agent instructions

Use `bin/validate` before opening a pull request. It mirrors the main local
quality checks from CI:

```bash
bin/validate
```

For quick iteration, use the fast mode. It skips slower checks that usually need
more setup, such as Brakeman and Rails tests:

```bash
bin/validate --fast
```
