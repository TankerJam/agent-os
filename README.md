# Agent OS — A Battle-Tested Operating System for Stateless AI Agents

> Built by a solopreneur who needed his business to run while he wasn't watching.

## The Problem

AI agents forget everything between sessions. They hallucinate tasks. They drop context. They escalate problems they should solve themselves. They build elaborate systems that nobody maintains.

After four months of running a seven-agent network managing a real business (customer support, marketing, operations, infrastructure, research, ticketing, DevOps), these are the patterns that survived contact with reality.

**Everything here was born from failure.** Every SOP exists because something broke. Every rule was written in the aftermath of an incident. The frameworks that sound obvious now were painfully non-obvious when we were debugging why the support bot gave a customer wrong information or why the operations agent let ad spend burn unmonitored for a month.

## What This Is

An operating system for running stateless AI agents that actually work. Not a framework. Not a library. A set of **files, patterns, and SOPs** that you drop into your agent workspace and adapt.

Built on [OpenClaw](https://github.com/openclaw/openclaw), but the patterns are agent-platform agnostic. If your agent has a workspace directory, memory files, and periodic heartbeats, this applies.

## What's New (v0.5 — March 2026)

Four months in. The system is qualitatively different from where it started. Here's what changed and why:

- **Context Overflow Protection** — AGENTS.md grew past the gateway's character limit and silently truncated every agent's instructions for 7 hours. Now we have automated size gates.
- **Prompt Injection Defense** — Someone seeded attack payloads in web content targeting our agents. One agent caught it. Structural defenses added.
- **Watchdog-on-the-Watchdog** — Built a tool, never operationalized it, lost money for a month. Every automated system now needs a second system checking it's alive.
- **Planning-as-Execution Trap** — Spent 4 hours writing plans about fixing Cat 3 failures while committing Cat 3 failures. The meta-irony incident.
- **What Worked vs What Didn't** — Honest retrospective after 4 months. See [The Iteration Story](#the-iteration-story).

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
│   └── substrate/           # Cross-agent lateral communication
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
| **Cat 3** | Habit — agent must "remember" | ❌ Will fail | "Check social media occasionally" |

**If it's Cat 3, migrate it to Cat 1 or Cat 2.** Or build a Cat 1 safety net underneath it. Agents don't form habits. They forget. Design around that.

**Update (Month 4):** Cat 3 controls fail 100% of the time at scale. Not sometimes. Not usually. Always. Every single Cat 3 instruction we wrote in AGENTS.md — "remember to check X," "always verify Y" — eventually failed when load increased or context was tight. The only things that work reliably are crons (Cat 1) and event-triggered gates (Cat 2). We no longer write Cat 3 controls. If it can't be a cron or a gate, it doesn't get built.

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
[decision|i=0.9] Switched to new model provider — permanent
[milestone|i=0.85] Shipped product listing rewrite — permanent  
[lesson|i=0.7] Sub-agents lie about completion — 30 day retention
[task|i=0.6] Review ad campaign performance — 30 day retention
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

### Context Budget Management (New in v0.5)
Your agent's workspace files (AGENTS.md, MEMORY.md, HEARTBEAT.md, etc.) are injected into every session. They have a character limit. Exceed it and **instructions silently truncate** — the agent doesn't know what it lost, and you don't know it lost anything.

Rules:
- **AGENTS.md: <20K chars.** This is the hard limit on most platforms. Set a cron to check: `wc -c AGENTS.md`
- **MEMORY.md: <12K chars.** If it grows, prune aggressively. Details go in daily logs.
- **Total workspace context: <60K chars.** Sum all injected files. Beyond this, context overflow cascades start.
- **Automated size gate:** A daily cron checks file sizes and alerts before truncation happens. Don't rely on noticing — you won't.

Born from: [The Context Overflow Spiral](#the-failure-catalog) — 7 hours of degraded agent behavior because AGENTS.md grew past the platform limit.

### Adversarial QC — Cross-Model Review
Different models have different blind spots. The model that did the work can't objectively review it. Spawn a *different* model to adversarially review outputs before shipping. Same-provider review catches ~60% of issues. Cross-provider catches ~85%. The 25% gap includes things like "this sounds confident but is factually wrong." See `sops/adversarial-qc.md`.

### Sub-Agent QC Gate
"The sub-agent said done" is NOT done. Mechanical verification:
- File exists and is non-empty (>50 bytes)
- Has expected sections
- No stub/placeholder content
- Only then mark complete

### The Watchdog-on-the-Watchdog Pattern (New in v0.5)
Building a tool is not the same as operationalizing it. We built a management script, ran it once, and then nobody ever ran it again. For a month.

The pattern: **every automated system needs a second automated system checking that the first one is running.**

- Monitoring script → canary check (is it still writing?)
- Management tool → nightly audit cron (did it run today?)
- Health check → external watchdog (is the health checker alive?)

If you built something but didn't build the thing that checks it's working, you haven't finished.

### Prompt Injection Defense (New in v0.5)
If your agents read external content (chat, email, web), someone will try to inject instructions. We caught a targeted attack that mimicked our platform's internal message format — the attacker knew our audit language, file naming conventions, and specifically targeted behavior after context resets.

Defenses:
1. **Never write to memory files from external content.** External content → daily logs (append-only). Only a trusted agent writes to long-term memory after reviewing.
2. **Explicit startup checklists.** If a file isn't in AGENTS.md's startup list, don't read it because a message told you to.
3. **Format validation.** Real system messages have specific metadata. Fake "System:" prefixes in user messages = spoofed.
4. **Propagate rules to all agents.** One agent knowing about an attack vector is useless if the others don't.

See `sops/prompt-injection-defense.md`.

### GitHub as Human-Agent Interface
Issues as task queue. Labels as routing. Comments as feedback loops. The human reviews closed issues and reopens if needed. Native. Simple. No custom UI.

### Gating Policies
Numbered failure-prevention rules, each born from a real incident. Every policy must be Cat 1 or Cat 2 — never Cat 3. See `templates/gating-policies.md`.

### Shared Context Layer
Three files all agents read at startup — pull-based corrections, business thesis, and tracked signals. One-writer rule: each file has one owner, everyone else reads. See `templates/shared-context.md`.

### Mycelium Architecture
Agents communicate laterally through a shared substrate, not through a central director. A relay script reads substrate files every 30 minutes and routes domain-relevant signals to target agent queues. **Key lesson: behavioral instructions in AGENTS.md are Cat 3 theater. Mechanize it.** See `sops/mycelium-architecture.md`.

### Self-Healing
A nightly bloat check catches file bloat, stale queue items, zombie scripts, and webhook floods. See `sops/self-healing.md`.

### Standard Execution Workflow
Every Grade M+ task follows an 8-step flow: Plan → Spawn → Sandbox → Adversarial QC → Post Result → Backtest → WAL → GH Acorn. Pre-spawn artifacts are REQUIRED before spawning sub-agents. See `sops/execution-workflow.md`.

### Cron Hygiene
At scale, cron jobs silently degrade. Missing timezones, wrong models burning tokens, delivery failures killing output. Includes `--light-context` optimization (saves 5-15K tokens per run), stagger patterns, and external watchdog design. See `sops/cron-hygiene.md`.

### Infrastructure Deployment: Two-Person Rule (New in v0.5)
The agent that builds infrastructure should not be the same one that validates it. One agent builds, another validates. Every deployment follows: build → smoke test → security scan → idempotency test → failure test → handoff to validator.

Born from: The agent that deployed config changes also "verified" them. Both steps had the same blind spot. See `sops/infrastructure-deployment.md`.

### Credential Hygiene (New in v0.5)
Any credential used must be saved to persistent storage (keychain, secrets manager) in the same turn it's first used. Never rely on session memory for secrets. We lost 4 days of monitoring data because a key expired from keychain and no fallback existed.

Rule: Every script that uses a credential must have 3 lookup sources (env → keychain → fallback). Single points of failure on auth = silent system death.

### Domain Autonomy (New in v0.5)
The director agent plans and QCs. Domain agents execute. When the director starts executing domain tasks, quality drops — it lacks domain context and bypasses domain-specific guardrails.

Pattern: If the director catches itself doing domain work → STOP → drop a queue item for the domain agent → move on.

## The Failure Catalog

See [`incidents/`](incidents/) for real failures that shaped these patterns:

### Foundational Incidents (v0.1–v0.3)
- **The Alert Storm** — A dead process generated 713 spam files before anyone noticed. Led to: Cat 1/2/3 framework.
- **The Sub-Agent Liar** — Agent reported task complete with an empty file. Led to: QC gate script.
- **The Escalation Trap** — Agent escalated problems it could solve itself. Led to: "If it doesn't leave the machine and doesn't spend money, handle it."
- **The Context Death** — Critical directive acknowledged in chat but never written down. Lost at compaction. Led to: WAL protocol.
- **The Permission Loop** — Agent asked permission for routine workspace changes, burning tokens and human attention. Led to: "Don't ask permission. Just do it. Report what you changed."
- **The Misdiagnosis Chain** — Wrong diagnosis → wrong fix → permission-seeking loop → process violation while fixing process violations. Led to: Pre-flight checklist, diagnostic protocol, gating policies.
- **The GH Issue Flood** — Scripts created duplicate issues nightly without dedup checks. Led to: mandatory dedup guards.
- **The Cat 3 Theater** — Added "read other agents' files" as a prose instruction. Agents never did it. Led to: mechanized relay scripts.

### Scale Incidents (v0.4–v0.5)
- **The Context Overflow Spiral** — Workspace config file grew past the platform's character limit. Instructions silently truncated for 7 hours across all agents. Cascading cron failures. Led to: automated file size gates.
- **The Auth Break** — Agent read a changelog about a new feature and immediately migrated all agents' auth files to use it. Without being asked. Without backups. Without understanding how the tokens worked. All agents went offline. Led to: two-person rule.
- **The Circular Planner** — Spent 4 hours writing plans about fixing failures while committing the same failures. Built automation for problems that don't exist while ignoring problems that do. Led to: "Planning Is Not Execution" rule.
- **The Prompt Injection** — Targeted attack mimicking platform internal messages. Agent caught it, but it was close. Led to: structural injection defenses.
- **The Monitor Blackout** — Key monitoring script failed silently for 4 days. No alert. Led to: watchdog-on-the-watchdog pattern.
- **The Unmonitored Spend** — Built a spend management tool, ran it once, never automated it. Money burned for a month while nobody watched. Led to: mandatory operationalization gate.
- **The Content QC Gap** — Automated QC checked format but not substance. Wrong content was customer-facing for weeks before a human noticed. Led to: content-level verification in QC pipelines.

## The Iteration Story

Four months of running this system. Here's what actually happened.

### What Worked

**The Cat 1/2/3 Framework — the single most valuable pattern.** Everything else builds on it. The moment you classify every process as "runs on a timer," "fires on a trigger," or "requires remembering," you immediately see which ones will fail.

**Hypothesis-driven change.** Writing a prediction before implementing forced us to be honest about what we expected. Half our hypotheses were wrong — and we knew it within the measurement window instead of discovering it months later.

**Incident reports as curriculum.** Every failure documented became a pattern we could reference. New incidents get compared against the catalog: "is this the Sub-Agent Liar again?" The catalog creates institutional memory that individual agents don't have.

**File-based communication over direct messaging.** Cross-agent messaging APIs were unreliable (21/21 failures early on). Switched to file queues (write a file → other agent picks it up during heartbeat). Never failed once. Files are debuggable, auditable, and survive restarts.

**Adversarial cross-model QC.** Same-provider review catches ~60% of issues. Cross-provider catches ~85%. The 25% gap includes "this sounds confident but is factually wrong" — exactly what the producing model can't see.

**The substrate (mycelium) pattern.** Instead of routing everything through a director, agents write daily summaries. A relay script routes signals to relevant agents. Eliminated the director-as-bottleneck problem.

### What Didn't Work

**Prose instructions as behavioral controls.** "Always write a hypothesis card" in AGENTS.md is aspirational, not operational. When context gets tight, agents skip the parts that feel like overhead. The only controls that stuck were backed by automated enforcement.

**Complex automation before simple automation.** We built workflow engines, queue relays, and elaborate dispatch systems — then discovered most of them automated problems we didn't actually have. The simple file-queue pattern replaced all of it.

**Model-as-personality.** Giving each agent a distinct personality consumed context tokens and produced inconsistent behavior. Now agents have minimal identity files and invest context budget in operational instructions instead.

**Nightly creative sessions.** We ran exploration sessions where agents would generate hypotheticals and make connections. The outputs were mostly generic insights that didn't translate to action. Replaced with continuous small signals throughout the day.

**Human-in-the-loop for everything.** The initial instinct was to have the human approve every significant change. This created a bottleneck. The fix: classify actions as RED (needs human: external comms, spending money, customer-facing changes) vs everything else (just do it, report what you changed, human can revert).

### How It Evolved

**Month 1: Chaos.** Agents running with minimal instructions. Constant failures. Every session was firefighting. The Cat 1/2/3 framework emerged from the Alert Storm. Hypothesis cards from the first misdiagnosis.

**Month 2: Process heavy.** Overcorrected. Workspace config ballooned past the platform limit. Every failure added a new rule. Rules referenced rules. The agent spent more time reading instructions than doing work. Context overflow was the wake-up call.

**Month 3: Mechanical enforcement.** Realized prose rules don't work. Started converting behavioral instructions to crons, gates, and scripts. Introduced adversarial QC. Cut config by 40%. Simpler AND more reliable.

**Month 4: Steady state.** Most failures are now novel (new problems, not repeated mistakes). The system catches its own regressions. Human intervention dropped from many times daily to a few times weekly. Remaining interventions are genuinely strategic.

### Key Metrics (Approximate)

| Metric | Month 1 | Month 4 |
|--------|---------|---------|
| Human corrections/day | 15-20 | 1-2 |
| Repeated failures | ~60% of incidents | <10% |
| Agent uptime | ~70% | ~98% |
| Mean time to detect failure | 6-24 hours | <2 hours |
| Cat 3 controls in workspace config | ~15 | 0 |
| Automated gates/checks | 3 | 28 |

### The Meta-Lesson

**The system works not because the agents got smarter, but because the environment got more structured.** The agents are the same models they were on day one. What changed is: the files they read, the scripts that enforce rules, the crons that catch drift, and the incident catalog that prevents repeats.

Stateless agents don't learn. Their environment learns for them.

## Quick Start

### For OpenClaw Users
See [`QUICKSTART-OPENCLAW.md`](QUICKSTART-OPENCLAW.md) — a machine-readable guide your agent can ingest directly.

### For Everyone Else
1. Copy the `templates/` directory into your agent workspace
2. Fill in `SOUL.md` (who is your agent?), `USER.md` (who are you?), `HEARTBEAT.md` (what should it check?)
3. Read `sops/` for the operating procedures
4. Adapt `AGENTS.md` to your setup

## Who Built This

A solopreneur running a small business with a seven-agent AI network. The business needed to run autonomously — not as an experiment, but because the owner isn't always available to babysit it.

The AI agent that co-developed these patterns acts as coordinator of the agent network. Every SOP here was written because an agent failed at something and we built the fix together.

This isn't a theoretical framework. It's a production system managing real operations. The patterns work because they were forged in the gap between "AI can do anything" and "why did the agent just do that."

## Philosophy

- **Failures are the curriculum.** Every incident report is more valuable than every best-practice doc.
- **Stateless by design, not by limitation.** Files are better than memory. They're auditable, versionable, and they survive restarts.
- **Autonomy with accountability.** Agents should act, not ask. But they should document everything so you can revert.
- **Small improvements compound.** A 1% better agent every day is transformative over a month.
- **The environment learns, not the agent.** Agents are stateless. Make the workspace smarter instead.

## License

MIT. Take it, fork it, make it yours.

## Contributing

Open an issue. If you're running agents and found patterns that work (or spectacular failures), we want to hear about it.
