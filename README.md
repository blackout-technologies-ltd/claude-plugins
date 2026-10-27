# Blackout Claude Code plugins

Shared skills for the engineering team.

## Install

```
/plugin marketplace add blackout-technologies-ltd/claude-plugins
/plugin install pr-descriptions@blackout
/plugin install jira-tickets@blackout
/plugin install client-contract@blackout  # Mobile only, for architectural reviews, etc
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

## jira-tickets

| Skill | Use it for |
|---|---|
| `writing-jira-tickets` | New or rewritten BDM tickets: product language first (how it should work / what actually happens, repro steps), technical notes last, what automated tests should cover and how much manual QA it needs |
| `writing-qa-handoff` | The Jira comment for the manual tester when a PR is opened: what changed, what tests already prove, where risk remains, steps on phone / dashboard |
| `backfilling-tickets-from-prs` | Legacy tickets: compares the ticket with its PRs (ticket says vs PRs did, undelivered criteria, which build has the fix), then proposes a rewritten ticket and a handoff or "what was shipped" comment |

With both plugins installed, `writing-pr-descriptions` drafts the handoff comment alongside the PR description, and both are posted on one approval. Uses whichever Atlassian/Jira MCP tool you have; without one it prints the text for pasting.

## client-contract

| Skill | Use it for |
|---|---|
| `blackout-behaviour-guard` | Reviewing a client diff that touches blocking, registration, phone-home, config sync, push or the shield |
| `blackout-architecture-audit` | Whole-codebase sweep of a client against `HOW-IT-WORKS.md` |

Only for the iOS and Android clients: both skills read `HOW-IT-WORKS.md` from the repo root and stop if it isn't there. Enable it in those repos' `.claude/settings.json` (`"enabledPlugins": {"client-contract@blackout": true}`) rather than for every repo.

The source of truth is now this repo; the copies in `android/.claude/skills/` and `ios/.claude/skills/` are still there and will drift until they're removed.

## Changing a plugin

Bump `version` in the plugin's `.claude-plugin/plugin.json` whenever you change its files. Installed copies only refresh when the version changes; otherwise `/plugin marketplace update` leaves everyone on the old skills.
