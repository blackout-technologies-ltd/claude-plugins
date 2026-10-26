---
name: blackout-architecture-audit
description: Use when auditing whether this repository's Blackout client still does what the product contract says it should - a whole-codebase sweep against HOW-IT-WORKS.md. Triggered by "does the app still work the way it should", conformance or architecture review, pre-release checks, onboarding, or after a large refactor, dependency upgrade or backend contract change. Not for reviewing a single diff - use blackout-behaviour-guard for that.
---

# Blackout architecture audit

## Overview

**First:** if the repo root has no `HOW-IT-WORKS.md`, this is not a Blackout mobile client repo. Say so and stop.

`HOW-IT-WORKS.md` at the repo root is the product contract: what restricted mode means, what
triggers it, what the app must report when it cannot enforce. It is shared verbatim by the iOS
and Android clients and names no classes or files. This skill checks this repository's code
against it and reports where they have parted company.

**Core principle: the contract describes guarantees, not modules. A guarantee can break
without any single file looking wrong.** No module is named "report what we cannot enforce" or
"honour the server's decision". Those live spread across a request model, a dispatcher and a
push handler, and they fail by omission - a field that stopped being sent, a branch that
stopped ending in a phone home. You cannot find them by reading the code bottom-up. You start
from the guarantee and go looking.

**This file is method only.** Everything about *this* codebase - where each guarantee lives,
what the product words map to, which traps have caught previous runs - is in the behaviour map
described below. That split is deliberate: the method is identical for both clients, the
specifics are per-repository and rot when the code moves.

## The behaviour map

`.claude/blackout-behaviour-map.md`. Read it before starting, in full. It must carry:

| Section | What it holds |
|---|---|
| **Vocabulary** | product term from the contract -> symbol in this codebase |
| **Where to start reading** | each guarantee -> the files that have to be right for it to hold |
| **Platform mechanics** | detail the shared contract deliberately leaves out |
| **Defence in depth** | the layers that back each other up, so a gap in one is not automatically a defect |
| **Landmines** | traps that have caused a previous run to report something false |
| **Deliberate - do not report** | intentional behaviour, each row naming *why* |
| **Neighbouring repositories** | where the wire contract is actually defined |

If the map is missing or a section is empty, say so and derive what you need from the code -
then write it, because populating the map is half of what this skill is for. A first run
against a fresh repository is expected to produce a map, not to find one.

## Scope and authority

Report both directions. **Edit neither `HOW-IT-WORKS.md` nor the code.**

The one file this skill writes is the map, its own index. That is not an exception: the map is
this skill's finding, not a source of truth.

The contract is not automatically right. It was written from intent, and the code has had
production contact - some divergences are the code being correct and the document lagging. Say
which side you think is stale and why. Do not rewrite `HOW-IT-WORKS.md` to match what you
found, and do not "fix" code to match a sentence in it. Drift is a decision for a human.

## Never assert what the document says - go and read it

**Nothing in this skill or the map may be trusted about the *content* of `HOW-IT-WORKS.md`.**
That file is edited often. Any claim of the form "the contract does not mention X" is a dated
observation, not a fact. Three such claims once went stale and produced fabricated "the
document is out of date" findings in a real run.

Before reporting any divergence whose stale side is the document, quote the sentence you
searched for and say it is absent. If you cannot quote its absence, you have not checked.

Read `HOW-IT-WORKS.md` end to end before touching the map. Everything the map asserts is about
**code** for this reason - checkable against the repo, and it does not rot when the document
changes.

## Required for each guarantee

Emit this block. One per guarantee, no exceptions, including the ones that hold.

```
Guarantee:   <quote the sentence being tested>
Code path:   <files that have to be right for it to be true>
Status:      holds | partial | missing | diverged
Evidence:    <what you actually read - not what you assume>
Stale side:  code | contract | neither | unknown - and the reasoning
```

`neither` is for a deliberate limitation or an intentional design choice; a finding filed
against one of those is noise. `unknown` is a legitimate answer and better than a guess.

**Granularity: one block per testable claim, not one per section.** A section asserting four
separate things gets four blocks. Expect at least 25-35 blocks - one per testable claim,
however many that comes to. If you produce one per section, you have summarised the document
rather than tested it. `Evidence: read X, it does Y` is the
load-bearing line - a status without one is an opinion.

## Vocabulary is not a reliable index

`HOW-IT-WORKS.md` is platform-neutral, so its words are product words. Some appear verbatim in
the code. Others have no code presence at all. A few have **decoys** - a file whose name
matches the term while the behaviour lives somewhere else entirely.

