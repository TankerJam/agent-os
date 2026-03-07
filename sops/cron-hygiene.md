# Cron Hygiene — Managing OpenClaw Scheduled Jobs at Scale

> Read this BEFORE creating or editing any OpenClaw cron job.
> Born from running 64 crons across 7 agents — and watching half of them silently fail.

## Why This Exists

Crons compound. One misconfigured job is a bug. Sixty misconfigured jobs are a system failure. Without hygiene standards:
- Jobs run in UTC when you think they're local time
- Delivery failures silently kill job output
- Opus-tier models burn tokens on `grep` jobs
- Agents wake cold with no idea why they're running
- Duplicate crons accumulate because nobody checks before creating

## Required Flags — Every Cron Job

```bash
openclaw cron add \
  --name "descriptive-kebab-case-name" \
  --agent {agent-id} \
  --cron "expr" \
  --tz "America/Denver" \
  --best-effort-deliver \
  --session isolated \
  --model {appropriate-model} \
  --message "self-contained task description"
```

### Flag Reference

| Flag | Required? | Why |
|------|-----------|-----|
| `--name` | **Yes** | Descriptive kebab-case. Grep-friendly. Must be unique. |
| `--agent` | **Yes** | Pin to the agent that owns this domain. Never leave as default. |
| `--tz` | **Yes** | Without this, cron uses UTC. Your 6 AM job fires at midnight. |
| `--best-effort-deliver` | **Yes** | Without this, delivery failure = silent job failure. |
| `--session isolated` | **Yes** | Never pollute main session with cron noise. |
| `--model` | **Yes** | Right-size the model. See model selection below. |
| `--message` | **Yes** | Self-contained. Agent wakes cold — full context in the message. |
| `--timeout-seconds` | Recommended | Default 30s is too short for scripts. Use 60-120s. |

### Model Selection

Pick the cheapest model that can do the job. Crons run frequently — cost compounds.

| Task Type | Model | Examples |
|-----------|-------|---------|
| Run a script, grep, file ops | `haiku` | health checks, queue sweeps, archival |
| Read + reason + write | `sonnet` | content review, synthesis, KB updates |
| Strategy, cross-domain | `opus` | weekly reviews only. Rare for crons. |

**Default to Haiku.** Most crons are mechanical. If the message says "Run: bash ...", it's Haiku.

### Message Writing

The agent wakes with NO memory of why it's running. The message IS the entire context.

**Bad:** `Check the queue`

**Good:**
```
Run: bash /absolute/path/to/scripts/queue-sweep.sh
If any items found, summarize and write to queue/incoming/sweep-results.md.
If clean, reply HEARTBEAT_OK.
```

Rules:
- **Absolute paths.** The agent doesn't know its working directory.
- **State what to do with output.** Post it? Write a file? Stay silent?
- **Spell out conditions.** "If X, then Y. Otherwise Z."

## Performance Flags — Use These

| Flag | When | Impact |
|------|------|--------|
| `--light-context` | Script-runners that don't need workspace files | **Saves 5-15K tokens/run.** Skips AGENTS.md/SOUL.md/MEMORY.md injection. |
| `--no-deliver` | Background jobs that write to files, not chat | Suppresses announce delivery. |
| `--stagger` | Top-of-hour crons (`0 * * * *`) | Prevents load spikes when 10+ crons fire simultaneously. |
| `--thinking off` | Mechanical Haiku tasks | Saves thinking tokens. |

### `--light-context` Guidance

This is the most impactful optimization most setups miss. If your cron says "Run: bash ..." and the script handles all the logic, the agent doesn't need its full workspace bootstrap.

```bash
# YES — script does the work, agent just executes
openclaw cron add --light-context --model haiku \
  --message "Run: bash /path/scripts/health-check.sh. Report output."

# NO — agent needs identity/business context to reason
openclaw cron add --model sonnet \
  --message "Review support tickets and draft KB articles for common issues."
```

## Cron Monitoring

