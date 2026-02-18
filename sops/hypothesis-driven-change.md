# SOP: Hypothesis-Driven Change

*Every change is an experiment. No exceptions.*

## The Problem This Solves

Director lives in a vacuum. All ideas seem good in the moment because there's no scar tissue from failed experiments. Without reality testing, the system accumulates untested changes that feel productive but may be neutral or harmful. "Shipped" ≠ "worked."

## The Rule

**No change ships without a hypothesis card.** Period.

Before implementing ANY change (config, process, SOP, KB edit, cron job, agent instruction), write a hypothesis card to `data/hypotheses/YYYY-MM-DD-slug.md`.

## Hypothesis Card Template

```markdown
# Hypothesis: [short name]

**Date:** YYYY-MM-DD
**Author:** [agent]
**Status:** TESTING | VALIDATED | FAILED | INCONCLUSIVE | KILLED

## Problem
What specific, observable problem does this solve?
Not "it would be nice if" — what is BROKEN and how do you KNOW?
Evidence: [link to log, metric, complaint, or observation]

## Hypothesis
If we [specific change], then [specific measurable outcome] because [reasoning].

## Change
- File(s) changed: [paths]
- What was changed: [specific diff]
- Reversible? [yes/no, how to revert]
- **Fix category:** [Cat 1 (automatic/cron) | Cat 2 (triggered/event) | Cat 3 (habit/manual)]
- If Cat 3: what Cat 1/2 safety net catches failures? If none → redesign the fix.

## Success Criteria
How will we KNOW it worked? Must be:
- Observable (not "feels better")
- Measurable (number, yes/no, before/after comparison)
- Time-bound (when do we check?)

Examples of GOOD criteria:
- "Ceremony executes on schedule 3/3 times this week"
- "Support response accuracy improves from 6/10 to 8/10 on KB eval"
- "Queue items processed within 1 hour for 5 consecutive days"

Examples of BAD criteria:
- "Agents work better"
- "Process feels smoother"
- "Should reduce errors"

## A/B Testing (required for system changes with multiple approaches)
- **Tested?** YES / NO / N/A
- If YES: How many variants? Which won? Why?
- If NO: Why not? (Only acceptable: "single obvious fix" or "emergency hotfix")
- **Pattern:** Spawn 2-3 sub-agents with different approaches → grade results → ship winner
- **Rule:** If you're debating between approaches in your head, STOP debating and TEST.

## Companion Script (MANDATORY — no card is complete without this)
Every hypothesis card MUST have a companion script at `scripts/hyp-{slug}.sh`.

The script must do ONE of:
- **Implement** the change (e.g., update config, write file, trigger action)
- **Validate** the hypothesis is deployed (e.g., `grep -q "pattern" file && echo PASS || echo FAIL`)
- **Measure** success criteria (e.g., count files, check metrics, verify output)

Minimum viable script (3 lines is fine):
```bash
#!/bin/bash
# hyp-{slug}.sh — validates/implements {hypothesis name}
grep -q "expected-pattern" /path/to/file && echo "HYP_PASS: deployed" || echo "HYP_FAIL: not deployed"
```

**If a card has no companion script by its check date, it auto-fails.**
Verification: `ls scripts/hyp-*.sh | wc -l` vs `ls data/hypotheses/*.md | wc -l`
Ratio target: >80% of cards have a script.

## Check Date
YYYY-MM-DD (default: 7 days for process changes, 14 days for content/marketing)

## Verdict (filled at check date)
**Result:** [what actually happened — with evidence]
**Verdict:** VALIDATED / FAILED / INCONCLUSIVE
**Next:** [keep as-is / iterate with new hypothesis / revert / kill]

### Lessons Learned
1. **What worked:** {specific thing} — **Why:** {structural reason}
2. **What failed:** {specific thing} — **Why:** {root cause}
3. **What to do differently:** {concrete change, Cat 1/2 only}
4. **Applies to:** {what other systems/processes this lesson affects}

### Functional Test
Run: `{command}`
Expected: `{output}`
If this test fails, the hypothesis is NOT deployed regardless of what files exist.
```

## The Lookback Trigger

Hypotheses don't check themselves. Two structural triggers:

### 1. Nightly Dream — Hypothesis Review
Director dream Phase 2 includes:
- `ls data/hypotheses/` — any cards with check dates ≤ today?
- For each due card: gather evidence, write verdict, update status
- FAILED/INCONCLUSIVE cards: revert or iterate (new hypothesis card)

### 2. Weekly Board Review — Hypothesis Dashboard
Monday board review includes:
- Total active hypotheses
- Cards due this week
- Hit rate: validated / total checked (trailing 30 days)
- Any cards overdue for checking? (>3 days past check date = failure)

## What Counts as a "Change"

**YES, needs a hypothesis card:**
- New cron job or modified cron
- Agent SOUL.md / HEARTBEAT.md / instruction changes
- New SOP or process
- KB articles that change how agents behave
- Marketing content strategy shifts
- Config changes

**NO, doesn't need one:**
- Fixing a typo
- Responding to a support ticket
- Routine memory maintenance
- Filing a reimbursement case
- Anything that's executing an existing process (not changing one)

## The Meta-Hypothesis

This SOP is itself a hypothesis:

**Problem:** Director ships untested changes that accumulate without validation.
**Hypothesis:** If every change requires a written hypothesis with success criteria and a forced lookback date, then the rate of validated improvements will exceed 50% within 30 days.
**Success criteria:** >50% of hypothesis cards marked VALIDATED after 30 days (by March 16).
**Check date:** 2026-03-16
**Kill criteria:** If <30% validated after 30 days, this process is theater and should be simplified or killed.

## FAQ

**"This is too much overhead for small changes."**
Small changes get small cards. 5 lines is enough: problem, change, how you'll know, when you'll check. If you can't write 5 lines about why you're making a change, you probably shouldn't make it.

**"What if I forget to check?"**
That's what the nightly dream trigger and weekly review are for. If those fail, the process failed and we need a better trigger — not more willpower.

**"What if most things are INCONCLUSIVE?"**
That means success criteria are too vague. Tighten them. If you can't define success, you can't claim it.

## Iteration Speed

**Think in days, not weeks.**
- Process changes: check at 3 days
- Content/marketing: check at 5 days
- Infrastructure: check at 3 days
- Monthly is too long. Weekly is the MAX outer bound.

**Daily signal tracking:**
- Don't wait for check date to notice things
- Nightly dream includes KPI dashboard — look at trends
- If a hypothesis is clearly failing at day 2, don't wait for day 7 to call it

**WAL for conversations:**
When Prismo gives an insight during chat:
1. Write hypothesis card IMMEDIATELY if it implies a change
2. Append to today's memory under `## Prismo Directives`
3. Update relevant SOP if it's a permanent principle
4. Do this BEFORE responding. Write-ahead, not write-after.
