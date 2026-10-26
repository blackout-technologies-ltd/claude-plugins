# Blackout Claude Code plugins

Shared skills for the engineering team.

## Install

```
/plugin marketplace add blackout-technologies-ltd/claude-plugins
/plugin install pr-descriptions@blackout
```

Update later with `/plugin marketplace update blackout`.

## pr-descriptions

| Skill | Use it for |
|---|---|
| `writing-pr-descriptions` | Feature / fix PRs: writing a new description or back-filling a thin one (`/pr-descriptions:writing-pr-descriptions 1234`) |
| `writing-release-pr-descriptions` | develop→master prod candidates |

Both use `plugins/pr-descriptions/scripts/pr-scope.sh`, which prints the Scope table (production vs tests vs config, by area) for Android, Laravel, iOS, Go, dbt and Terraform repos. It also runs on its own:

```
bash pr-scope.sh                 # vs origin/develop
bash pr-scope.sh origin/master   # release scope
bash pr-scope.sh --help
```

Reference examples: android #604 (feature), android #608 (release).
