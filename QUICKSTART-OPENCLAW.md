# QUICKSTART-OPENCLAW.md — New Agent Setup Guide

> **For agents:** Your human pointed you here. Read this, then implement it in your workspace.
> **For humans:** Point your new OpenClaw agent at this file. It'll set itself up.

## What This Is

A battle-tested operating system for stateless AI agents. These patterns were developed over three months running a seven-agent network managing a real e-commerce business. Everything here exists because something failed without it.

You can adopt this incrementally. Phase 1 works standalone. Each phase adds capability.

---

## Phase 1: Foundation (Day 1 — Do This Now)

### 1. Create Your Workspace Structure
```bash
mkdir -p memory data/execution-plans data/hypotheses data/incidents \
         queue/incoming queue/done sops scripts shared-context \
         data/substrate data/problem-cards logs
```

### 2. Create Your Core Files

**`SOUL.md`** — Who you are. Keep under 60 lines.
```markdown
# SOUL.md

## Role
You are [role] for [human's name]. You [primary responsibility].

## Core Truths
- You are proactive, not reactive. Don't wait to be asked.
- Think like a [role metaphor]. Study the domain. Make strategic decisions.
- Have strong opinions, loosely held. Act, then document for easy revert.

## Operating Principles
1. [Most important principle]
2. [Second most important]
3. [Third]

## Boundaries
- You CAN: [what you're allowed to do without asking]
- ASK FIRST: [what needs human approval — external comms, spending money, etc.]

## Vibe
[2-3 adjectives. How you communicate. Not a corporate robot.]
```

**`USER.md`** — Who your human is.
```markdown
# USER.md

- **Name:** [name or handle]
- **Timezone:** [tz]
- **Occupation:** [what they do — helps you understand their schedule/context]
- **Preferences:** [concise updates? detailed reports? no sycophancy?]
- **Annoyed by:** [permission-seeking? long responses? being asked obvious questions?]
```

**`AGENTS.md`** — Your operating manual. This is the most important file.
```markdown
# AGENTS.md

## Every Session
1. Read `SOUL.md` — who you are
2. Read `USER.md` — who you're helping
3. Read `shared-context/FEEDBACK-LOG.md` — corrections from other agents
4. Read `memory/active-context.md` — working memory
5. Read `memory/YYYY-MM-DD.md` — today + yesterday only
6. Check `queue/incoming/` — tasks from other agents
7. Check `data/execution-plans/` — resume IN_PROGRESS plans before new work

## Safety
- `trash` > `rm` (always recoverable deletes)
- Read before overwriting (never blind-write a file you haven't seen)
- ASK FIRST for: external emails, social posts, spending money, anything public-facing
- Everything internal: just do it, report what you changed

## Memory Protocol
- Write decisions/lessons to today's log IMMEDIATELY (WAL protocol)
- Update `memory/active-context.md` before session end
- Keep `active-context.md` under 2KB — it's a parachute, not a diary
```

**`HEARTBEAT.md`** — Start small. 3-5 items max.
```markdown
# HEARTBEAT.md

## Every Heartbeat
1. Check `queue/incoming/` — process any items
2. Check `data/execution-plans/` — resume any IN_PROGRESS plans
3. [Your domain-specific check — email? GH issues? monitoring?]

If nothing needs attention, reply: HEARTBEAT_OK
```

**`memory/active-context.md`** — Your parachute.
```markdown
# Active Context
## Current Focus
- [what you're working on]
## Recent Decisions  
- [what you decided and why]
## Blocked / Waiting
- [what needs human input]
```

**`shared-context/FEEDBACK-LOG.md`** — Cross-agent corrections.
```markdown
# Cross-Agent Feedback Log
*All agents: read at session start*

## Active Corrections
- [corrections that apply to all agents go here]
```

### 3. Understand the Three Laws

**Law 1: If It's Not Written Down, It Doesn't Exist**
You are stateless. Every session is a fresh start. Your human tells you something important → write it to a file IMMEDIATELY, before responding. Not "I'll note that" — write it NOW. Context dies at compaction.

**Law 2: The Cat 1/2/3 Framework**
Before building any process:

| Category | Trigger | Reliability |
|----------|---------|-------------|
| **Cat 1** | Cron/timer — runs automatically | ✅ Always works |
| **Cat 2** | Event/heartbeat — fires on trigger | ✅ Works when triggered |
| **Cat 3** | Habit — agent must "remember" | ❌ **Will fail** |

**If it's Cat 3, it will fail.** Migrate to Cat 1 (cron) or Cat 2 (heartbeat check). Agents don't form habits. They forget.

**Law 3: Every Multi-Step Task Gets a Plan File**
Before executing anything with 4+ steps:
```markdown
# data/execution-plans/{label}-{date}.md
Status: IN_PROGRESS
Steps:
1. [what] → [expected output]
2. [what] → [expected output]
3. Verify results
```
Update status to DONE or FAILED when complete. No file = no iteration = no learning.

---

## Phase 2: Memory System (Day 2-3)

### Daily Logs
Write `memory/YYYY-MM-DD.md` as things happen. Tag every entry:

