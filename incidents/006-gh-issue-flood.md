# Incident 006: GitHub Issue Flood — 14 Duplicate Issues From Missing Dedup

## What Happened

Two scripts (`prismo-escalate.sh` and `dream-dispatch.sh`) created GH issues every time they detected persistent conditions — without checking if an open issue already existed for the same condition. Result: 14 duplicate issues for the same 3 problems, plus the human finding a 15-day-old approved action sitting in a queue file untouched.

## Timeline

- Feb 18: Human approves GH #80 (SEO task) via comment
- Feb 18–Mar 4: `gh-prismo-action-*` file sits in `queue/incoming/` untouched (15 days)
- Mar 3-4: `prismo-escalate.sh` runs nightly, creates #207 and #229 for same reimbursement alert
- Mar 3-4: `dream-dispatch.sh` creates P0/P1 issues nightly — same topics, 14 duplicates total
- Mar 5: Human audit session discovers all of this

## Root Causes

1. **No dedup check before GH issue creation.** Both scripts used `gh issue create` without first checking `gh issue list --state open --search "$TITLE"` for existing issues.

2. **Queue overflow check ignored .md files.** `queue-overflow-check.sh` only processed `*.txt` — the n8n webhook stubs were `.md` files, invisible to the cleanup script. 556 empty stubs accumulated.

3. **No age-based alert on queue items.** A human-approved action file sat for 15 days because nothing checked "how old are the items in queue/incoming?"

## Fix

### For every script that creates GH issues:
```bash
EXISTING=$(gh issue list --repo "$REPO" --state open \
    --search "$TITLE" --json number --jq '.[0].number' 2>/dev/null | grep -E '^[0-9]+$')
if [ -n "$EXISTING" ]; then
    log "DEDUP: #$EXISTING already open for: $item"
    continue
fi
```

### For queue monitoring:
- `stale-queue-items.sh` — alerts on files >7 days old, adversarial findings >24h
- `queue-overflow-check.sh` — now handles both `.txt` and `.md` files
- Auto-purges empty n8n stubs matching "Task: unspecified"

## Lessons

1. **Every `gh issue create` needs a dedup guard.** No exceptions. If you write a script that touches the issue tracker, grep it for dedup logic before deploying.

2. **Queue monitoring is not optional.** If items go into a queue, something must check their age. Unmonitored queues are where work goes to die.

3. **File extension assumptions break.** If your cleanup script handles `*.txt` but your webhook creates `*.md`, you have a blind spot. Match all relevant extensions.
