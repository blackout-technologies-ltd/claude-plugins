---
name: releasing-backend-to-production
description: Use when asked to release, ship, deploy or push the Laravel backend (backend-web-laravel, the dashboard) to production, cut or tag a release on master, publish a GitHub release, or write and post the release notes for a backend release to Slack.
---

# Releasing the backend to production

## Overview

**Publishing a GitHub Release on `backend-web-laravel` deploys production** (`aws_prod.yml` runs on `release: published`). So this skill gathers and drafts everything first, gets **one approval**, then publishes, then posts to Slack.

Two sets of notes, two audiences:

| | GitHub release | Slack |
|---|---|---|
| Reader | Engineers | Customer success, sales, product: non-technical |
| Content | GitHub's generated "What's Changed" list, unedited | What customers and staff will notice, in plain words |
| Where | The release body | `#product-dashboard` (`C03G9TYCXSN`) |

## 1. Check master is ready

Run from the backend repo. Nothing here changes anything.

```bash
REPO=blackout-technologies-ltd/backend-web-laravel
git fetch origin master develop --tags
PREV=$(gh release view --repo $REPO --json tagName --jq .tagName)   # latest release
git log --oneline "$PREV"..origin/master | head                     # empty → nothing to release, stop
git merge-base --is-ancestor origin/master origin/develop && echo "STOP: master is inside develop"
gh pr list --repo $REPO --base master --state open --json number,title
```

- **Nothing new since `$PREV`:** stop and say so.
- **"STOP: master is inside develop":** the deploy workflow rejects this commit. The release PR was probably fast-forwarded; ask the user.
- **An open PR into master** (usually "Prod candidate"): the release is not merged yet. Tell the user and stop; merging it is their call.

## 2. Work out the tag

`v<Y>.<MM>.<DD>` from today's date in UK time: `Y` is the last digit of the year (2026 → `6`, 2027 → `7`), month and day zero-padded.

```bash
TAG="v$(TZ=Europe/London date +%y.%m.%d | cut -c2-)"   # 16 Nov 2026 → v6.11.16
git tag --list "$TAG*"
```

If `$TAG` already exists (second release that day), append a digit: `v6.10.05` → `v6.10.051`, then `…052`.

## 3. Preview the GitHub notes

This call creates nothing:

```bash
gh api repos/$REPO/releases/generate-notes -f tag_name="$TAG" \
  -f target_commitish=master -f previous_tag_name="$PREV" --jq .body
```

This list is both the GitHub release body and the source for the Slack notes.

## 4. Draft the Slack notes

Work from the PR titles in the preview. Where a title does not tell you what a customer would notice, read the PR (`gh pr view <n> --json title,body`); do not guess.

Shape (standard Markdown; the Slack tool converts it). Leave out a section with nothing in it:

```markdown
:rocket: **Blackout platform release <TAG> (<D Month YYYY>)**

**New for admins**
- **<Short name>:** <what they can now do, one sentence>

**A fresher dashboard**            ← pages moved to the new design, as one short paragraph
**Improvements and fixes**
**Privacy and security**
**Heads-up: things we've changed or retired**
```

- **One sentence per item, about what the reader sees or can do**, in the words on the screen ("Wi-Fi networks", "check-ins"), not the code's ("Svelte", "queue", "endpoint", "job").
- **No ticket keys, PR numbers, author names or links.**
- **Leave out** what no customer or colleague would notice: dependency and framework updates, CI, build, refactors, removed dead code, merge-backs. Security patches become one line: "The latest security updates have been applied."
- **Leave out a fix for something introduced in this same release.** Nobody outside the team saw it broken.
- **Say when something is not for everyone:** behind a feature flag, rolled out one organisation at a time, or Apex/super-admin only.
- **Heads-up items need a fact, not a guess.** For anything retired, removed or newly restricted, the reader's question is "does this affect my customers?". If the PR does not answer it, put the question to the user in the approval step and write the line from their answer ("This hasn't been used in a long time, so no action is needed").
- **No customer or personal data** (school or organisation names, people, emails).
- Under 5000 characters (the Slack tool's limit per message).

## 5. One approval

Show the user, in one message:

1. The tag, the commit it will point at (`git log -1 --format='%h %s' origin/master`) and the previous tag.
2. The number of PRs included, and that publishing **starts the production deploy**.
3. The Slack draft in full, and the channel.
4. Any heads-up questions from step 4.

Wait for a yes. An earlier "do the release" is not approval of a draft they have not seen.

## 6. Publish, then post

```bash
gh release create "$TAG" --repo $REPO --target master --title "$TAG" \
  --generate-notes --notes-start-tag "$PREV"
gh run list --repo $REPO --workflow aws_prod.yml --limit 1 --json url,status --jq '.[0]'
```

Then post the approved draft to `#product-dashboard` with your Slack tool (no Slack tool: print it for pasting). Post once the release is published; the notes say what is in the release, not that the deploy has finished.

Report: the release URL, the deploy run URL and its status, and the Slack message link. If the user wants to know when it is live, `gh run watch <id> --repo $REPO --exit-status`.

## If something goes wrong

- **`gh release create` fails:** nothing was deployed. Do not post to Slack. Report the error.
- **The deploy run fails after publishing:** report it with the run URL. Do not delete the release or tag, and do not re-publish, without the user saying so.
- **A hotfix release** (a fix merged straight to master) uses the same steps; title it `<TAG> Hot Fix` and keep the Slack note to the one fix.
