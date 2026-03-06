# Adversarial QC — Cross-Model Quality Control for AI Agents

> Your agent will tell you it did a great job. A different model will tell you the truth.

## Why This Exists

AI agents are optimistic reporters. When a sub-agent says "Done! I reviewed all 7 files and everything looks great," there's a meaningful chance it:
- Skimmed 3 of the 7
- Missed a critical issue in the ones it read
- Declared victory on work that's 70% complete
- Made changes that break something adjacent

**The same model that did the work cannot objectively evaluate it.** This isn't a philosophical position — it's an observed failure rate. In our network, sub-agent "done" signals were wrong ~30% of the time before we added adversarial QC.

## The Pattern

```
1. Cheap model does the work (Haiku/Sonnet)
2. Different, capable model reviews the work (Opus/GPT-4o)
3. Review findings posted to human BEFORE acting on them
4. Failures fixed, then verified again
```

### Why Different Models?

Not just "expensive model checks cheap model." Different models have different blind spots:

| Model | Good At | Misses |
|-------|---------|--------|
| Haiku | Fast mechanical work, grep, file edits | Nuance, cross-system implications |
| Sonnet | Reasoning, synthesis, planning | Its own assumptions, scope creep |
| Opus | Strategy, adversarial thinking, edge cases | Over-engineering, token cost |
| GPT-4o | Fresh perspective, different training data | OpenClaw-specific conventions |

The adversarial reviewer catches what the executor's blind spots miss. It's not about intelligence tier — it's about **different failure modes**.

## Implementation in OpenClaw

### Step 1: Do the Work (Cheap Model)

Spawn a sub-agent with the appropriate model for the task:

```
sessions_spawn(
    task="Audit all 7 HEARTBEAT.md files for bloat. Flag any over 100 lines. 
          Suggest specific cuts. Write findings to /tmp/heartbeat-audit.md",
    model="haiku",
    label="haiku-audit"
)
```

**Model selection for execution:**
- **Haiku** — File operations, grep, simple edits, status checks, mechanical tasks
- **Sonnet** — Multi-file reasoning, content writing, code review, synthesis
- **Opus** — Only when the task IS strategic (architecture, major decisions)

### Step 2: Adversarial Review (Different Model)

Once the work sub-agent completes, spawn the reviewer:

```
sessions_spawn(
    task="Adversarial QC review. Be brutal. Find what's wrong.
    
    WHAT WAS DONE: [summary of the task]
    KEY OUTPUTS: [list the files/changes made]
    WHAT COULD BE WRONG: [your honest concerns]
    
    Review criteria:
    1. Did the work actually get done, or just described?
    2. Are there off-by-one errors, missed files, wrong paths?
    3. Does this break anything adjacent?
    4. What did the executor assume that might be wrong?
    5. Rate each finding: HIGH (must fix) / MEDIUM (should fix) / LOW (nice to fix)
    
    Be adversarial. 'Looks good' is not an acceptable review.",
    model="opus",
    label="opus-qc",
    attachments=[
        {"name": "audit-output.md", "content": work_output}
    ]
)
```

**Model selection for review:**
- **Opus** — Default adversarial reviewer. Best at finding assumptions and edge cases.
- **GPT-4o** — Good for cross-model perspective (via OpenRouter or direct API). Different training data catches different things.
- **Sonnet** — Acceptable if Opus is unavailable, but weaker at adversarial thinking.

**Never use the same model for both execution and review.** The whole point is different failure modes.

### Step 3: Retrieve and Post Results

**Do not trust auto-announce.** Always poll explicitly:

```
# Check if QC is done
subagents(action="list")

# When status is "done", retrieve the result
sessions_history(sessionKey="agent:main:subagent:{uuid}")
```

**Post findings to your human IMMEDIATELY — before acting on them:**

```
Opus QC complete — 3 findings:
🔴 HIGH: filesystem-audit.sh auto-trims without backup (data loss risk)
🔴 HIGH: stale-queue check uses pipe subshell (variable scoping bug — check silently passes)
🟡 MED: n8n flood check runs at 6 AM only (misses daytime floods)

Acting on: all three. Backup added, subshell fixed, frequency increased.
```

**The "post before act" rule exists because of a real failure:** QC would finish, the agent would spend 20 minutes fixing things, and the human would ask "what happened?" with no visibility into the findings.

### Step 4: Fix and Verify

Fix HIGH findings first. Then verify the fixes didn't introduce new issues:
- Re-run the specific check that found the issue
- `grep` for adjacent code that might have the same bug
- Run relevant health checks

## When to Use Adversarial QC

