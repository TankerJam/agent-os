# Incident 008: The Context Overflow Spiral

**Date:** Month 3  
**Severity:** P1 — 7 hours of degraded agent behavior across all agents  
**Detected by:** Human (manual)

## What Happened

The main workspace config (AGENTS.md) grew to 22,768 characters through incremental rule additions. The platform limit is 20,000 chars. Every agent got a silently truncated version of their instructions for 7 hours.

The cascade:
1. New rules added after a previous incident (correctly) but without pruning old content
2. File grew 13.8% past the limit in one session
3. Platform truncated — agents didn't know what they lost
4. A recurring cron accumulated context without successful compaction
5. Context overflow hit repeatedly across multiple runs
6. Each overflow caused compaction timeout → next run starts with same bloated context → overflow again
7. Multiple crons failed in the cascade

## Root Cause

**No automated gate on file size.** Rules were added individually (each one sensible in isolation) but nobody tracked the cumulative size. Textbook "boiling frog" failure.

## The Fix

1. Automated daily cron: `wc -c AGENTS.md` with alert at 18K (warning) and 20K (critical)
2. Context budget tracking for all injected workspace files (target: <60K total)
3. When adding rules, must prune old/redundant ones to stay under budget
4. MEMORY.md target: <12K chars, enforced by same cron

## Lesson

Every file your agent reads at startup is context budget. Context budget is finite. Treat it like memory on an embedded system — every byte matters, and silent truncation is worse than a crash because nobody knows it happened.
