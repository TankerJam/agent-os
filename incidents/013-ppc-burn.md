# Incident 013: The PPC Burn

**Date:** 2026-03-12 (discovered; failure period: Feb 9 — Mar 12)  
**Severity:** HIGH — $460 in wasted ad spend  
**Detected by:** Human (manual)

## What Happened

Built a PPC (pay-per-click) ad management tool on Feb 9. Ran initial optimizations. Then... nobody ever ran it again. For 31 days.

One campaign ran at 389% ACoS ($311 cost / $80 in sales) for the full period. Another at 52.7% ACoS. Total estimated waste: ~$460.

Additionally, the script had bugs that were never caught because it was never used again:
- `sales` field name mismatch (reports use `sales14d`, script read `sales` — showed $0)
- `keywordBid` can be None — `float(None)` crash

## Root Cause

1. **Tool was built but never operationalized.** No cron, no monitoring, no automated runs.
2. **Agent heartbeat didn't include PPC checks.** The operations agent checked inventory, not ad performance.
3. **No "watchdog on the watchdog."** Nobody noticed PPC wasn't being watched.
4. **Building a tool felt like completing the task.** It wasn't.

## The Fixes

1. **Mandatory operationalization gate:** Building a tool requires also building the cron that runs it and the check that verifies it ran
2. **Operations agent heartbeat:** Now includes PPC audit
3. **Nightly PPC audit cron + DevOps watchdog** checking audit ran
4. **Guardrails:** max bid $2.50, max daily $75/campaign, max monthly $3K

## Lesson

Building a tool and running it once is a demo, not a deployment. If the tool isn't on a cron with a watchdog checking the cron, it's theater. "We have a script for that" means nothing if nobody runs it. Operationalization — not creation — is the finish line.
