# Incident 007: Cat 3 Theater — Behavioral Instructions That Never Execute

## What Happened

Added "Step 9b: Mycelium scan — `ls data/substrate/*.md` and read other agents' files" to all 6 domain agent AGENTS.md files. Adversarial QC immediately flagged it: agents don't execute embedded shell commands from prose instructions. They read AGENTS.md as guidance, not as a runnable script.

The instruction required three discretionary decisions per session (decide to run the command, decide to read each file, decide to act on findings) with zero enforcement. By our own Cat 1/2/3 framework, this was Cat 3 — and Cat 3 fails 100% of the time on tasks that aren't intrinsically motivated.

## The Pattern

This is the most common failure mode in agent configuration:

1. Identify a gap ("agents don't read each other's signals")
2. Write a behavioral instruction ("read the substrate files at startup")
3. Claim the gap is fixed
4. The instruction never executes because nothing enforces it
5. Human discovers the gap is still open weeks later

## The Fix

Replace the behavioral instruction with a mechanized relay:

**Before (Cat 3 — never works):**
```markdown
9b. Read /data/substrate/YYYY-MM-DD-*.md from other agents
```

**After (Cat 1 — always works):**
```bash
# mycelium-relay.sh — cron every 30 min
# Reads substrate, routes signals to agent queue/incoming/
```

```markdown
9b. Check queue/incoming/mycelium-*.txt — these are cross-agent signals
    auto-routed to you. Act directly, no director needed.
```

The agent no longer needs to decide to read substrate files. The relay reads them and delivers actionable items to the agent's queue. The agent just needs to process its inbox — which it already does.

## The Test

Before deploying any new AGENTS.md instruction, ask:

1. **Does this require the agent to remember to do something?** → Cat 3 risk
2. **Does this require the agent to make a judgment call about when?** → Cat 3 risk
3. **Is there a script/cron that makes this happen regardless?** → Cat 1
4. **Does the agent's startup sequence guarantee this runs?** → Cat 2

If the answer to #1 or #2 is yes and #3 is no: **you're writing theater, not process.**

## Lessons

1. **"Just add it to AGENTS.md" is the agent equivalent of "just put it in the wiki."** Nobody reads the wiki. Nobody follows behavioral instructions consistently.

2. **The gap between "wrote the instruction" and "it actually executes" is where most agent failures live.** Closing the gap requires mechanical enforcement.

3. **Cat 3 masquerading as Cat 1 is the hardest failure to detect** because it looks like you've done the work. The instruction exists. It's in the right file. It even sounds reasonable. But nothing makes it happen.
