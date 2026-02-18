# SOP: Systems Design for Stateless Agents

*The "post-it notes with strings" principle. Every system must account for the fact that agents wake up fresh every session with no habits, no muscle memory, and no continuity except files.*

---

## The Three Categories

Every system we build falls into one of three categories:

| Category | How It Works | Reliability | Examples |
|----------|-------------|-------------|---------|
| **Cat 1: Automatic** | Runs on timers/crons. No agent action needed. | ✅ Always works | Session observer, git autocommit, queue-age-monitor, LaunchAgents |
| **Cat 2: Triggered** | Fires when an event happens. Agent acts on trigger. | ✅ Works when triggered | Rule propagation (triggered by writing a rule), incident reports (triggered by failure), HEARTBEAT checks (triggered by heartbeat poll) |
| **Cat 3: Habit-based** | Requires agent to remember to do something. | ❌ Usually fails | "Remember to snapshot before editing," "remember to write before responding," "remember to read PRE-FLIGHT" |

## The Rule

**Cat 3 systems will fail.** Stateless agents cannot form habits. Every session is a fresh start. "Remember to do X" is the same as "forget to do X."

## The Fix Pattern

For every proposed system, ask: **What category is this?**

- **If Cat 3 → migrate to Cat 1 or Cat 2:**
  - Can it run on a cron/timer? → Cat 1 (best)
  - Can it be triggered by a file, event, or HEARTBEAT? → Cat 2 (good)
  - Can a Cat 1 system catch failures when the agent forgets? → Automated safety net
  - None of the above? → Accept as aspirational, document the safety net, don't rely on it

- **If Cat 2 → verify the trigger fires reliably:**
  - Is the trigger in an always-loaded file (SOUL.md, HEARTBEAT.md)? ✅
  - Is the trigger in an optional file (PRE-FLIGHT.md, a SOP)? ⚠️ Add reference in always-loaded file
  - Is the trigger "the agent will notice"? ❌ That's Cat 3 in disguise

- **If Cat 1 → verify it's actually running:**
  - Check LaunchAgents/cron status
  - Verify output exists and is fresh
  - Monitor for silent failures

## Migration Playbook

When you identify a Cat 3 system:

1. **Extract the intent.** What is this system trying to prevent/ensure?
2. **Find the Cat 1/2 equivalent.** What timer, trigger, or script could do the same thing?
3. **Build it.** Script > instruction. Cron > reminder. HEARTBEAT entry > SOP reference.
4. **Kill or reframe the Cat 3 version.** Don't leave both running — the Cat 3 version creates false confidence.
5. **Document the migration.** Why was the old way Cat 3? Why does the new way work? What's the lesson?

## Lessons Learned

### Memory Verification (KILLED 2026-02-14)
- **Intent:** Prevent silent data corruption in MEMORY.md edits
- **Why Cat 3:** Required agent to run snapshot before and check after every edit
- **Cat 1 equivalent:** Git auto-commit (hourly). Every file version is preserved. Rollback via git, not a custom script.
- **Lesson:** Before building a new safety system, check if an existing Cat 1 system already covers it. Git was already doing this job — we built a redundant manual layer on top.
- **Generalizable:** Don't build manual safety nets when automated ones exist. And if you do build one, automate it or kill it — a manual safety net that nobody uses is worse than none (false confidence).

### WAL Protocol (Reframed 2026-02-14)
- **Intent:** Capture Prismo directives before they're lost to compaction
- **Why Cat 3:** "Write before responding" requires forming a habit
- **Cat 1 safety net:** Session observer runs every 15 min, extracts facts from active sessions automatically
- **Lesson:** The behavioral aspiration is fine. The RELIANCE on it is the mistake. The session observer IS the real WAL — it just doesn't require discipline.

### PRE-FLIGHT Checks (Migrated to Cat 2, 2026-02-14)
- **Intent:** Agents check domain-specific gates before acting
- **Why Cat 3:** Separate file agents must remember to read
- **Cat 2 fix:** Added "read PRE-FLIGHT before any action" to all agent HEARTBEATs (always-loaded)
- **Lesson:** Critical instructions belong in always-loaded files. Optional files are optional behavior.

## The Meta-Rule

**When designing any new system, process, or instruction:**

1. What category is it? (Be honest — "agent should..." is almost always Cat 3)
2. If Cat 3, how do we make it Cat 1 or Cat 2?
3. If we can't, what Cat 1 system catches failures?
4. Document the category explicitly in the hypothesis card

**Scripts > instructions. Crons > reminders. Triggers > habits. Files > memory.**

---

*Created: 2026-02-14. Origin: Systems iteration after Prismo correction rate hit 11. "The strings tied to your post-it notes."*
