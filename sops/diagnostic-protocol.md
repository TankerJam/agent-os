# Diagnostic Protocol — Logs First, Always

> Born from: Misdiagnosed Brave Search API rate limits as Anthropic auth failures. Deployed wrong fix to 7 agents.

## The Rule

Before treating ANY system failure:

1. **Read the logs**
   ```bash
   grep -i "error\|429\|fail\|cooldown\|timeout" ~/.openclaw/logs/gateway.err.log | tail -20
   ```

2. **Identify the ACTUAL error**
   - Not the wrapper error
   - Not the symptom
   - The root cause
   - Look for: HTTP status codes, rate limit headers, actual error messages

3. **Write hypothesis card** with evidence FROM THE LOGS
   - Quote the specific log line
   - State what you think is happening and why
   - State what you're going to change

4. **Only then deploy the fix**

## Why This Exists

```
What I saw:    "No available auth profile for anthropic (all in cooldown)"
What I treated: Added OpenRouter as cross-provider fallback to ALL agents
What the logs said: "Brave Search 429: plan=Free AI, rate_limit=1, rate_current=1"
Actual fix:    Add 2-second spacing between search queries
```

The auth error was a SECONDARY failure — Anthropic cooled down from rapid retries caused by the search failures. One `grep 429` would have found the root cause in 10 seconds. Instead, a config change was deployed to 7 agents treating the wrong problem.

## The Pattern

| Step | Cat 3 (fails) | Cat 2 (works) |
|------|--------------|---------------|
| Diagnose | "I think it's auth" | `grep 429 gateway.err.log` |
| Plan | "Add fallback" | Write hypothesis card with log evidence |
| Fix | Deploy immediately | Deploy after card |
| Verify | "Should work now" | Check logs again after fix |

## When to Skip

Never. Even if you're 99% sure of the cause, read the logs. It takes 10 seconds and prevents 30-minute misdiagnosis chains.