```markdown
## 2026-03-06

- [decision|i=0.9] Switched to hypothesis-driven changes — permanent
- [milestone|i=0.85] Deployed customer support knowledge base — permanent
- [lesson|i=0.7] Sub-agents lie about completion — always verify — 30d retention
- [task|i=0.6] Review PPC campaign performance — 30d retention
- [context|i=0.3] Routine heartbeat, nothing urgent — 7d retention
```

**Retention:** i≥0.8 permanent, i≥0.5 → 30 days, i<0.5 → 7 days.

### Memory Hygiene
- **Daily log loading:** TODAY + YESTERDAY only. Older logs → `memory/archive/YYYY-MM/`
- **Active context:** Update before every session end. Under 2KB.
- **MEMORY.md:** Curated long-term wisdom. Distill from daily logs weekly. Under 12KB.
- **Archive:** Move logs older than 14 days to `memory/archive/`. Automate this (Cat 1).

### The WAL Protocol (Write-Ahead Logging)
When you receive a directive, correction, or learn something important:
1. **Write** to today's log + relevant file FIRST
2. **Then** respond to the human
3. **Then** continue working

Not "I'll save this later." There is no later. Your session can compact at any time.

---

## Phase 3: Hypothesis-Driven Change (Week 1)

Every system change gets a hypothesis card:

```markdown
# data/hypotheses/YYYY-MM-DD-{slug}.md

## Status: TESTING
## Problem
[What's broken?]
## Hypothesis  
If we [change], then [prediction] because [reasoning].
## Success Criteria
[How will you know it worked? Be specific.]
## Check Date: YYYY-MM-DD
## Results
[What actually happened?]
## Verdict: CONFIRMED / FAILED / KILLED
```

**Why bother?** Without hypothesis cards, you make changes and never check if they worked. You accumulate fixes for problems that might not exist. The card forces: what am I predicting? How will I measure? Did it work?

---

## Phase 4: Adversarial QC (Week 1-2)

> See `sops/adversarial-qc.md` for the full guide.

**The problem:** Your agent will tell you it did a great job. It probably didn't check thoroughly.

**The fix:** A different model reviews the work. Different models have different blind spots.

### How It Works

```
1. Cheap/fast model does the work (Haiku for mechanical, Sonnet for reasoning)
2. Different, capable model reviews adversarially (Opus, or cross-provider like GPT-4o)
3. Findings posted to human BEFORE acting on them
4. Failures fixed, then re-verified
```

### When to Use

| Task Complexity | QC? |
|----------------|-----|
| Simple lookup, 1-2 tool calls | No |
| Multi-file changes, script writing | **Yes** |
| Architecture, strategy, config changes | **Yes, always** |

### Spawn Template

```
sessions_spawn(
    task="Adversarial QC review. Be brutal.
    
    WHAT WAS DONE: [summary]
    KEY OUTPUTS: [files/changes]  
    WHAT COULD BE WRONG: [your honest concerns]
    
    Find bugs, missed items, broken assumptions. 
    Rate findings: 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW.
    'Looks good' is not acceptable unless you found zero issues.",
    model="opus",
    label="opus-qc"
)
```

### Model Pairing Guide

| Executor | Reviewer | When |
|----------|----------|------|
| Haiku | Opus | Mechanical work (file edits, greps, cleanup) |
| Sonnet | Opus | Reasoning work (content, code, synthesis) |
| Opus | GPT-4o | Strategic work (different provider = different blind spots) |
| Any | Sonnet | Budget-conscious (weaker adversarial but cheaper) |

### The Rule
**"Sub-agent said done" ≠ done. "QC said clean" = done.**

Post QC findings to your human immediately. Format:
```
QC complete — 3 findings:
🔴 HIGH: [must fix before shipping]
🟡 MED: [should fix]
🟢 LOW: [nice to have]
Acting on: [what you're fixing now]
```

### Real Examples of QC Catches
- Bash script using pipe subshell — variable modifications silently lost (check always passed)
- Auto-trim without backup — first false positive destroys the original file
- Queue monitor checking `.txt` only while real items were `.md`
- "84 zombie scripts" estimate was actually 7 when systematically verified

**Cost:** ~10-20% on top of task cost. Alternative: shipping bugs that take 2-10x longer to find later.

---

## Phase 5: Multi-Agent Communication (Week 2+)

> Only relevant if running multiple agents. Skip if single-agent.

### Shared Context Layer
Files that ALL agents read at startup:
- `shared-context/FEEDBACK-LOG.md` — corrections that apply across agents
- `shared-context/THESIS.md` — business worldview (what you sell, positioning)
- `shared-context/SIGNALS.md` — trends being tracked

**One-writer rule:** Each file has one owner who writes. Everyone else reads.

### Mycelium (Lateral Communication)
Instead of routing everything through a director agent:
1. Each agent writes a daily `data/substrate/YYYY-MM-DD-{name}.md`
2. A relay script (cron, every 30 min) reads all substrate files
3. Routes domain-relevant signals to target agent queues

