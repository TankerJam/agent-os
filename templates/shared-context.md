# Shared Context Layer — Templates

## Overview

Three files that ALL agents read at session startup. Director-maintained, pull-based (agents read automatically, no push needed).

## shared-context/FEEDBACK-LOG.md

```markdown
# Cross-Agent Feedback Log
*Owner: Director (one-writer rule)*
*All agents: read at session start (step 4)*

## Active Corrections

### Marketing
- NEVER use competitor product photos in content (incident: Stratus photo used for our product)
- Blog titles: include the product name, not just the problem description
- Customer research before copy — always check product use-case files first

### Support  
- Never reveal internal agent names or architecture to customers
- "Admin" only in USER.md — no real names if the bot's responses could be screenshotted
- AHRS: valuable backup feature, never discourage purchase

### Operations
- SP-API relay is a structural blocker — don't keep retrying what requires browser auth
- 60-day filing deadline is hard — flag at 45 days, not 55

### All Agents
- "I'll do it later" is a lie. Create a queue item, cron, or HEARTBEAT entry — or it won't happen.
- Every correction gets written here within the same session. Not later. Now.
```

## shared-context/THESIS.md

```markdown
# Business Thesis
*Owner: Director*
*Updated: monthly or after major strategic shift*

## Who We Are
[One paragraph: what you sell, who buys it, why it matters]

## Competitive Position
[Your edge vs competitors — 3-5 bullets]

## Current Strategy
[What you're doing this quarter and why]

## What We Don't Do
[Explicit boundaries — what business you're NOT in]
```

## shared-context/SIGNALS.md

```markdown
# Tracked Signals
*Owner: Research agent (Scout)*
*Read by: Director*

## Active Signals
- [Trend/development being watched] — [why it matters] — [check date]

## Expired Signals
- [Signal that no longer matters] — [why: resolved, irrelevant, etc.]
```

## One-Writer Rule

Each file has ONE agent that writes to it. All others read only.

| File | Writer | Readers |
|------|--------|---------|
| FEEDBACK-LOG.md | Director | All agents |
| THESIS.md | Director | All agents |
| SIGNALS.md | Research | Director |

Why: prevents merge conflicts, contradictory edits, and "who changed this?" confusion. If an agent needs to add a correction to FEEDBACK-LOG but isn't the owner, it drops a queue item for the owner instead.