| Task Grade | QC Required? | Why |
|------------|-------------|-----|
| **XS** (1 tool call) | No | Overhead exceeds risk |
| **S** (2-3 tools) | No | Unless it's a config change |
| **M** (4+ tools, multi-file) | **Yes** | This is where bugs hide |
| **L** (multi-concern, research) | **Yes** | Too much surface area for self-review |
| **XL** (architecture, strategy) | **Yes, Opus** | Stakes are highest |

**Skip QC only for:** trivial lookups, status checks, single-file reads, and when the human explicitly says skip.

## The Cross-Model Blind Spot Check

For critical infrastructure changes, use a model from a completely different provider:

```python
# scripts/blind-spot-check.py
# Sends the proposed change to GPT-4o for adversarial review
# Different training data = different assumptions = catches different things

import openai
client = openai.OpenAI()  # Uses OPENAI_API_KEY

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{
        "role": "system",
        "content": "You are an adversarial code reviewer. Find bugs, "
                   "security issues, and logical errors. Be brutal. "
                   "'Looks good' is not acceptable."
    }, {
        "role": "user", 
        "content": f"Review this change:\n\n{change_content}"
    }]
)
```

This is NOT about one model being "better" — it's about **coverage**. Claude misses things GPT catches. GPT misses things Claude catches. Using both means fewer blind spots.

## Template: Adding QC to Your AGENTS.md

Drop this into your agent's operating manual:

```markdown
## Adversarial QC Gate [Cat 1]

Before reporting ANY Grade M/L/XL task complete:

1. Spawn adversarial reviewer (different model than executor)
2. Provide: what was done, key outputs, what could be wrong
3. Tell reviewer to be brutal — "looks good" is not acceptable
4. Poll for completion (do not trust auto-announce)
5. Post findings to human IMMEDIATELY before acting
6. Fix HIGH findings, re-verify
7. Only then report task complete

**"Sub-agent said done" ≠ done. "QC said clean" = done.**

Model pairing:
- Haiku executes → Opus reviews
- Sonnet executes → Opus reviews  
- Opus executes → GPT-4o reviews (cross-provider)
```

## Template: QC Spawn Task

Copy-paste this as your QC spawn template. Customize the bracketed sections:

```
Adversarial QC review. Be brutal. Find what's wrong, not what's right.

## What Was Done
[1-3 sentences describing the task and approach]

## Key Outputs  
[List every file created/modified with paths]

## What Could Be Wrong
[Your honest concerns — where you cut corners, what you're unsure about]

## Review Checklist
1. Did the work actually get done? (Check files exist, are non-empty, have expected content)
2. Are there bugs? (Off-by-one, wrong paths, missing error handling, variable scoping)
3. Adjacent breakage? (Does this change break something nearby?)
4. Assumptions? (What did the executor take for granted that might be wrong?)
5. Completeness? (Was anything skipped or left as TODO?)

Rate each finding: 🔴 HIGH (must fix before shipping) / 🟡 MEDIUM (should fix) / 🟢 LOW (nice to have)

Do not say "looks good overall" unless you genuinely found zero issues. 
If you found zero issues, say so explicitly and explain why you're confident.
```

## Real Failures That Proved This Necessary

### The Subshell Bug
Sonnet wrote a health-check script that used `command | while read` — variable modifications inside the pipe were lost in a subshell. The check silently passed on files it should have flagged. Opus QC caught it immediately: "line 47: `STALE` array modified inside pipe subshell — changes lost."

### The Auto-Trim Without Backup  
Haiku wrote `tail -150 observations.md > tmp && mv tmp observations.md` — trims the file but destroys the original on any false positive. Opus QC: "Where's the backup before destructive modification?"

### The 15-Day Unactioned Approval
No agent noticed a human-approved action file sitting in queue/incoming/ for 15 days. Self-healing scripts caught it after we added age-based queue monitoring — but adversarial QC on the queue monitoring code itself caught that the script only checked `.txt` files while the real items were `.md`.

### The "84 Zombie Scripts"
A Haiku sub-agent estimated 84 zombie scripts in the workspace. A more careful systematic check found only 7. Without QC on the original estimate, we'd have wasted hours investigating phantoms.

## Cost

Adversarial QC adds ~10-20% to task cost. The alternative is shipping bugs that take 2-10x longer to find and fix after the fact. The math is obvious.

For a typical Grade M task:
- Haiku execution: ~$0.02
- Opus QC: ~$0.10  
- Total with QC: ~$0.12
- Cost of shipping the subshell bug without QC: 2+ hours of debugging = $2-5 in agent time

## Getting Started

1. Add the QC gate template to your `AGENTS.md`
2. On your next Grade M+ task, spawn a QC reviewer after the work is done
3. Post findings before acting on them
4. Fix HIGHs, log MEDIUMs, note LOWs
5. After a week, review: how many real bugs did QC catch? (It'll be more than zero.)

That's it. No framework to install. No special tooling. Just: **different model reviews the work, findings posted before acting, human has visibility.**