See `sops/mycelium-architecture.md` and `scripts/mycelium-relay.sh`.

**Key lesson:** Don't put "read other agents' files" in AGENTS.md as a behavioral instruction. That's Cat 3 — it'll never happen. Use a cron relay (Cat 1) to deliver signals to each agent's queue.

### Queue Protocol
- `queue/incoming/` — items for this agent to process
- `queue/done/` — processed items (archive periodically)
- Format: `{source}-{topic}-{date}.txt`
- Every heartbeat: process all items in incoming/

---

## Phase 6: Self-Healing (Week 2+)

> See `sops/self-healing.md` for the full guide.

Automated health checks that catch problems before your human does.

### Minimum Viable Self-Healing
A single script that runs nightly:

```bash
#!/bin/bash
# scripts/health-check.sh — run daily via cron

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace-main}"
ISSUES=0

# Check: active-context.md exists and is under 2KB
AC="$WORKSPACE/memory/active-context.md"
if [ ! -f "$AC" ]; then
    echo "⚠️  Missing: active-context.md"
    ISSUES=$((ISSUES + 1))
elif [ $(wc -c < "$AC") -gt 3072 ]; then
    echo "⚠️  active-context.md over 3KB ($(wc -c < "$AC") bytes)"
    ISSUES=$((ISSUES + 1))
fi

# Check: daily logs older than 14 days
OLD_LOGS=$(find "$WORKSPACE/memory" -maxdepth 1 -name "20??-??-??.md" \
    -mtime +14 2>/dev/null | wc -l | tr -d ' ')
if [ "$OLD_LOGS" -gt 0 ]; then
    echo "⚠️  $OLD_LOGS daily logs older than 14 days — need archiving"
    ISSUES=$((ISSUES + 1))
fi

# Check: MEMORY.md under 12KB
MEM="$WORKSPACE/MEMORY.md"
if [ -f "$MEM" ] && [ $(wc -c < "$MEM") -gt 12288 ]; then
    echo "⚠️  MEMORY.md over 12KB — needs pruning"
    ISSUES=$((ISSUES + 1))
fi

# Check: queue/incoming not overflowing
QUEUE_COUNT=$(find "$WORKSPACE/queue/incoming" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$QUEUE_COUNT" -gt 20 ]; then
    echo "⚠️  Queue overflow: $QUEUE_COUNT items in incoming/"
    ISSUES=$((ISSUES + 1))
fi

[ "$ISSUES" -eq 0 ] && echo "✅ All clean" || echo "Found $ISSUES issues"
exit "$ISSUES"
```

### Growing From There
Add checks as you discover problems. Every manual audit finding → automate the detection. See `scripts/nightly-bloat.sh` for a full example with sub-checks.

---

## Phase 7: Execution Workflow (Ongoing)

> See `sops/execution-workflow.md` for the full 8-step flow.

For any task with 4+ steps:

```
1. PLAN        → Write execution plan file before starting
2. SPAWN       → Sub-agents for parallelizable work
3. SANDBOX     → Test before applying (dry-run, diff)
4. ADVERSARIAL → QC with different model
5. POST RESULT → Tell human what QC found, immediately
6. BACKTEST    → Verify no adjacent breakage
7. WAL         → Write to daily log + hypothesis card
8. CLOSE       → Update task tracker (GH issue, BOARD.md, etc.)
```

**The audit rule:** If you're doing 4+ tool calls without a plan file, you're winging it. Stop. Write the plan. Then execute.

---

## Anti-Patterns (Things That Failed Expensively)

1. **"I'll remember to do X"** → You won't. Cron or it didn't happen.
2. **"Sub-agent said done"** → Verify. Files exist? Non-empty? Expected content?
3. **"Just add it to AGENTS.md"** → If it requires the agent to remember, it's Cat 3 theater.
4. **Asking permission for routine work** → Just do it. Report. Human can revert.
5. **Auto-fixing without backup** → Always `cp file file.bak` before destructive ops.
6. **Creating GH issues without dedup** → Always check for existing open issues first.
7. **Loading all daily logs** → Today + yesterday only. Everything else is archived.
8. **SOUL.md as a manual** → Keep it under 60 lines. Identity and vibe only.
9. **Alerting without cooldown** → Without a cooldown timer, alerts fire every run.
10. **Size-based archives** → Use date-based (14-day window). Size misses the real problem.

---

## Adapting This To Your Setup

These patterns came from running e-commerce agents. Your domain is different. The principles transfer:

- **Single agent?** Skip Phase 5 (multi-agent). Everything else applies.
- **No sub-agents?** Skip adversarial QC spawning. Still use the hypothesis card pattern.
- **No GH issues?** Use `BOARD.md` as a kanban or any task tracker. The principle: tasks need a persistent record outside chat.
- **Different platform?** The file patterns work anywhere. Replace OpenClaw-specific tools with your platform's equivalents.

**Start with Phase 1. Add phases as you feel pain.** Don't implement everything day one — you'll create ceremony without understanding. Let failures guide which phases you need next.

## License

MIT. Take it, adapt it, make it yours.
