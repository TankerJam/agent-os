# Incident 012: The Observer Blackout

**Date:** 2026-02-23 (discovered; failure started 2026-02-19)  
**Severity:** P2 — 96 hours of lost observations  
**Detected by:** Dream session (4 days late)

## What Happened

A key monitoring script (session observer, runs every 15 minutes) had been failing since Feb 19. The script checked for an API key in the system keychain — the key had expired/been removed. The fallback checked an environment variable — not available in cron environments.

For 4 days, no observations were extracted from sessions. The monitoring system was dark during critical system changes (routing gate deployment, pre-spawn gate introduction). No alert fired.

## Root Cause

**Single point of failure on credential lookup.** The script had two key sources: keychain → env var. Both failed simultaneously (key removed from keychain, env var not available in cron context). No fallback, no alert on failure.

## The Fixes

1. **Three credential sources:** env var → keychain primary → keychain fallback
2. **Observer canary:** Daily check — if observer hasn't written in 2+ hours, alert immediately
3. **The watchdog-on-the-watchdog pattern:** Every automated system needs a second system checking it's alive

## Lesson

Silent failures are the most dangerous kind. This script failed 384 times (every 15 minutes for 4 days) without anyone noticing. The fix isn't "make the script more reliable" — it's "build a second system that notices when the first one stops." Your monitoring needs monitoring.
