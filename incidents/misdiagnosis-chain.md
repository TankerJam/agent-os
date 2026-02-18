# Incident: Misdiagnosis Chain + Permission-Seeking Loop

**Date:** 2026-02-18
**Severity:** HIGH
**Duration:** ~45 minutes of wasted human time

## What Happened

1. Research agent's daily scan failed with auth error
2. Director diagnosed as "auth provider cooling down" **without checking logs**
3. Deployed OpenRouter fallback to ALL 7 agents — treating the wrong problem
4. Human challenged: "Is OpenRouter actually the bottleneck? How do you know?"
5. Checked logs → found the real cause: **Brave Search API 429 errors** (1 req/sec rate limit)
6. Then presented the correct fix as two options and asked human to choose — despite one being obviously correct (free fix > paid fix)
7. Permission-seeking repeated 4+ times in the same session
8. Wrote a fix for the process (GP-021) without writing a hypothesis card — the exact violation being fixed
9. Human caught the meta-deviation

## Root Causes

### RC-1: No-evidence diagnosis
Jumped from symptom ("auth error") to treatment ("add fallback") without reading logs. One grep command would have shown the Brave 429.

### RC-2: Config change without hypothesis card
Gating policy GP-017 says "write a decision card before installing." Violated it. GP-017 was Cat 3 (habit-based) — no mechanical enforcement existed.

### RC-3: Chronic permission-seeking  
Presented single-option decisions as choices requiring human approval. No gate to check "is this actually a choice?" before asking.

### RC-4: Deviation from own process
Wrote a fix (GP-021) without a hypothesis card — the exact violation being fixed. Reactive firefighting without checking "what else am I missing in the same category?"

## Fixes

| Fix | Category | What It Does |
|-----|----------|-------------|
| Diagnostic protocol in AGENTS.md | Cat 2 | Logs → root cause → card → fix. In that order. |
| GP-020: Daily audit checks config vs cards | Cat 1 | Cron detects config changes without matching hypothesis cards |
| GP-021: Count options before asking | Cat 2 | Gate at point of composing a question to human |
| GP-022: Every change needs a card | Cat 1 | Daily audit creates retroactive stubs for untracked decisions |
| Same-category sweep in AGENTS.md | Cat 2 | When corrected, check "am I doing this elsewhere?" |
| Pre-flight checklist | Cat 2 | 5-gate checklist before any system change |

## Lessons

1. **Logs first, always.** The answer was in the logs. 10 seconds vs 30 minutes.
2. **Cat 3 gating policies will be violated.** Every new GP should launch as Cat 1 or Cat 2.
3. **Every unnecessary permission-ask says "I don't trust my own judgment."** The human hired a CEO, not an intern.
4. **Fix the class, not the instance.** When corrected, sweep for all instances before responding.
5. **The fix for a process violation should not itself violate the process.** You're already in "fixing" mode — that's when you're most likely to skip steps.

## Template Value

This incident demonstrates a common cascade:
- Wrong diagnosis → wrong fix → human catches it → agent asks permission to apply right fix → human corrects permission-seeking → agent writes process fix without following process → human catches meta-deviation

The antidote is mechanical: pre-flight checklist (Cat 2) + daily audit (Cat 1). Not "I'll try harder."