So finding nothing, and finding one plausible file, are both worthless as evidence. Before
reporting anything `missing`, check the map's Vocabulary table, then search for the
*mechanism* rather than the name. Vocabulary failures are the largest single source of false
findings in this audit.

## Four checks worth running every time

The map's Landmines section carries the specific traps each of these has hit before. Read it
first; every trap listed there was found the hard way.

**1. Every push type ends in a phone home.** **Find where the phone home is actually called
first, then work backwards** to confirm every push type reaches it. Do not start from the
constant list and follow the switch: the switch on the type constant is often *not* the
dispatch. A parser that sets flags and a dispatcher that reads them are two separate functions,
sometimes in different files, and a `default:` case that only logs proves nothing about whether
the push is dropped - the fallback may be a terminal `else` in the dispatcher. Reading the
parser alone has produced a false "unrecognised pushes are dropped" finding on both clients.

Then watch for: a handler that returns early rather than falling through, a fallback that lives
in a different class from the one you are reading, a gate that matches case-insensitively
feeding a router that matches exactly, a constant declared but never routed, and a branch that
reports only on success.

**2. Every reporting field is still populated.** Walk the phone-home payload model field by
field and find what sets each one. Highest-yield check in the audit, and the easiest to get
wrong in both directions:

- A hardcoded default is a finding **only when nothing downstream overrides it**. Look for
  post-construction copies and builders before calling a constant a bug.
- **If serialisation is hand-written, read the encoder, not the field list.** A field can be
  declared, populated, and still not be what goes on the wire - encoders that substitute
  placeholder values inside conditional branches are invisible from the model.
- In a language with **positional** parameters, check argument order at the call site: a model
  built from same-typed positional arguments can be populated, correctly typed, fully tested
  and still carry the wrong values. Where the language forces argument labels or named
  parameters this hazard is structurally impossible - spend the effort on accessors returning
  stale caches instead.

**3. Every phone home says why it happened.** This guarantee fails at *call sites*, not in the
models, so a payload walk cannot see it. Find every dispatch and check which reason each one
declares. A site declaring a generic or borrowed reason while handling something specific is
mislabelling itself, and the server cannot tell those events apart. Some are deliberate and
carry a ticket comment - read it and report the conflict rather than resolving it.

**4. Every enforcement layer is actually shipped.** A guarantee can be fully implemented in
code that never runs. Confirm the module or target containing it is in the build, that any
flag gating it is written somewhere, and that any data it depends on is actually populated.
Equally, confirm where the decision is *taken* before concluding a mechanism is missing: a
layer implemented server-side looks identical to a layer that is absent if you only read the
client. Say which of the two you established, and how.

## Output

Two artifacts.

1. **The report** - a dated file in the repository's gitignored docs directory. Guarantee
   blocks, then findings ordered by consequence: a broken block outranks a broken report
   outranks a stale sentence in the document.
2. **The map** - `.claude/blackout-behaviour-map.md`, committed. Rewrite it whole; a
   half-updated map is worse than a missing one.

If your caller has told you not to edit files, put the map corrections in the report as an
applyable list and say the map was not written. Do not skip deriving them.

Record undecided divergences in the report. Never only in a commit message.

Open findings are tracked in Confluence, linked from the map. **Do not read that page before
auditing**: re-derive from the code, then compare, so a finding that has since been fixed drops
off and a new one is not lost among familiar ones. Say which of your findings are already
tracked and which are new. On a first run for a repository there is no such page yet - say so,
record every finding as new, and note that a page should be created.

## Common mistakes

- Reporting `missing` after grepping the contract's vocabulary. Check the map first.
- Auditing modules instead of guarantees. Reading a manager end to end tells you what it does,
  not whether the app still reports a disabled device.
- Treating the contract as automatically authoritative. It lags; say so when it does.
- Rewriting the document or the code. This skill reports.
- Skipping the guarantees that hold. The block for a passing guarantee is what makes the
  report a baseline rather than a bug list.
- Running the test suite for evidence. Unit tests here run against platform stubs and prove
  far less than they appear to; a green run is not evidence a guarantee holds and a red one is
  usually unrelated. Read the code, and say in `Evidence` that you did.
- Auditing only what changed recently. This is the whole-codebase skill - that is the point of
  it existing separately from `blackout-behaviour-guard`.

## Red flags - stop and produce the required block

- "This section is obviously still implemented"
- "The tests pass, so the guarantee holds"
- "I could not find it, so it must have been removed"
- "The contract is out of date here, I will just update it"
- "This is basically the same as reviewing the recent diffs"
