# Gating Policies — Failure-Prevention Rules

> Every policy here was born from an actual failure. The number tells you which incident spawned it.

## Template

```markdown
### GP-NNN: Short Name
**Trigger:** When does this gate fire?
**Gate:** What mechanical check happens?
**Why:** What incident caused this? (one sentence)
**Category:** Cat 1 (cron), Cat 2 (triggered), or Cat 3 (habit — migrate ASAP)
```

## Example Policies

### GP-017: Decision Card Before Installing External Tools
**Trigger:** Installing any new tool, system, or external dependency
**Gate:** Hypothesis card must exist in `data/hypotheses/` AND issue tracker BEFORE installation begins
**Why:** Installed a memory system without cost analysis or decision card. Human caught it.
**Category:** Cat 2 (checklist at point of installation)

### GP-020: Hypothesis Card Before Config Change
**Trigger:** Any modification to agent config, SOUL.md, or HEARTBEAT.md
**Gate:** Daily health audit cron checks for config file modifications without matching hypothesis cards
**Why:** Deployed a config change to all agents without a hypothesis card. Misdiagnosis that treated the wrong problem.
**Category:** Cat 1 (daily automated audit)

### GP-021: No Permission-Seeking for Single-Option Decisions
**Trigger:** About to ask human to choose between options
**Gate:** Count viable options. If only ONE is rational, EXECUTE IT.
**Test:** "Would a competent CEO need their boss to pick this?" If no → just do it.
**Why:** Asked permission 4+ times in one session for decisions with one obvious answer.
**Category:** Cat 2 (gate at point of composing question)

### GP-022: Every Process Change Needs a Hypothesis Card
**Trigger:** Creating or modifying any gating policy, SOP, agent instruction, or behavioral rule
**Gate:** Write hypothesis card + issue BEFORE deploying the change. Daily audit creates retroactive stubs for anything missed.
**Why:** Wrote a gating policy about writing hypothesis cards — without writing a hypothesis card. Meta-deviation.
**Category:** Cat 1 (daily audit catches violations) + Cat 2 (pre-flight checklist)

## Design Rules

1. **New policies MUST launch as Cat 1 or Cat 2.** Never Cat 3. Agents don't form habits.
2. **Every policy needs a mechanical enforcement mechanism.** "I'll remember" is not enforcement.
3. **Cat 1 beats Cat 2 beats Cat 3.** If you can automate it, automate it.
4. **Post-hoc catching (Cat 1 audit) is better than nothing.** It's not as good as a pre-gate, but it catches what slips through.
