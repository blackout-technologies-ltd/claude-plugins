---
name: blackout-behaviour-guard
description: Use when reviewing a diff, branch or pull request in a Blackout mobile client (iOS or Android) that touches blocking, triggers, registration, permissions, the phone-home payload, configuration or hash sync, feature flags, the disable flow, push message handling, the network filtering or app-blocking services, or the shield - checks the change against the product guarantees in HOW-IT-WORKS.md. Applies during code review, pre-push checks and PR review. For a whole-codebase sweep with no diff, use blackout-architecture-audit instead.
---

# Blackout behaviour guard

## Overview

**First:** if the repo root has no `HOW-IT-WORKS.md`, this is not a Blackout mobile client repo. Say so and stop.

`HOW-IT-WORKS.md` at the repo root is the product contract, shared verbatim by the iOS and
Android clients. This skill applies it to a change. The question is not "is this code correct"
- other reviews cover that - it is **"after this change, does the app still do what Blackout
Mobile is supposed to do?"**

**Core principle: guarantees break through clean diffs.** The changes that have actually
broken these apps did not look wrong. Dropping a field from a request model, moving a write
off a path, tightening a parse - each is a small, tested, green diff, and each ends with the
server no longer hearing something it needs. Correctness review reads the diff. This review
reads what the diff was holding up.

**This file is method only.** What each guarantee depends on in *this* codebase is in
`.claude/blackout-behaviour-map.md` - read it first, particularly **What a change puts at
risk**, **Defence in depth**, **Landmines** and **Deliberate - do not report**. The map is a
cache maintained by `blackout-architecture-audit`, not a source of truth. If it looks stale,
fall back to `HOW-IT-WORKS.md` and say the map needs regenerating.

## Required for each guarantee the change touches

```
Guarantee:   <the sentence in HOW-IT-WORKS.md this change bears on>
Change:      <what the diff does to the path that upholds it>
Still holds: yes | no | unverifiable from the diff
Because:     <the specific mechanism, not a restatement of the diff>
```

Nothing at risk is a valid outcome - say so in one line and stop. A guard that always finds
something is a guard nobody reads.

## The five silent breaks

The shapes that have actually cost these apps working blocking. Check for them by shape, not
by file; the map records which of them have bitten this repository and where.

1. **A report stops being sent.** A value stops reaching the payload while the payload still
   has the field. Every presence check still passes.
2. **A branch stops phoning home.** State changes locally, the server never learns, and the
   next server decision is made on stale input.
3. **A parse gets stricter.** Narrowing an accepted encoding turns a block into a silent
   no-op. Widening is safe; narrowing needs to know what the server actually sends.
4. **A coordinated list gets half-updated.** Several places define one concept; updating all
   but one leaves a path that silently never fires.
5. **A hole gets closed on paper.** A detection is removed, softened or moved behind a flag
   without the underlying workaround being prevented. The contract is explicit: where the app
   cannot prevent, it must report.

## Constraints

- **Direction of the guarantee.** Over-blocking is worse than under-blocking here. A change
  that fails safe toward not-blocking is often deliberate - check the map before flagging.
- **Check the layers before calling a routing gap a drop.** A specific push route, a generic
  fallback phone home, then configuration hash comparison - each backstops the one above, so a
  missing route usually costs a round trip rather than the behaviour. See **Defence in depth**
  in the map. Report it as a defect only when every layer misses.
- **Do not ask for tests that cannot pass.** Unit tests here run against platform stubs;
  version-gated branches, intent targets and system schedulers are not assertable. Ask for a
  device check or an abstraction instead.
- **Comment on the change, not on pre-existing gaps** elsewhere in the file. A gap the diff
  did not create belongs in an audit, not this review.
- **Do not restate what the diff does.** Say what it puts at risk.
- **Advisory, not blocking.** Rank by consequence: a broken block outranks a broken report
  outranks a document that needs updating. Three real findings beat a checklist.
- **When the change is right and the document is wrong,** say which sentence of
  `HOW-IT-WORKS.md` needs updating. Do not edit it as part of a review.

## Red flags - stop and produce the required block

- "This is a refactor, behaviour is unchanged"
- "The field is still in the model" - is it still being *set*?
- "Tests pass"
- "This only touches the UI" - the home screen reports state, and settings drive the disable flow
- "The server will catch it on the next phone home" - only if this path still phones home
- "This just tidies up the push handling"
