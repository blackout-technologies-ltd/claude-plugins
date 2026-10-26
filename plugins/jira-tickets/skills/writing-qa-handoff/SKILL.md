---
name: writing-qa-handoff
description: Use when a pull request for a BDM Jira ticket is opened or merged and the ticket needs a comment telling the manual QA tester what was done and how to test it on the develop environment - also when asked for test instructions, a QA note or a handoff for a ticket.
---

# Writing the QA handoff comment

## Overview

Merged PRs build into the **develop** environment, where a manual tester checks them on test phones and the dashboard / Apex. The tester does not read code. This comment tells them what changed, what automated tests already proved, and **where risk remains**, so they spend their time there. When writing a PR description, draft this alongside it from the same facts.

## Gather first

- The ticket (`BDM-…` from the branch): its Summary, How it should work / What actually happens, Steps to reproduce, Testing section.
- The PR: what changed, its Risk and Verified sections, the tests it adds.
- Whether the change is behind a feature flag: `customfield_10078` on Tasks; on Bugs, or when it's empty, check the code. No flag found → "none".
- The ticket's existing comments: if a QA handoff is already there, update it instead of adding a second one.
- For every step you plan: the screen or form field it uses (read the view/template on develop) and whether each platform actually receives the change (e.g. whether config sends that field to iOS).

## The comment

```markdown
**Ready to test on develop once #<PR> is merged.**  ← or "Merged in #<PR>; on develop now."

**What changed:** 1–3 sentences in product language: what the user/admin/device does now.

**Feature flag:** none · or the flag name and how to turn it on for the test org.

**Already covered:**
- <cases the PR's automated tests prove, in plain words>
- <device or environment checks the developer already ran (from the PR's Verified section or ticket comments), with who/when>

**Manual QA: <No manual QA needed | Targeted | Focused regression>**
<Why, in one line: what automated tests can't reach — real devices, OS versions, timing, push delivery, third-party services.>

Setup: org configuration, platform/app version, device state.
1. Step the tester can do on a phone or in the dashboard.
   Expected: what they should see.
<Focused regression only: "Also check: <area>, <area>" (at most 3)>

**Don't raise against this ticket:** known limitations and related issues left for other tickets.
```

## Manual QA levels

| Level | When |
|---|---|
| **No manual QA needed** | No observable behaviour change, fully covered by automated tests. Say why. |
| **Targeted** | Visible change: give the specific scenarios. |
| **Focused regression** | Touches shared machinery (blocking, phone-home, config sync, registration, VPN, permissions): scenarios plus up to 3 named neighbouring areas. |

## Rules

- **Every step must be doable on develop today.** A step using a field that doesn't exist, or a platform the change can't reach, makes the tester fail a working fix. Unaffected platforms go under "Don't raise", with the reason.
- **Steps use only what the tester can see and do:** app screens, the dashboard / Apex, device settings. No class names, endpoints or log greps unless the tester already uses that tool. Aim for 6 steps or fewer.
- **Name the traps** on a `Traps:` line after the steps: anything that would make a broken fix look fixed (e.g. "don't send a manual check-in, it hides the bug").
- **No invented facts:** no guessed timings ("within a minute") or counts. If timing matters and is unknown, write "note how long it takes".
- **No customer or personal data.**
- **Posting:** show the draft (together with the PR description when there is one) and, on the developer's OK, add it as a comment on the ticket with the available Atlassian/Jira tool. Don't change the ticket's status; the PR automation does that.
