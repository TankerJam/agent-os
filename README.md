# Agent OS — A Battle-Tested Operating System for Stateless AI Agents

> Built by a solopreneur who needed his business to run while he wasn't watching.

## The Problem

AI agents forget everything between sessions. They hallucinate tasks. They drop context. They escalate problems they should solve themselves. They build elaborate systems that nobody maintains.

After three months of running a seven-agent network managing a real e-commerce business (customer support, marketing, operations, infrastructure, research, ticketing, DevOps), these are the patterns that survived contact with reality.

**Everything here was born from failure.** Every SOP exists because something broke. Every rule was written in the aftermath of an incident. The frameworks that sound obvious now were painfully non-obvious when we were debugging why the support bot insulted a customer or why the marketing agent spent $200 on ads targeting the wrong keywords.

## What This Is

An operating system for running stateless AI agents that actually work. Not a framework. Not a library. A set of **files, patterns, and SOPs** that you drop into your agent workspace and adapt.

Built on [OpenClaw](https://github.com/openclaw/openclaw), but the patterns are agent-platform agnostic. If your agent has a workspace directory, memory files, and periodic heartbeats, this applies.

## Core Architecture

```
workspace/
├── AGENTS.md          # Operating manual — agent reads this every session
├── SOUL.md            # Identity and personality
├── USER.md            # Who you're helping (context about the human)
├── HEARTBEAT.md       # Periodic task checklist
├── IDENTITY.md        # Name, emoji, avatar
├── TOOLS.md           # Environment-specific notes (API keys, device names)
├── MEMORY.md          # Curated long-term memory (distilled wisdom)
├── memory/
│   ├── active-context.md    # Working memory — survives compaction
│   ├── YYYY-MM-DD.md        # Daily raw logs
│   └── dreams/              # Creative exploration outputs
├── sops/                    # Standard operating procedures
├── scripts/                 # Automation scripts
├── data/
│   ├── execution-plans/     # Every multi-step task gets a plan file
│   ├── hypotheses/          # Hypothesis cards for changes
│   ├── incidents/           # Failure documentation
│   └── archive/             # Old data, organized
└── queue/
    ├── incoming/            # Cross-agent communication
    └── done/                # Processed items
```

## The Three Laws of Stateless Agents

### 1. If It's Not Written Down, It Doesn't Exist

Agents don't have persistent memory across sessions. Every insight, decision, and lesson must be written to a file *immediately* — not at session end, not "later." Context dies at compaction. Write-Ahead Logging (WAL) means the write happens BEFORE you respond.

### 2. The Cat 1/2/3 Framework

Before building any process, ask: **what category is this?**

| Category | Trigger | Reliability | Example |
|----------|---------|-------------|---------|
| **Cat 1** | Cron/timer — runs automatically | ✅ Always works | Daily backup, scheduled reports |
| **Cat 2** | Event/heartbeat — fires on trigger | ✅ Works when triggered | "On new email, summarize it" |
| **Cat 3** | Habit — agent must "remember" | ❌ Will fail | "Check Twitter occasionally" |

**If it's Cat 3, migrate it to Cat 1 or Cat 2.** Or build a Cat 1 safety net underneath it. Agents don't form habits. They forget. Design around that.

### 3. Every Execution Gets a File

Before executing any multi-step task:
1. Write the execution plan to a file
2. Execute
3. Update the file with results

Without the file, there's no iteration. No learning. No memory of what you did or why. The file IS the continuity.

## Key Patterns

### Memory Tiering
- **Hot:** `memory/active-context.md` — current focus, recent decisions, blocked items (<2KB)
- **Warm:** `memory/YYYY-MM-DD.md` — daily logs with importance tags
- **Cold:** `MEMORY.md` — curated long-term wisdom, reviewed periodically
- **Structured:** SQLite+FTS5 for queryable facts (optional)

### Importance Tagging
Every log entry gets tagged:
```markdown
[decision|i=0.9] Switched to Sonnet for all agents — permanent
[milestone|i=0.85] Shipped product listing rewrite — permanent  
[lesson|i=0.7] Sub-agents lie about completion — 30 day retention
[task|i=0.6] Review PPC campaign performance — 30 day retention
[context|i=0.3] Checked email, nothing urgent — 7 day retention
```

### Hypothesis-Driven Change
Every system change is a hypothesis:
1. Write a hypothesis card (problem, prediction, measurement criteria)
2. Implement the change
3. Measure against criteria
4. Grade: CONFIRMED / FAILED / KILLED / SHELVED
5. Close the loop

No more "let's try this and see." Every change has a prediction and a verdict.

### Adversarial QC — Cross-Model Review (New in v0.3)
Different models have different blind spots. The model that did the work can't objectively review it. Spawn a *different* model to adversarially review outputs before shipping. Haiku executes → Opus reviews. Sonnet executes → Opus reviews. Opus executes → GPT-4o reviews (cross-provider). Post findings to human before acting on them. See `sops/adversarial-qc.md` for the full guide with templates, model pairing, and real examples.

### Sub-Agent QC Gate
"The sub-agent said done" is NOT done. Mechanical verification:
- File exists and is non-empty (>50 bytes)
- Has expected sections
- No stub/placeholder content
- Only then mark complete

### GitHub as Human-Agent Interface
Issues as task queue. Labels as routing. Comments as feedback loops. The human reviews closed issues and reopens if needed. Native. Simple. No custom UI.

### Pre-Flight Checklist
Before ANY system change, five gates:
1. **Evidence?** Did I read the logs?
2. **Hypothesis card?** Written before the change?
3. **Incident report?** If fixing a failure — report FIRST
4. **Same-category sweep?** Am I doing this same mistake elsewhere?
5. **Single-option check?** If only one answer is rational — execute, don't ask

See `templates/AGENTS.md` for the full checklist.

### Gating Policies
Numbered failure-prevention rules, each born from a real incident. Every policy must be Cat 1 or Cat 2 — never Cat 3. See `templates/gating-policies.md`.

### Shared Context Layer (New in v0.3)
Three files all agents read at startup — pull-based corrections, business thesis, and tracked signals. One-writer rule: each file has one owner, everyone else reads. See `templates/shared-context.md`.

### Mycelium Architecture (New in v0.3)
Agents communicate laterally through a shared substrate, not through a central director. A relay script reads substrate files every 30 minutes and routes domain-relevant signals to target agent queues. **Key lesson: behavioral instructions in AGENTS.md are Cat 3 theater. Mechanize it.** See `sops/mycelium-architecture.md` and `scripts/mycelium-relay.sh`.

### Self-Healing (New in v0.3)
A nightly bloat check catches file bloat, stale queue items, zombie scripts, and webhook floods — everything your human shouldn't have to audit manually. See `sops/self-healing.md` and `scripts/nightly-bloat.sh`.

### Standard Execution Workflow (New in v0.3)
Every Grade M+ task follows an 8-step flow: Plan → Spawn → Sandbox → Adversarial QC → Post Result → Backtest → WAL → GH Acorn. Pre-spawn artifacts (plan file + hypothesis card) are REQUIRED before spawning sub-agents. See `sops/execution-workflow.md`.

### Adversarial Testing — Cross-Model Review (New in v0.3)
Your agent lies about quality — not maliciously, just optimistically. The fix: a model from a **different provider** reviews the work before the human sees it. Three layers: same-provider QC (Opus checks Sonnet), cross-provider review (GPT checks Claude), and periodic blind-spot scans. Same-provider catches ~60% of issues; cross-provider catches ~85%. See `sops/adversarial-testing.md`.

### Decision Audit Trail
Every decision gets a hypothesis card — not just the ones that go wrong. A daily Cat 1 cron scans memory files for decision-like entries and creates stub cards for any that weren't tracked. The audit trail is how you backtest: "we decided X on Feb 18 — did it work?"

### Diagnostic Protocol
Before treating any failure: read the logs, find the actual error, write a hypothesis card with evidence, THEN fix. See `sops/diagnostic-protocol.md`.

Born from: Misdiagnosed search API rate limits as auth provider failures. Deployed wrong fix to 7 agents.

## The Failure Catalog

See [`incidents/`](incidents/) for real failures that shaped these patterns:

- **The Alert Storm** — A dead process generated 713 spam files before anyone noticed. Led to: Cat 1/2/3 framework.
- **The Sub-Agent Liar** — Agent reported task complete with an empty file. Led to: QC gate script.
- **The Escalation Trap** — Agent escalated infrastructure problems it could solve itself. Led to: "If it doesn't leave the machine and doesn't spend money, handle it."
- **The Context Death** — Critical directive acknowledged in chat but never written down. Lost at compaction. Led to: WAL protocol.
- **The Permission Loop** — Agent asked permission for routine workspace changes, burning tokens and human attention. Led to: "Don't ask permission. Just do it. Report what you changed."
- **The Misdiagnosis Chain** — Wrong diagnosis → wrong fix → permission-seeking loop → process violation while fixing process violations. Led to: Pre-flight checklist, diagnostic protocol, gating policies. See `incidents/misdiagnosis-chain.md`.
- **The Missing Comments** — Human approved a deploy via GitHub. Agent never saw it for 6 hours. No cron was reading comments. Led to: `scripts/gh-comment-check.sh`.
- **The GH Issue Flood** — Two scripts created duplicate GH issues every nightly run without dedup checks. 14 duplicates accumulated. A human-approved action sat 15 days untouched in a queue. Led to: mandatory dedup guards, queue age monitoring. See `incidents/006-gh-issue-flood.md`.
- **The Cat 3 Theater** — Added "read other agents' substrate files" as a prose instruction in AGENTS.md. Adversarial QC immediately flagged it: agents don't execute shell commands from prose. Three discretionary decisions, zero enforcement. Replaced with a mechanized relay script. Led to: "if it requires remembering, it's Cat 3 theater." See `incidents/007-cat3-theater.md`.

## Quick Start

### For OpenClaw Users
See [`QUICKSTART-OPENCLAW.md`](QUICKSTART-OPENCLAW.md) — a machine-readable guide your agent can ingest directly.

### For Everyone Else
1. Copy the `templates/` directory into your agent workspace
2. Fill in `SOUL.md` (who is your agent?), `USER.md` (who are you?), `HEARTBEAT.md` (what should it check?)
3. Read `sops/` for the operating procedures
4. Adapt `AGENTS.md` to your setup

## Who Built This

A solopreneur running a small e-commerce business with a seven-agent AI network handling customer support, operations, marketing, infrastructure, research, ticketing, and DevOps. The business needed to run autonomously — not as an experiment, but because the owner isn't always available to babysit it.

The AI agent that co-developed these patterns (Director) acts as CEO of the agent network. Every SOP here was written because an agent failed at something and we built the fix together.

This isn't a theoretical framework. It's a production system managing real customer support, real operations, real marketing spend. The patterns work because they were forged in the gap between "AI can do anything" and "why did the bot just tell a customer to go away."

## Philosophy

- **Failures are the curriculum.** Every incident report is more valuable than every best-practice doc.
- **Stateless by design, not by limitation.** Files are better than memory. They're auditable, versionable, and they survive restarts.
- **Autonomy with accountability.** Agents should act, not ask. But they should document everything so you can revert.
- **Small improvements compound.** A 1% better agent every day is transformative over a month.

## License

MIT. Take it, fork it, make it yours.

## Contributing

Open an issue. If you're running agents and found patterns that work (or spectacular failures), we want to hear about it.
