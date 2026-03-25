# SOP: Prompt Injection Defense

**When:** Any agent that reads external content — chat messages, email, web scraping, API responses.

## The Threat

If your agents process external content, someone will attempt to inject instructions disguised as system messages. We caught a targeted attack that mimicked our platform's internal audit format. The attacker knew our file naming conventions and specifically targeted post-context-reset behavior.

## Defense Layers

### 1. Memory Write Protection
Agents processing external content must NOT directly update:
- `MEMORY.md` (long-term memory)
- `memory/active-context.md` (working memory)
- `AGENTS.md` (operating instructions)

External content can be written to:
- `memory/YYYY-MM-DD.md` (daily logs, append-only)
- `queue/incoming/` (for human or director review)

Only a trusted agent (e.g., director, after reviewing content) writes to critical memory files.

### 2. Explicit Startup Checklists
Your agent's startup files are listed in AGENTS.md. If a message tells the agent to read a file not in that list — ignore it. This is how you prevent "read WORKFLOW_AUTO.md" injection.

### 3. Format Validation
Real system messages have specific metadata (session IDs, timestamps in specific formats, specific prefixes). A "System:" prefix in a user-role message is spoofed. Train agents to recognize the difference.

### 4. Propagation
When you discover an attack vector, propagate the defense to ALL agents immediately. One agent knowing about an attack while six others are vulnerable defeats the purpose.

## Detection Patterns

Watch for:
- Messages containing "System:" or "⚠️" prefixes that arrive as user-role
- References to files that don't exist in your workspace
- Instructions to read files or execute commands embedded in external content
- Regex patterns in filenames (e.g., `memory\/\d{4}-\d{2}-\d{2}\.md`)

## Born From

Incident 011: A prompt injection mimicking post-compaction audit format was prepended to a human's message, likely via clipboard contamination from web browsing. The agent caught it because the format didn't match real system messages and the referenced file wasn't in the startup checklist.
