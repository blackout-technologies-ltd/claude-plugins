---
name: writing-release-pr-descriptions
description: Use when opening, describing or back-filling a release pull request - develop→master, "Prod candidate", "Prod push", "Test release", production candidate or release branch PRs - for the reviewers and QA who sign the release off.
---

# Writing release PR descriptions

## Overview

A release PR description is a **sign-off sheet**: what is in it (by PR), what changes in production behaviour, what QA must exercise, and what to watch after deploy. Each included PR already has its own description; this one summarises and links, it does not repeat them.

## Gather first

The script is `scripts/pr-scope.sh` at the plugin root: two directories above this skill's base directory.

1. Range: for a new release, `BASE=origin/master HEAD=origin/develop`. For an existing or merged release PR, `gh pr view <n> --json baseRefOid,headRefOid` and use those SHAs.
2. Previous release: the merged PR into master whose merge commit is `BASE` (`gh pr list --base master --state merged -L 5 --json number,title,mergeCommit`). Titles vary ("Test release", "fixes to testflight"); go by the commit.
3. Included PRs: `git log --format='%h %s' BASE..HEAD` and collect the PR numbers (`(#123)` or `Merge pull request #123`); `gh pr view <n> --json title,body` for each, as the source for fixes, risk and QA. Commits with no PR and a net effect go under Other changes as `direct: <sha>`.
4. Scope: run `pr-scope.sh BASE` with HEAD checked out. For a merged PR, use a temporary `git worktree add --detach <dir> HEAD`, then remove it.
5. Platform diff: the stack's bold items in `../writing-pr-descriptions/stack-risks.md`, diffed `BASE..HEAD`. Include the actual diff in a `<details>` block when it is short.
6. Prod signals: Crashlytics / Sentry / alert counts (events / users) from the PR bodies. With no count, write how it was found ("customer report", "code review").

## The description

Title: `Prod candidate <version>` (no version: `Prod candidate`).

```markdown
# Release: develop → master (production candidate)

Merges `develop` into `master` for the next production release. Built since #<previous release PR>. Version <old> → <new> (if versioned).

**Pending QA sign-off.**   ← change to "QA signed off by <who>, <date>" when true

<2–4 sentences: the themes of this release, in plain words.>

## Crash and bug fixes
| PR | Fix | Prod signal |
|---|---|---|
| #N | <one line> | <events / users, or alert name> |

## Other changes
| PR | Change |
|---|---|
| #N | <PR title, one line> |
<newest first; chores and CI included>

## Scope
<details><summary>Files changed since #<previous release></summary>
<pr-scope.sh output, goal filled in with the themes>
</details>

## Risk
- **<Platform diff item>:** what changed, or "no change". <details> with the diff if short.
- **<Behaviour change> (#N, #M):** what production will do differently and who notices (users, dashboard, backend load).
- Migrations / data: list them, or "No database migrations."

## Testing / QA focus
- <Scenario to exercise, with the expected result> (#N)
<one or more per user-visible change; include upgrade-over-existing-install / existing-data paths>

## Watch after release
- **<Dashboard, alert or Crashlytics issue>:** what should rise, fall or clear, and which PR it proves.
```

## Fix Version (iOS and Android releases)

Each app release gets a Jira Fix Version so tickets show which release carries them. Backend and other repos skip this.

1. Name: `<version> Mobile App - iOS` or `<version> Mobile App - Android` (the existing BDM convention), with the version from `MARKETING_VERSION` in `project.pbxproj` or `VERSION_CODE` in `version.properties` at HEAD.
2. Tickets: the `BDM-…` key from each included PR's branch or title (the PR's own ticket only). Skip a ticket whose work is split across PRs (`gh search prs "<KEY>" --owner blackout-technologies-ltd`) that are not all in this release, and say so.
3. In the draft shown to the user, **not** in the PR body: the version name, whether it exists yet, and the tickets to tag, with their current Fix Versions (JQL `key in (…) AND fixVersion is not EMPTY`; a plain search may not return the field).
4. On the user's OK: find the version (`getJiraProjectVersions`, a read; compare trimmed names, one old version has a trailing space); create it unreleased if missing (`manageJiraProjectVersion` with `action: create`, which the Atlassian MCP runs as a destructive-tier call); **add** it to each ticket's Fix Versions, keeping any already there. If your Jira tool can't create versions (permissions), give the list to a Jira admin. Mark the version released only when the user says the store release has gone out.

## Rules

- **Link PRs, never ticket keys.** Jira auto-transitions any `BDM-…` key in a PR body; a release PR would drag every included ticket back to "IN PR". The included PRs carry the keys.
- **One line per table cell.** Detail lives in the linked PR.
- **QA status is literal.** Keep "Pending QA sign-off" until someone says otherwise; never write that QA passed.
- **No customer or personal data** (school/org names, user IDs, emails). Included PR bodies often contain them; don't carry them over.
- **Back-filling or updating:** show the draft and get the user's OK before `gh pr edit <n> --body-file <file>`.

## Example

github.com/blackout-technologies-ltd/employee-client-android-java/pull/608 is the reference shape.
