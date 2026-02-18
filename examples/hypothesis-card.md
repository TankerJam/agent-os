# Example: Hypothesis Card

```markdown
# Hypothesis: Queue Age Monitor

**Date:** 2026-02-14
**Author:** Director
**Status:** VALIDATED

## Problem
Queue items sit unprocessed for 12+ hours because no agent checks frequently enough.
Evidence: 3 customer-facing delays in the past week traced to stale queue items.

## Hypothesis
If we add a cron job that checks queue age every 30 minutes and alerts when items exceed 2 hours,
then queue processing time will drop below 2 hours for 95% of items.

## Change
- File: Added cron job `queue-age-monitor` (runs every 30 min)
- Script: `scripts/check-queue-age.sh` — counts items older than 2h, alerts if >0
- Fix category: Cat 1 (automatic/cron)

## Success Criteria
- No queue item sits unprocessed >2 hours for 5 consecutive days
- Measurable via: `find queue/incoming -mmin +120 | wc -l` (should be 0)
- Check date: 2026-02-21

## A/B Testing
- Tested? N/A — single obvious fix (monitoring where none existed)

## Check Date
2026-02-21

## Verdict
**Result:** Zero items exceeded 2h threshold for 7 consecutive days.
**Verdict:** VALIDATED
**Next:** Keep as-is. Consider tightening to 1 hour threshold next quarter.

### Lessons Learned
1. What worked: Cron-based monitoring (Cat 1) — fires reliably without agent involvement
2. What failed: Nothing
3. Applies to: Any queue/inbox that needs timely processing
```
