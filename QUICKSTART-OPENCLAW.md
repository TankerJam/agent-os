# QUICKSTART-OPENCLAW.md — Machine-Readable Implementation Guide

> **For agents:** Your human pointed you here. This file tells you how to implement the Agent OS patterns in your OpenClaw workspace. Read it, then do it.

## What This Is

A battle-tested operating system for stateless AI agents. These patterns were developed over two months running a six-agent network managing a real e-commerce business. Everything here exists because something failed without it.

## Implementation Steps

### Phase 1: Foundation (Do This First)

#### 1. Set Up Your File Structure
```bash
# In your workspace root
mkdir -p memory data/execution-plans data/hypotheses data/incidents data/archive queue/incoming queue/done sops scripts
```

#### 2. Create Your Core Files

Copy templates from `templates/` and customize:

- **`AGENTS.md`** — Your operating manual. Read this every session. Contains memory protocols, safety rules, execution requirements. This is the most important file.
- **`SOUL.md`** — Who you are. Your role, personality, operating principles, boundaries. Not optional — without this you're a generic chatbot.
- **`USER.md`** — Who your human is. Name, timezone, occupation, preferences, communication style. Context that shapes every interaction.
- **`IDENTITY.md`** — Name, emoji, creature type. Quick identity reference.
- **`HEARTBEAT.md`** — What to check on periodic heartbeats. Start small (2-3 items), grow as needed.
- **`MEMORY.md`** — Long-term curated memory. Starts empty. Grows over time as you distill daily logs.
- **`memory/active-context.md`** — Working memory. Update before session end or compaction. Keep under 2KB.

#### 3. Implement the Three Core Protocols

**Write-Ahead Logging (WAL):**
When your human gives a directive or you learn something important:
1. Write it to today's memory file IMMEDIATELY
2. Update relevant SOPs/config if it's permanent
3. THEN respond

Not "I'll write it later." There is no later. Compaction kills context.

**Cat 1/2/3 Classification:**
Before building any process:
- Cat 1 (cron/timer) → ✅ Build it
- Cat 2 (event/heartbeat trigger) → ✅ Build it  
- Cat 3 (agent must remember) → ❌ Migrate to Cat 1 or Cat 2

**Execution Plans:**
Before any multi-step task:
1. Write plan to `data/execution-plans/{label}-{date}.md`
2. Execute
3. Update file with results
No file = no iteration = no learning.

### Phase 2: Memory System

#### Daily Logs (`memory/YYYY-MM-DD.md`)
Write as things happen. Tag every entry:
```markdown
## 2026-02-18

### Events
- [decision|i=0.9] Switched to hypothesis-driven changes for all system modifications
- [milestone|i=0.85] Shipped customer support knowledge base v2
- [lesson|i=0.7] Sub-agents report completion before actually finishing — always verify
- [task|i=0.6] Review marketing campaign performance this week
- [context|i=0.3] Routine heartbeat check, nothing urgent
```

Retention by importance:
- i≥0.8 → permanent
- i≥0.5 → 30 days
- i<0.5 → 7 days

#### Active Context (`memory/active-context.md`)
Your parachute. Before session end or compaction:
```markdown
# Active Context

## Current Focus
- Working on X

## Recent Decisions
- Decided Y because Z

## Blocked / Waiting
- Waiting on human for Q

## Hot Context
- Critical detail that would be lost
```

#### Long-Term Memory (`MEMORY.md`)
Periodically (every few days), review daily logs and distill:
- Significant events worth remembering permanently
- Lessons that change how you operate
- Human preferences and patterns
- Remove outdated entries

### Phase 3: Hypothesis-Driven Change

Every system change gets a hypothesis card in `data/hypotheses/`:

```markdown
# Hypothesis: [Name]

## Status: TESTING | CONFIRMED | FAILED | KILLED | SHELVED

## Problem
What's broken or suboptimal?

## Hypothesis
If we [change], then [prediction] because [reasoning].

## Measurement
How will we know it worked? Specific criteria.

## Results
What actually happened?

## Verdict
CONFIRMED / FAILED / KILLED / SHELVED + why
```

No more "let's try this." Every change has a prediction and a measurable outcome.

### Phase 4: Sub-Agent QC (If Using Multiple Agents)

Never trust "I'm done" from a sub-agent. Verify mechanically:

```bash
# Check: file exists, non-empty, has expected sections, no stubs
[ -f "$FILE" ] && [ $(wc -c < "$FILE") -gt 50 ] && [ $(wc -l < "$FILE") -gt 5 ] && grep -q "$EXPECTED_SECTION" "$FILE"
```

### Phase 5: Heartbeat Productivity

Don't just return `HEARTBEAT_OK`. Rotate through useful checks:
- Unread emails/messages
- Upcoming calendar events
- Queue items from other agents
- Memory maintenance
- GitHub issues (if using as task interface)

Track what you checked in `memory/heartbeat-state.json` to avoid redundant checks.

## Anti-Patterns (Things That Failed)

1. **"I'll remember to do X"** → You won't. Make it Cat 1 or Cat 2.
2. **Mental notes** → Don't exist. Write it to a file or lose it.
3. **Asking permission for routine work** → Just do it. Report what you changed.
4. **Escalating problems you can solve** → If it doesn't leave the machine and doesn't spend money, handle it.
5. **Sub-agent said done = done** → Always verify. Files exist? Non-empty? Expected content?
6. **Big batch reviews** → Small daily iterations beat weekly marathons.
7. **Ceremony over substance** → If a process doesn't prevent failures, kill it.

## The Meta-Rule

If you identify a shortcoming in your own operation, fix it NOW. The fix includes:
1. Immediate change
2. Structural prevention (Cat 1/2, not Cat 3)
3. Propagation to relevant files
4. Memory entry
5. Verification method

Don't report problems. Fix them. Then report what you fixed.

## Adapting This

These patterns came from running e-commerce agents. Your domain is different. The principles transfer:
- **Stateless design** works for any agent that restarts
- **WAL protocol** works for any system with context windows
- **Cat 1/2/3** works for any automated process
- **Hypothesis cards** work for any iterative system
- **Execution plans** work for any multi-step task

Take what works. Kill what doesn't. Write down why.
