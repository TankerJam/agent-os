# Adversarial Testing — Cross-Model Review for Agent Work

> Your agent will lie to you about quality. Not maliciously — it's just optimistic by default. The fix: make a different model check the work.

## The Pattern

Every non-trivial piece of agent work gets reviewed by a model from a **different provider** than the one that produced it. The reviewer's job is to find problems, not confirm quality.

```
Agent (Sonnet) produces work
    ↓
Adversarial reviewer (GPT-5.3 / different provider) tears it apart
    ↓
Agent fixes findings OR documents why they're acceptable
    ↓
Only THEN does the human see it
```

The key insight: **models from the same provider share blind spots.** Claude won't catch what Claude missed. GPT won't catch what GPT missed. Cross-provider review catches the gaps that same-provider review misses.

## Three Layers

### Layer 1: Opus QC (Same Provider, Higher Tier)
**When:** Every Grade M/L/XL task (multi-step, multi-file, or high-stakes).
**What:** Spawn a higher-tier model from the same provider as an adversarial reviewer.
**Why:** Catches reasoning errors, missed edge cases, incomplete implementations.

```
Task: Sonnet writes a new SOP
QC: Opus reviews with prompt "Find what's wrong. Be brutal."
```

**Setup (OpenClaw):**
```bash
# In your AGENTS.md or routing rules:
# "Before reporting Grade M/L/XL complete: spawn Opus adversarial QC."
# Template prompt for Opus:
#   "Review this work. What was done: [X]. Key outputs: [Y].
#    Find problems. Be adversarial. Grade: PASS / FAIL / REVISE."
```

### Layer 2: Cross-Provider Review (Different Model, Different Provider)
**When:** Anything customer-facing, infrastructure changes, behavioral rule changes.
**What:** Send the work to a model from a completely different provider.
**Why:** Different training data = different blind spots. This is where you catch the real bugs.

```
Task: Claude writes a blog post about your product
Review: GPT-5.3 checks for factual errors, hallucinated claims, missing context
```

**Setup:**

1. Get an API key from a second provider (OpenAI, Google, etc.)
2. Store it in your system keychain:
   ```bash
   # macOS
   security add-generic-password -a openclaw -s openai-api-key -w "sk-..."
   ```

3. Create a review script (`scripts/cross-model-review.sh`):
   ```bash
   #!/bin/bash
   # Cross-model adversarial review
   # Usage: bash scripts/cross-model-review.sh <file-to-review>
   
   FILE="$1"
   API_KEY=$(security find-generic-password -a openclaw -s openai-api-key -w)
   CONTENT=$(cat "$FILE" | head -500)  # Truncate for token limits
   
   RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d "$(python3 -c "
   import json, sys
   print(json.dumps({
       'model': 'gpt-4o',
       'max_completion_tokens': 2000,
       'messages': [
           {'role': 'system', 'content': 'You are an adversarial reviewer. Find problems: factual errors, logical gaps, missing context, hallucinated claims, things that would embarrass the author. Grade: PASS (ship it), ADEQUATE (minor issues), WEAK (needs revision), FAIL (start over). Be specific and brutal.'},
           {'role': 'user', 'content': '''Review this:\n\n$CONTENT'''}
       ]
   }))
   ")")
   
   echo "$RESPONSE" | python3 -c "
   import json, sys
   d = json.load(sys.stdin)
   print(d['choices'][0]['message']['content'])
   "
   ```

4. Wire it into your workflow:
   ```bash
   # In AGENTS.md behavioral gates:
   # "Before publishing any customer-facing content:
   #  bash scripts/cross-model-review.sh <draft-file>
   #  FAIL/WEAK = fix first. PASS/ADEQUATE = ship."
   ```

### Layer 3: Blind Spot Check (Periodic, Automated)
**When:** Daily or weekly via cron. Reviews agent decisions, not just outputs.
**What:** Feed the adversarial model your agent's recent decisions and ask "what did they miss?"
**Why:** Catches systematic biases your agents develop over time.

```bash
# scripts/blind-spot-check.sh — run daily via cron
# Reads today's memory log + hypothesis cards
# Asks the adversarial model: "What blind spots do you see?"

API_KEY=$(security find-generic-password -a openclaw -s openai-api-key -w)
TODAY=$(date +%Y-%m-%d)
MEMORY=$(cat memory/$TODAY.md 2>/dev/null | tail -100)
HYPOTHESES=$(ls data/hypotheses/$TODAY-*.md 2>/dev/null | xargs cat 2>/dev/null | tail -100)

PROMPT="Here are today's agent decisions and hypothesis cards. What blind spots, biases, or systematic errors do you see? What questions should we be asking that we aren't?

DECISIONS:
$MEMORY

HYPOTHESES:
$HYPOTHESES"

# Call adversarial model...
# Save output to data/blind-spot-reviews/$TODAY.md
```

**OpenClaw cron setup:**
```bash
openclaw cron add \
  --name "blind-spot-check" \
  --cron "55 6 * * *" \
  --agent main \
  --session isolated \
  --model haiku \
  --no-deliver \
  --message "Run: bash scripts/blind-spot-check.sh"
```

## Model Selection Guide

| Your Primary Agent | Adversarial Reviewer | Why |
|---|---|---|
| Claude (Sonnet/Opus) | GPT-4o or GPT-5.3 | Different provider, different training biases |
| GPT-4o | Claude Sonnet | Same logic — cross-provider catches more |
| Gemini | Either Claude or GPT | Gemini has unique blind spots around tool use |
| Any model | Same model, higher tier | Better than nothing, but same-provider has limits |

**Budget guide:** Cross-model reviews cost ~$0.02-0.10 per review depending on input size. Running daily blind-spot checks on a single agent: ~$3-5/month. Cheap insurance.

## What We Learned Running This

1. **Same-provider QC catches ~60% of issues. Cross-provider catches ~85%.** The remaining 15% is stuff no model catches — that's what incident reports and human review are for.

2. **The adversarial model must be told to be adversarial.** Without "be brutal" / "find problems" in the prompt, models default to praise. Explicit: "Grade FAIL if you find any factual error."

3. **Review the reviewers.** Adversarial models can hallucinate problems that don't exist. If a review says "FAIL: the pricing is wrong," verify the pricing actually IS wrong before acting.

4. **Automate the trigger, not just the check.** A review that requires someone to remember to run it will be skipped under pressure. Wire it into crons, heartbeats, or behavioral gates (AGENTS.md rules).

5. **Log everything.** Save all reviews to `data/model-review-audit/` or equivalent. When something breaks in production, grep the reviews to see if any model flagged it and the flag was ignored.

## Quick Start

1. Pick your adversarial model (different provider than your primary agent)
2. Store the API key in your system keychain
3. Copy `scripts/cross-model-review.sh` and adapt the prompt
4. Add a behavioral gate to AGENTS.md: "Before [action], run cross-model review"
5. Add a daily blind-spot cron
6. Review the first week of outputs to calibrate — adjust prompts based on signal quality

That's it. Five steps to catch the mistakes your agent won't catch itself.
