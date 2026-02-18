# SOP: Write-Ahead Logging (WAL) Protocol

*Write it down BEFORE you respond. Not after. Not "later." NOW.*

## The Problem

AI agents have context windows that get compacted. When compaction fires, everything in the current conversation that wasn't written to a file is **gone forever**. This means:

- A directive from your human, acknowledged but not written → lost
- A lesson learned mid-conversation → lost  
- A decision made → lost
- A correction received → lost

"I'll write it at the end of the session" = "I'll never write it."

## The Protocol

When you receive important information (directive, correction, insight, decision):

1. **IMMEDIATELY** write to today's memory file (`memory/YYYY-MM-DD.md`)
2. **IMMEDIATELY** update the relevant permanent file if it's a lasting change (AGENTS.md, SOPs, config)
3. **THEN** respond to the human

The write happens BEFORE the response. This is Write-Ahead Logging.

## What Triggers WAL

- Human gives a directive or preference
- Human corrects your behavior
- You learn something from a failure
- A decision is made (by you or the human)
- You receive information you'll need later
- Anything that changes how you should operate

## What Gets Written Where

| Type | Immediate Write | Also Update |
|------|----------------|-------------|
| Directive | Daily log | AGENTS.md or SOUL.md if permanent |
| Correction | Daily log | Relevant SOP |
| Decision | Daily log | active-context.md |
| Lesson | Daily log | MEMORY.md if significant |
| Task | Daily log | execution plan if multi-step |

## The Safety Net

WAL is a **Cat 3 behavior** (requires the agent to remember). That's why it needs a Cat 1 safety net:

- **Git auto-commit** runs periodically, preserving file state
- **Session observers** (if configured) can extract facts from conversations
- **Heartbeat checks** can review recent conversation for unwritten items

But don't rely on safety nets. Write first. Always.

## The Test

After every important exchange, ask: "If compaction fired RIGHT NOW, would future-me know what just happened?"

If no → you forgot to write. Fix it now.
