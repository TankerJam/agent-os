# Standard Execution Workflow

> Every non-trivial task follows this sequence. No skipping steps.

## The 8-Step Flow

```
1. PLAN        → Post plan block + write execution plan file
2. SPAWN       → Sub-agents with context (attachments > inline text)
3. SANDBOX     → Sub-agent tests changes: dry-run, diff, verify
4. ADVERSARIAL → Adversarial QC on all outputs (mandatory)
5. POST RESULT → Post QC result to human IMMEDIATELY, before further work
6. BACKTEST    → Verify fix doesn't break adjacent systems
7. WAL         → Write: hypothesis card + daily log + AGENTS.md if behavioral
8. GH ACORN    → Move issue status at each phase transition
```

## When to Use

| Grade | Trigger | Workflow |
|-------|---------|----------|
| XS/S | ≤3 tool calls, single concern | Execute directly |
| M | 4+ tools, multi-file, or script writing | Full 8-step flow |
| L | Multi-concern, research+write, multi-workspace | Full flow + rich context for sub-agents |
| XL | Architecture, strategy, human-facing | Full flow + senior model for QC |

## Step Details

### 1. PLAN — Pre-Spawn Artifacts

Before ANY tool calls on Grade M+ work, create all four artifacts:

```
data/execution-plans/{label}-{date}.md  — what you're doing and how
data/hypotheses/{date}-{label}.md       — problem, hypothesis, success criteria
queue/incoming/task-{label}-{date}.txt  — queue tracking item  
memory/active-context.md                — recovery anchor (if session crashes)
```

**Posting `📋 Plan:` in chat is not sufficient.** Files must exist before spawning sub-agents. If you crash mid-execution, these files are how you resume.

### 2. SPAWN — Sub-Agents With Attachments

Use file attachments instead of encoding context in task text:
```
sessions_spawn(
    task="Review this config and find issues",
    attachments=[{
        "name": "SOUL.md",
        "content": file_content,
        "encoding": "utf8"
    }]
)
```

Benefits: saves context window, content redacted from transcripts, cleaner task descriptions.

**Model selection:** Cheap models for mechanical work (grep, file edits). Reasoning models for synthesis. Strategic models for adversarial QC only.

### 3. SANDBOX — Dry-Run First

Sub-agents must test before applying:
- `diff` before overwriting files
- `--dry-run` flags on destructive operations
- Verify target paths exist before writing
- Read file before editing (never blind-write a file you haven't seen)

### 4. ADVERSARIAL — Mandatory QC

Spawn a senior model to adversarially review all outputs. Tell it:
- What was done
- Key outputs
- What could be wrong
- Ask it to be brutal

**Do not trust auto-announce.** Poll for completion, retrieve results explicitly.

### 5. POST RESULT — Immediately

The moment adversarial QC returns: post the summary to your human. Then act on findings.

**Not:** act on findings first, then report. **Yes:** report first, then act.

This was a real failure mode — the QC would finish, the agent would start fixing things, and the human would ask "what did QC find?" because the agent hadn't reported yet.

Format: "QC complete — [N] findings: [HIGH/MED/LOW bullets]. Acting on: [X, Y, Z]."

### 6. BACKTEST — Adjacent Systems

After deploying changes:
- `grep` for references to modified files in other scripts
- Run health checks that cover the affected area
- Verify the fix doesn't break the thing next to the thing you fixed

### 7. WAL — Write-Ahead Log

Write to three places minimum:
- **Hypothesis card** — update with verdict (CONFIRMED/REJECTED/PARTIAL)
- **Daily memory log** — what happened, decision tags, importance scores
- **AGENTS.md** — if the change is behavioral (new rule, new process)

### 8. GH ACORN — Track Progress

Move the GH issue label at each phase:
```
task → in-progress → done (or blocked)
```

Comment on the issue at each major phase transition. The issue tracker is the human's view into what's happening. Keep it current.

## What Gets Audited

A routing-gate check runs every 15 minutes and flags:
- **EXEC-WITHOUT-SPAWN:** >3 tool calls in one turn with no sub-agent spawn
- **SPAWN-WITHOUT-PLAN:** Sub-agent spawned but no execution plan file exists
- **SPAWN-WITHOUT-FILE:** Plan posted in chat text but not written to disk

All three create queue items and trigger alerts.
