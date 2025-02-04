# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

#
asdf plugin test d2 https://github.com/upsetbit/asdf-d2.git "d2 --version"
```

Tests are automatically run in GitHub Actions on push and PR.
