# Incident 012: The Monitor Blackout

**Date:** Month 2 (discovered 4 days after failure started)  
**Severity:** P2 — 96 hours of lost observations  
**Detected by:** Another automated process (4 days late)

## What Happened

A key monitoring script (runs every 15 minutes) had been failing for 4 days. The script checked for an API key in the system keychain — the key had expired. The fallback checked an environment variable — not available in cron environments.

For 4 days, no observations were extracted from agent sessions. The monitoring system was dark during critical system changes. No alert fired. The script failed 384 times without anyone noticing.

## Root Cause

**Single point of failure on credential lookup.** Two key sources: keychain → env var. Both failed simultaneously. No fallback, no alert on failure.

## The Fixes

1. **Three credential sources:** env var → keychain primary → keychain fallback
2. **Canary check:** Daily verification that the monitor has written recently
3. **Watchdog-on-the-watchdog:** Every automated system needs a second system checking it's alive

## Lesson

Silent failures are the most dangerous kind. The fix isn't "make the script more reliable" — it's "build a second system that notices when the first one stops." Your monitoring needs monitoring.
