---
name: writing-jira-tickets
description: Use when creating, writing or rewriting a Jira ticket (bug, task, story) in the BDM project, turning code-review findings, Crashlytics issues, customer reports or technical notes into a ticket, or when a ticket is too technical for the product owner or the manual QA tester to follow.
---

# Writing Jira tickets

## Overview

A ticket has three readers: the **product owner** (what is wrong or wanted, for whom, why it matters), the **developer** (technical detail), and the **manual tester** (how to tell it works, and how much testing it deserves). Lead with plain product language; put code-level detail in its own section at the end. The tester has test phones (Android and iOS) and the dashboard / Apex on the develop environment, and does not read code.

## Gather first

- The source: review notes, Crashlytics issue, customer report, Slack thread, or the developer's description.
- Enough code/context to state **user-visible impact**: who is affected (which orgs, platform, setting) and what they see. If it's not knowable, say so instead of guessing.
- Search Jira for duplicates (`project = BDM AND text ~ "<keywords>" AND statusCategory != Done`). On a match, stop and show it: the draft becomes a proposed rewrite of that ticket's summary/description, applied only on the developer's OK. Mention closely related tickets so they can be linked.

## Bug template

```markdown
## Summary
1–2 sentences in product language: what goes wrong, for whom, and the consequence.

## How it should work
What the user, admin or device should experience. No class names.

## What actually happens
What they experience instead. How it was found (customer report, Crashlytics: N events / N users, code review, QA) and how often.

## Steps to reproduce
Environment: develop / production · platform + app version · device · org setup needed.
1. …numbered, using only what the tester can do on a phone or in the dashboard.
Expected: … · Actual: …
<If there is no reliable repro, say exactly that and why (e.g. "timing-dependent race found in code review"), then give the best-effort steps.>

## Testing
**Automated tests should cover:** the cases unit/feature tests must prove, including the one that fails today.
**Manual QA:** <No manual QA needed | Targeted | Focused regression> — see levels below. One line on what remains risky after automated tests.

## Technical notes (for developers)
Cause, files/functions (names, not line numbers), suggested fix, alternatives considered, link to the source (review page, Crashlytics issue, Slack thread). Optional for bugs found by non-developers.
```

## Task / story template

```markdown
## Summary
1–2 sentences: what changes for users/admins and why it matters.

## Background
The problem or opportunity in product language. User story if it helps ("As a school admin, I want… so that…").

## Requirements / acceptance criteria
- Observable outcomes the PO and tester can check ("An admin can…", "The device shows…").

## Testing
**Automated tests should cover:** …
**Manual QA:** <level> — what remains risky after automated tests.

## Out of scope
- …and open questions, if any.

## Technical notes (for developers)
Approach, affected repos, migrations, API changes. Optional.
```

## Manual QA levels

Pick one. "Regression" on everything wastes the tester's time; name the areas instead.

| Level | When | Write |
|---|---|---|
| **No manual QA needed** | Internal refactor, logging, CI, code with no observable behaviour change, fully covered by automated tests | Why nothing is observable |
| **Targeted** | The change has a visible effect | The specific scenarios to check |
| **Focused regression** | The change touches shared machinery (blocking, phone-home, config sync, registration, VPN, permissions) | The scenarios **plus** at most 3 named neighbouring areas: "regression with focus on geofence blocking, dashboard block toggle" |

## Fields

| Field | Value |
|---|---|
| Project | `BDM` |
| Issue type | Bug (something that worked or should work doesn't) · Task (a change) · Story (user-facing feature) · Spike (investigation) |
| Summary | Always `<platform> - <short description>`. Platform is one of `Android`, `iOS`, `Backend`, `Infra`, `Web`; when several are affected, join them with `/` (`Backend/iOS - …`). The description is a short plain outcome, not class names: `Android - Location block can be missed when entering a geofence during a config update`. |
| Labels | Lowercase platform labels, one or more of `android`, `ios`, `backend`, `dashboard` (`devops` for infra); topic labels optional. Older tickets use `Android` / `iOS` / `BackEnd`; when rewriting one, switch to lowercase. Required on Tasks. |
| Feature flag + validation (`customfield_10078`, required on Tasks; shows as "No") | No flag → `No, validate in develop` (id `10048`) · behind a flag, testable on develop → `Yes, validate in develop` (`10046`) · behind a flag, only testable in production → `Yes, validate in production` (`10047`) |

## Rules

- **Product language first.** The first three sections must make sense to someone who has never opened the code. Class names, line numbers and lock names live in Technical notes.
- **Repro and QA steps must be doable** with the screens and fields that exist on develop, on platforms the issue actually affects. Check the UI/view before writing a step.
- **No invented facts.** No guessed timings, counts or customer impact; write "unknown" or leave it to the reporter.
- **No customer or personal data:** no school/org names, user IDs, emails or device IDs; describe the org setup instead ("an education org with geofence blocking").
- **Creating it:** show the developer the draft, then create it with the available Atlassian/Jira tool (Markdown description). With no Jira tool, output it for pasting.
