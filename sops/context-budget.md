# SOP: Context Budget Management

**When:** Always. Every file in your workspace that gets injected at session start costs context tokens.

## The Problem

Most agent platforms inject workspace files (AGENTS.md, MEMORY.md, HEARTBEAT.md, etc.) into every session. These files have a character limit. Exceed it and **instructions silently truncate** — the agent doesn't know what it lost.

This is the most insidious failure mode: the agent appears to work normally but is missing critical instructions. You won't notice until something goes wrong and you discover the rule that should have prevented it was truncated away.

## Budget Targets

| File | Target | Hard Limit | Why |
|------|--------|------------|-----|
| AGENTS.md | 18K chars | 20K chars | Platform injection limit |
| MEMORY.md | 10K chars | 12K chars | Context pressure |
| HEARTBEAT.md | 5K chars | 8K chars | Should be a checklist, not an essay |
| Total workspace | 50K chars | 60K chars | Leaves room for conversation + tools |

## Automated Enforcement

Daily cron (Cat 1):
```bash
#!/bin/bash
AGENTS_SIZE=$(wc -c < AGENTS.md 2>/dev/null || echo 0)
MEMORY_SIZE=$(wc -c < MEMORY.md 2>/dev/null || echo 0)

if [ "$AGENTS_SIZE" -gt 20000 ]; then
  echo "🔴 CRITICAL: AGENTS.md at ${AGENTS_SIZE} chars (limit: 20000)"
elif [ "$AGENTS_SIZE" -gt 18000 ]; then
  echo "⚠️  WARNING: AGENTS.md at ${AGENTS_SIZE} chars (target: 18000)"
fi

if [ "$MEMORY_SIZE" -gt 12000 ]; then
  echo "⚠️  WARNING: MEMORY.md at ${MEMORY_SIZE} chars (target: 12000)"
fi
```

## The Rule

When adding content to workspace files, you must also prune. The total budget cannot grow. New rule added? Old redundant rule removed. New memory entry? Old low-importance entry pruned.

**Details go in daily logs and data/ files.** Workspace files are summaries and rules — never raw data.

## Born From

The Context Overflow Spiral (Incident 008): AGENTS.md grew 13.8% past the limit. All agents ran with truncated instructions for 7 hours. Multiple cascading cron failures. Nobody noticed because the truncation was silent.
