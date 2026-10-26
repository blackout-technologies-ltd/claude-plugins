---
name: backfilling-tickets-from-prs
description: Use when a legacy or existing BDM Jira ticket is thin, out of date or too technical and its work has already been done in one or more PRs - comparing a ticket against its PRs, back-filling or reconciling the ticket from what was actually shipped, or checking whether a PR delivered what the ticket asked.
---

# Back-filling tickets from their PRs

## Overview

Old tickets often say less (or something different) than what was shipped. The PRs are the record of what was actually done; the ticket is what the product owner and the manual tester read. This skill reconciles the two: it reports where they disagree, then proposes a rewritten ticket and, if none exists, a QA handoff comment. **REQUIRED:** use the templates and rules in `jira-tickets:writing-jira-tickets` and `jira-tickets:writing-qa-handoff`; this skill adds only the comparison.

## Gather first

1. The ticket with its comments: summary, description, status, issue type, labels, `customfield_10078`.
2. Its PRs: `gh search prs "<KEY>" --owner blackout-technologies-ltd --json number,repository,title,state,url` (base branch via `gh pr view`), plus PRs linked on the ticket's development panel if your Jira tool shows them. **Skip release PRs** (develop→master, "Prod candidate"); they bundle many tickets. Check each remaining PR's diff actually belongs to this ticket.
3. For each PR: body, diff, tests added, review comments, merge state and date.
4. Builds: the first develop build/version that contains each merge (`git tag --contains <merge>` or the version-bump commits after it) and the production release it shipped in. Repos without tags: use the version-bump commits after the merge (`git log --ancestry-path <merge>..origin/develop`). The master merge is the release candidate; say so if the store/deploy date isn't known. Compare with any test results in the ticket comments: a "tested" comment on a build without the fix is a disagreement.

## The comparison

Show this first, before any proposed edit:

```markdown
**BDM-1234 vs <repo>#<n>[, <repo>#<m>]**

| | Ticket says | PRs did |
|---|---|---|
| Problem / goal | … | … |
| Platforms affected | … | … |
| Fix / scope | … | … |
| Acceptance criteria | <each one, or "none written": use the implied goal> | done / partly / not done (why) |

**Disagreements:** ticket claims the code contradicts (e.g. "iOS affected" when iOS never receives the data), and work in the PRs the ticket never mentions.
**Gaps in the fix:** cases the PR doesn't handle, found by reading the code. Mark each "from code reading, not verified on a device".
**Not delivered:** acceptance criteria or asks with no matching change → follow-up ticket candidates.
**Status check:** e.g. "Done, but PR #n is still open", "In QA with no handoff comment", "tested on 2.6.48; fix first in 2.6.49".
**Builds:** first develop build with the fix · production release.
```

## Then propose

- **Ticket rewrite:** the `writing-jira-tickets` template, filled from the ticket's original facts (reporter's repro, customer impact, dates) plus what the PRs show. Keep every original fact that is still true; correct the wrong ones and say which in the comparison. Fix labels and fields, and retitle to the `<platform> - <short description>` form (e.g. "iOS VPN bug - clean install" → `iOS - First VPN connect after a fresh install can block all internet`).
- **QA handoff comment:** per `writing-qa-handoff`, only if the ticket has none and is not yet Done. For a Done ticket, add a short "What was shipped" comment instead (PRs, what changed, release if known).
- **Fix Version (iOS/Android tickets):** if the work has shipped and the ticket has none, propose `<version> Mobile App - iOS|Android` for the production release found in Builds, created the same way as in `pr-descriptions:writing-release-pr-descriptions`.
- **Follow-ups:** one line each for undelivered items and gaps in the fix; create them only if asked.
- **Done tickets:** the rewrite's Testing section records what was covered and what QA checked (on which build), not a plan.

## Rules

- **The PR diff is the evidence**, not the PR title or the ticket. Where they disagree, say what the code shows and where (file/function), in the comparison only.
- **Old tickets carry personal data** (user IDs, school/org names, people's emails). Don't carry them into the rewrite; describe the setup instead.
- **Untried test setups are labelled:** a way to force a failure that nobody has run (e.g. a dead DNS server) is marked "untested setup" in the step itself.
- **Don't lose the original:** before rewriting a description, save the current one (it goes in the comparison output) so the developer can restore it.
- **Thin PR descriptions:** if a PR's own description also needs back-filling, offer `pr-descriptions:writing-pr-descriptions` for it; this skill only edits Jira.
- **Writing:** show the comparison and proposed changes; apply each (description, comment, fields) only on the developer's OK, with the available Atlassian/Jira tool. Don't change ticket status.
