# Incident 013: The Unmonitored Spend

**Date:** Month 3 (discovered; failure period: ~1 month)  
**Severity:** HIGH — significant wasted spend  
**Detected by:** Human (manual)

## What Happened

Built an ad spend management tool. Ran initial optimizations. Then nobody ever ran it again. For a month.

Campaigns ran unmanaged — some at terrible return ratios. The management tool also had bugs that were never caught because it was never used again after the initial run.

## Root Cause

1. **Tool was built but never operationalized.** No cron, no monitoring, no automated runs.
2. **Agent heartbeat didn't include spend checks.**
3. **No "watchdog on the watchdog."** Nobody noticed the tool wasn't running.
4. **Building the tool felt like completing the task.** It wasn't.

## The Fixes

1. **Mandatory operationalization gate:** Building a tool requires also building the cron that runs it and the check that verifies it ran
2. **Agent heartbeat updated** to include spend audits
3. **Nightly audit cron + secondary watchdog** checking audit ran
4. **Spend guardrails:** Automated caps on bids, daily spend, monthly totals

## Lesson

Building a tool and running it once is a demo, not a deployment. If the tool isn't on a cron with a watchdog checking the cron, it's theater. Operationalization — not creation — is the finish line.
