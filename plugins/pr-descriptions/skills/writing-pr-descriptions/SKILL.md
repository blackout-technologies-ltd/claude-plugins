---
name: writing-pr-descriptions
description: Use when opening a pull request, writing or improving a PR description, or back-filling the body of an existing or merged PR whose description is empty, thin or just commit links. For develop→master release / prod-candidate PRs use writing-release-pr-descriptions instead.
---

# Writing PR descriptions

## Overview

A PR description tells a reviewer **why** the change exists, **how big** it really is once tests are separated out, **what could break**, and **how far it was actually verified**. It is short and scannable (aim for under ~450 words excluding tables). Reviewers read it first; future readers find it via `git blame`.

## Gather first

1. Ticket: the `BDM-…` id from the branch name. Read the Jira ticket for the user-facing symptom.
2. Diff and history: `gh pr view <n>` / `gh pr diff <n>` (back-fill) or `git diff origin/develop...HEAD` + `git log` (new PR). Read the existing body, commit messages and review comments: verification claims come from there.
3. Scope: run `bash <plugin root>/scripts/pr-scope.sh [base]` (the plugin root is two directories above this skill's base directory) from inside the repo (default base `origin/develop`; it detects Android, Laravel, iOS, Go, dbt and Terraform). Paste its output, then replace the `<!-- goal -->` and empty "Where to look" placeholders. For a merged PR, run it in a temporary `git worktree add --detach <dir> <headRefOid>` with base `<baseRefOid>` (from `gh pr view <n> --json headRefOid,baseRefOid`), then remove the worktree.
4. Risks: check the stack's items in `stack-risks.md` (same directory as this file).

## The description

Fill in every section, in this order. A section with nothing to say gets a one-line answer, not removal (except "Not in this PR").

```markdown
## Why
1–3 sentences: the symptom or the ask, and the signal (Crashlytics issue + events/users, customer report, ticket). If it is a bug, the root cause in one more sentence.

## Scope
> **N files, one goal: <the goal in a few words>.** Tests: N files. Production: +A / −D across N files.
<pr-scope.sh table, plus its collapsed "By area" block when it prints one>

**Where to look:**
- `path/to/File`: the one thing it does in this PR
<2–4 bullets: the files that carry the logic; say which ones are pure deletion or mechanical>

## Change
- One bullet per behaviour change, stated as what the code now does, plus the non-obvious reason when there is one.
- Mechanical work (renames, warning fixes, moves) gets one bullet at the end.

## Risk
- What could behave differently in prod and for whom. Migrations, permissions, config/env, dependency or manifest/entitlement changes (from stack-risks.md). How existing data/devices are repaired.
- "None: refactor only" is a valid answer when true.

## Verified
- **Automated:** which suites/tasks ran and their result (with counts if known), and the tests this PR adds.
- **Manual / device:** device or environment, then the scenarios that were run.
- **Not verified:** anything not run. "Not device-tested" is a valid answer.

## Not in this PR
- Deliberate omissions and follow-ups, with the reason. Delete the section if none.
```

Title: `BDM-1234: <what users/the system now do>` in plain words, not the branch name.

## Rules

- **Verification is evidence only.** Write only what the body, commits, comments, CI or the author show was run. If you can't find evidence, put it under **Not verified**; never imply testing happened. A repro run before the fix belongs in Why, not Verified.
- **One ticket key: the PR's own.** Jira auto-transitions any `BDM-…` key that appears in a PR body, so describe related work in words or link PRs by number (`#592`).
- **No customer or personal data:** no school/org names, user IDs, emails or device IDs; say "a school reported…".
- **Production vs tests stay separate** in Scope and Verified; test lines never inflate the production size.
- **Back-filling an existing PR:** keep correct facts from the current body, fix wrong ones (and say so to the user). Show the draft and get the user's OK before `gh pr edit <n> --body-file <file>`; never overwrite a body unseen.

## QA handoff

If the PR has a `BDM-…` ticket and the `jira-tickets:writing-qa-handoff` skill is available, draft that Jira comment from the same Risk and Verified facts and present it with the PR description for one approval.

## Example

github.com/blackout-technologies-ltd/employee-client-android-java/pull/604 is the reference shape.
