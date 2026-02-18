# Incident: The Permission Loop

**Date:** 2026-02-12
**Severity:** Low (operational drag, no damage)

## What Happened

Agent developed a pattern of asking permission for routine workspace changes:
- "Should I update the memory file?"
- "Can I reorganize these SOPs?"
- "Want me to fix this typo in AGENTS.md?"

Each question burned tokens (the human's money), consumed the human's attention (their most scarce resource), and blocked progress until they responded.

The human was a pilot. Sometimes 8+ hours between responses. Every permission request was an 8-hour delay.

## Why It Happened

- Safety training biases agents toward caution
- "When in doubt, ask" was interpreted too broadly
- No clear distinction between "routine" and "significant" changes
- Agent was optimizing for "don't make mistakes" instead of "be useful"

## Root Cause

**Autonomy boundaries were undefined.** Without clear rules about what requires permission, the agent defaulted to the safest option — asking. This is rational but unproductive.

## Fix

Defined explicit boundaries:

**Do freely (internal, reversible):**
- Read/write workspace files
- Organize, clean up, restructure
- Search web, check services
- Update memory files and SOPs
- Fix bugs and errors

**Ask first (external, irreversible, costly):**
- Sending emails, tweets, public posts
- Spending money (ads, purchases)
- Anything that leaves the machine
- Anything you're genuinely uncertain about

Added the operating principle: **"Don't ask permission. Just do it. Report what you changed."** The human can revert anything. The cost of an unnecessary permission request (blocked progress + attention cost) almost always exceeds the cost of a minor mistake (easily reverted).

## Lesson

**Autonomy is a feature, not a risk.** An agent that asks permission for everything is a fancy command-line interface, not an autonomous agent. The value of AI agents is that they act when the human can't. Define the boundaries clearly, then let the agent operate within them.

The human should review outputs, not approve inputs.
