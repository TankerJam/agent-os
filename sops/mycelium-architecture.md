# Mycelium Architecture — Lateral Agent Communication

> Agents talking to each other without routing through a central director.

## The Problem

Hub-and-spoke architectures break at scale. When every signal routes through one "director" agent:
- Director becomes a bottleneck
- Cross-domain signals die in queues
- Agent A discovers something Agent B needs, but B waits for Director to route it
- Director's context window fills with routing work instead of strategic thinking

## The Pattern: Shared Substrate

Every agent writes a daily "substrate" file — a 3-5 line summary of what they learned, what they're seeing, and any cross-domain signals.

```
workspace/data/substrate/YYYY-MM-DD-{agent-name}.md
```

```markdown
# Substrate: marketing — 2026-03-05 14:30
## Learned today
- Blog post on GPS modules getting 3x normal traffic from Reddit
## Network state
- Content pipeline healthy, 3 posts queued
## Signal
- GPS module traffic spike may indicate inventory opportunity (operations)
```

### Key: The Signal Section

The `## Signal` section is what makes mycelium work. It's where agents flag things relevant to OTHER agents' domains. Marketing notices a traffic spike → flags it for Operations. Support sees recurring customer complaints → flags it for Product.

## Implementation: The Relay Script

**Critical lesson: behavioral instructions don't work. Mechanize it.**

Putting "read other agents' substrate files" in AGENTS.md is Cat 3 — it requires the agent to remember, decide to read, interpret, and act. Three discretionary decisions with zero enforcement.

Instead: a relay script runs every 30 minutes, reads all substrate files, and routes domain-relevant signals to each agent's queue.

```bash
#!/bin/bash
# mycelium-relay.sh — runs every 30 min via cron/LaunchAgent
# Reads all substrate files, diffs against last scan,
# routes signals to target agent queues

SUBSTRATE="$WORKSPACE/data/substrate"
TODAY=$(date +%Y-%m-%d)

for substrate_file in "$SUBSTRATE/${TODAY}-"*.md; do
    agent_name=$(basename "$substrate_file" .md | sed "s/${TODAY}-//")
    
    # Extract Signal section
    SIGNAL=$(awk '/^## Signal/{flag=1; next} /^##/{flag=0} flag' "$substrate_file" | 
        grep -v "NONE\|^$")
    
    [ -z "$SIGNAL" ] && continue
    
    # Route by keyword matching to target agent queues
    echo "$SIGNAL" | grep -qi "amazon\|inventory\|ppc" && \
        write_queue "workspace-operations" "$agent_name" "$SIGNAL"
    echo "$SIGNAL" | grep -qi "blog\|content\|seo" && \
        write_queue "workspace-marketing" "$agent_name" "$SIGNAL"
    # ... etc for each domain
done
```

Each agent's startup checklist includes: **"Check queue/incoming/mycelium-*.txt"** — these are cross-agent signals that arrived via relay. Act directly, no director routing needed.

## What Works vs What's Theater

| Approach | Cat Level | Result |
|----------|-----------|--------|
| "Agents should read each other's files" in AGENTS.md | Cat 3 | Never happens |
| Shared-context files (FEEDBACK-LOG, THESIS, SIGNALS) | Cat 2 | Works if agents read at startup |
| Mechanized relay script routing to queue/incoming/ | Cat 1 | Works reliably |
| Substrate writing by agents | Cat 2 | Works — agents write when told to in HEARTBEAT |

## Shared Context Layer

Three files that ALL agents read at session startup:

- **FEEDBACK-LOG.md** — Cross-agent corrections. Director writes, all read. "Marketing: never use competitor product photos." Every agent learns from every other agent's mistakes.
- **THESIS.md** — Current business worldview and positioning. Changes monthly. All agents need the same strategic context.
- **SIGNALS.md** — Trends being tracked. Research writes, Director reads. What the intelligence arm is watching.

These live in the director workspace's `shared-context/` directory. All agent AGENTS.md files include a step to read them at session start.

### One-Writer Rule

Each shared file has exactly one owner who writes it. Everyone else reads. This prevents merge conflicts and contradictory edits. Document ownership in the file header.

## Lessons Learned

1. **Substrate writing is easy; substrate reading is hard.** Agents will write their daily update because HEARTBEAT tells them to. Reading other agents' updates requires initiative — which is Cat 3. Mechanize the reading.

2. **Domain routing by keyword is good enough.** A perfect NLU classifier is not needed. `grep -qi "amazon\|inventory"` catches 90%+ of operations-relevant signals. Start simple.

3. **Don't route signals back to the sender.** If Marketing writes "SEO traffic up" in their substrate, the relay shouldn't route it back to Marketing's queue.

4. **Silence is a signal.** If an agent hasn't written a substrate entry today, something may be wrong. The director should check for missing entries during heartbeat.
