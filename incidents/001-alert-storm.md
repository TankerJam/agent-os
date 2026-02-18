# Incident: The Alert Storm

**Date:** 2026-02-18
**Severity:** Medium (operational noise, no data loss)
**Detection time:** ~6 days after onset

## What Happened

A background process (queue-watcher) was orphaned when its managing LaunchAgent was removed during a config change. The process continued running with PID 1333, generating "alert-stale" files into `queue/incoming/` every few minutes.

By the time it was discovered, **713 spam files** had accumulated.

## Why It Wasn't Caught

- The LaunchAgent was removed but nobody killed the running process
- No monitoring existed for orphaned processes
- The queue sweep (heartbeat check) processed items but didn't flag the volume anomaly
- The alert files had valid formatting, so they looked like real items

## Root Cause

**Process lifecycle management was Cat 3** — it relied on someone remembering to kill processes when removing LaunchAgents. Nobody remembered.

## Fix

1. Killed PID 1333
2. Deleted 713 spam files
3. Reduced LaunchAgents to 3 known-good ones (gateway, git-autocommit, guardian)
4. Added rule: when removing a LaunchAgent, ALWAYS check for and kill the running process

## Lesson

Removing a service config doesn't stop the service. **Always verify the process is dead after removing its launcher.** This is a Cat 2 fix — the trigger is "every time you remove a LaunchAgent, check `pgrep`."

The deeper lesson: queue systems need volume anomaly detection. If incoming items spike 10x, that's a signal, not normal operations.
