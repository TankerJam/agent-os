# Changelog

## 2026-02-18 — Process Enforcement, Search Resilience, Decision Audit Trail

### What happened
A single debugging session exposed cascading process failures: misdiagnosed a search API rate limit as an auth provider issue, deployed a config change to 7 agents without a hypothesis card, asked the human for permission 4+ times on decisions with obvious answers, then wrote fixes for process violations that were themselves process violations. Every failure was Cat 3 (habit-based) — and every one failed exactly as the Cat 3 framework predicts.

### New patterns

#### Pre-Flight Checklist (Cat 2)
Before ANY system change, run this gate:
1. **Evidence?** Read the logs. Are you treating root cause or symptom?
2. **Hypothesis card?** Written to file AND issue tracker?
3. **Incident report?** If fixing a failure — report is step one, not follow-up
4. **Same-category sweep?** Am I making this same mistake elsewhere right now?
5. **Single-option check?** If presenting to human: are there actually 2+ viable options? If only one is rational — execute, don't ask.

Added to `templates/AGENTS-snippet.md`.

#### Decision Audit Trail (Cat 1)
Daily automated cron scans all memory files for decision-like entries (deployed, changed, switched, patched, etc.) and checks if a matching hypothesis card exists. If not, creates a retroactive stub card + issue. Every decision gets tracked — not just violations.

**Why:** Hypothesis cards written in the moment capture reasoning that's lost 24 hours later. The audit trail is for backtesting: "we made this decision on Feb 18, here's why, here's what happened." Without cards, you're managing by amnesia.

#### GP-021: No Permission-Seeking for Single-Option Decisions
Before asking your human to choose: count viable options. If only one is rational (free > paid, Cat 1 > Cat 3, fix > ignore), execute it. Don't present it as a choice.

**Test:** "Would a competent CEO need their boss to pick this?" If no → just do it.

**Why:** Every unnecessary ask wastes human time and signals the agent lacks judgment. The human hired a CEO, not an intern.

#### Diagnostic Protocol: Logs First, Always
Before treating any system failure:
1. Read the logs (`grep -i "error\|429\|fail" gateway.err.log | tail -20`)
2. Identify the ACTUAL error — not the wrapper, not the symptom
3. Write hypothesis card with evidence FROM THE LOGS
4. Only then deploy fix

**Born from:** Research agent failing with "no auth profile available." Diagnosed as auth provider cooling down. Actual cause: Brave Search API 429 (1 req/sec rate limit on free plan). Misdiagnosis cost a config change to all 7 agents that treated the wrong problem.

#### Same-Category Sweep
When corrected on a behavior:
1. "Am I doing this same thing anywhere else right now?"
2. Fix ALL instances, not just the one called out
3. Respond with the full fix, not one at a time

**Born from:** Fixed one missing hypothesis card, missed three others in the same session. Human corrected four times for the same pattern.

### New scripts

#### `scripts/gh-comment-check.sh`
Stateful GitHub issue comment monitor. Tracks last-seen comment per issue, alerts on new comments. Flags approvals as ACTION NEEDED. Designed for cron (Cat 1, hourly during business hours).

**Born from:** Human approved a deploy 6 hours earlier via GitHub comment. Agent never saw it. No cron was reading GitHub comments despite claiming to "check every hour."

#### `scripts/search-ab-test.sh`
A/B tests search providers (Brave vs Tavily) with identical queries. Measures latency, result count, and rate limit behavior under rapid fire.

**Results:** Both work fine with spacing. Under rapid fire: Brave 429s on query 2/3, Tavily handles all 3 clean. Tavily has no observable rate limit on free tier.

### New SOPs

#### `sops/diagnostic-protocol.md`
Logs → root cause → hypothesis card → fix. In that order. No treating symptoms.

### Incidents

#### `incidents/misdiagnosis-chain.md`
Full RCA of a cascading failure: wrong diagnosis → wrong fix → permission-seeking loop → process deviation while fixing process deviations. Four root causes, seven deployed fixes. Template for "when everything goes wrong at once."

### Updated templates
- `templates/AGENTS-snippet.md` — added Pre-Flight Checklist, Diagnostic Protocol, Same-Category Sweep, NEVER-ask gate
- `templates/gating-policy.md` — added GP-020 (card enforcement), GP-021 (no permission-seeking), GP-022 (every change needs a card)

### Key lessons
1. **Cat 3 enforcement of Cat 1 rules is still Cat 3.** Writing "always write a hypothesis card" in AGENTS.md is Cat 3. A daily cron that detects missing cards and creates stubs is Cat 1.
2. **"I won't deviate" is a Cat 3 promise.** Stop saying it. Build the gate.
3. **Misdiagnosis is more expensive than no diagnosis.** Reading the logs takes 10 seconds. Deploying a fix for the wrong problem takes 30 minutes and creates a new problem.
4. **Every decision needs an audit trail.** Not just violations — ALL decisions. Future-you needs to know what was decided, why, and what happened.
5. **The fix for a process violation should not itself be a process violation.** Meta-deviations are the hardest to catch because you're already in "fixing" mode.

---

## 2026-02-17 — Initial Release

First public release of Agent OS patterns. Cat 1/2/3 framework, hypothesis-driven change, execution lifecycle, WAL protocol, sub-agent QC.
