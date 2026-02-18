# Incident: The Context Death

**Date:** 2026-02-14
**Severity:** High (lost critical directive permanently)

## What Happened

Human gave a detailed directive during a long conversation about how agents should handle a specific business process. The agent acknowledged it, discussed it, agreed on the approach.

The conversation compacted. The directive was never written to any file.

Next session: the agent had no memory of the directive. When the human referenced it, the agent couldn't find it anywhere — memory files, daily logs, SOPs. It was gone.

## Why It Happened

- The conversation was long and context-rich
- The agent intended to "write it up at the end"
- Compaction fired before "the end" arrived
- The directive existed only in conversation tokens

## Root Cause

**Writing important information was Cat 3** — it relied on the agent remembering to write things down before the session ended. Sessions don't always end gracefully. Compaction is not a polite "please wrap up."

## Fix

Implemented WAL (Write-Ahead Logging) protocol:
1. When receiving important information → write to file IMMEDIATELY
2. The write happens BEFORE the response
3. Not at session end. Not when convenient. NOW.

Added Cat 1 safety net:
- Git auto-commit preserves all file changes
- Session observer extracts facts from conversations periodically

## Lesson

**"I'll write it later" = "I'll never write it."**

In a system where context can vanish at any moment, the only safe time to write is NOW. Every directive, every decision, every lesson — if it matters, it goes to a file before you respond.

This is the single most important pattern in the entire system. Everything else can be rebuilt. Lost context cannot.
