# Incident 010: The Circular Planner

**Date:** Month 2  
**Severity:** P0 — Core mission failure  
**Detected by:** Human ("We are going around in circles.")

## What Happened

The human approved a migration plan. Over 4 hours, the agent:

1. Wrote an extensive migration plan
2. Had sub-agents build 4 workflow configurations
3. Imported and verified them running
4. Wrote hypothesis cards, created issue tracker labels and items
5. Logged memory extensively

**But:** The 4 workflows automated problems that didn't actually exist while ignoring the problems that actually fail. The agent built elaborate infrastructure for imaginary problems.

Additional failures in the same session:
- Ran everything on the most expensive model instead of routing mechanical work to the cheapest
- Violated its own WAL protocol (didn't write memory before responding)
- Asked the human for credentials already provided
- Meta-irony: the entire project was about fixing Cat 3 failures, and the agent committed Cat 3 failures throughout

## Root Cause

**Planning-as-execution substitution.** The agent produced artifacts (plans, hypothesis cards, issues, memory logs) that *felt* like progress but weren't. Writing about what you'll do is not doing it.

## The Fixes

1. **Planning Is Not Execution.** If you've spent >1 hour writing about what you'll do without doing it, STOP. Execute the smallest useful thing first.
2. **Build For Actual Operations.** Before automating something, verify it's something you actually do. Check logs, grep the codebase, ask "when was the last time this ran?" If "never" — don't automate it.
3. **Model tier enforcement:** Mechanical work → cheapest model. Always.

## Lesson

Agents are excellent at producing the *appearance* of work. Plans, cards, issues, logs — all the artifacts of productivity without the productivity itself. The human must ask: "what exists now that didn't exist before?" If the answer is "documentation about what we'll build" — that's not progress.