### Check Error State
```bash
# Overall status
openclaw cron status

# Jobs in error
openclaw cron list --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
errors = [(j['name'], j.get('state',{}).get('consecutiveErrors',0))
          for j in data.get('jobs',[]) if j.get('state',{}).get('consecutiveErrors',0) > 0]
for name, ce in sorted(errors, key=lambda x: -x[1]):
    print(f'  ⚠️  {name}: {ce} consecutive errors')
print(f'Total: {len(errors)} in error')
"

# Run history for a specific job
openclaw cron runs --id <job-id> --limit 5
```

### Automated Hygiene Check
Run `scripts/cron-hygiene-check.sh` nightly to catch violations. It checks every enabled cron for:
- `--tz` set
- `--model` explicitly set
- `--best-effort-deliver` enabled
- `--session isolated`

Wire it into your nightly health check aggregator.

### External Watchdog
The Gateway hosts the cron scheduler. If the Gateway dies, ALL crons stop silently. Use a system-level watchdog (LaunchAgent, systemd timer, or system crontab) that runs independently:

```bash
# System crontab — runs even if OpenClaw is down
*/5 * * * * curl -fsS http://127.0.0.1:18789/health > /dev/null 2>&1 || \
  echo "OpenClaw Gateway DOWN" >> /var/log/openclaw-watchdog.log
```

### Built-in Dashboard
```bash
openclaw dashboard  # Opens web UI with cron/session/cost visibility
```

## Naming Convention

```
{domain}-{action}[-{detail}]
```

Examples: `support-kb-refresh`, `marketing-tweet-daily`, `devops-health-check`, `ops-reimbursement-scan`

## Domain Ownership

Pin every cron to the agent that owns that domain. Don't assign support work to the director agent.

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Missing `--tz` | Runs in UTC, not local time | Always set `--tz` |
| Missing `--best-effort-deliver` | Delivery failure kills the job silently | Always set it |
| Opus for `Run: bash` jobs | Burns 10-50x more tokens than needed | Use Haiku |
| Vague message | Agent wakes cold, hallucinates the task | Full context in message |
| No dedup before creating | Duplicate crons accumulate | Check `openclaw cron list` first |
| No `--light-context` on scripts | Wastes 5-15K tokens loading workspace files | Add it for mechanical jobs |
| All crons at top-of-hour | Load spikes, rate limits | Use `--stagger` or offset minutes |

## Verification After Creation

```bash
openclaw cron list --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for j in data.get('jobs',[]):
    if j['name'] == 'YOUR-CRON-NAME':
        s = j.get('schedule',{})
        p = j.get('payload',{})
        d = j.get('delivery',{})
        tz = s.get('tz','MISSING ⚠️')
        model = p.get('model','DEFAULT ⚠️')
        be = d.get('bestEffort', False)
        iso = j.get('sessionTarget','?') == 'isolated'
        ok = all([s.get('tz'), p.get('model'), be, iso])
        print(f'TZ: {tz} | Model: {model} | BestEffort: {be} | Isolated: {iso}')
        print(f'Hygiene: {\"✅ PASS\" if ok else \"❌ FIX REQUIRED\"} ')
"
```

## What the Community Does

Patterns from production OpenClaw setups (LumaDock, OpenClaw Pulse, Trilogy AI):

1. **Cron for exact timing, heartbeat for routine sweeps.** Don't use cron for "check inbox roughly every 30 min" — that's heartbeat. Use cron for "daily briefing at 7 AM sharp."
2. **Isolated sessions for everything except follow-ups.** Main session crons spam your conversation history.
3. **Model override per job, not per agent.** A morning briefing needs Sonnet; a health check needs Haiku. Don't pay Sonnet prices for grep.
4. **Webhook delivery for critical alerts.** Instead of hoping the chat channel is up, POST to a webhook endpoint. `--delivery webhook --to "https://your-endpoint"`.
5. **`openclaw dashboard` for visual monitoring.** The CLI is powerful but the dashboard shows trends.
6. **System-level watchdog watching OpenClaw.** If the Gateway crashes, cron dies silently. Always have an external check.
7. **QMD weekly compaction via cron.** Memory maintenance runs at 2 AM Sunday — never during working hours.
8. **Dream routines as cron, not heartbeat.** Cron guarantees execution even if the agent is busy at 3 AM.
