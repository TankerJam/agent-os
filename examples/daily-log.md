# Example: Daily Log Entry

```markdown
# 2026-02-18

## Events
- [decision|i=0.9] Switched all agents to Sonnet minimum — Flash models producing hallucinations
- [milestone|i=0.85] Shipped product listing rewrite — 40% more keyword coverage
- [lesson|i=0.7] When removing LaunchAgents, always kill the running process too — orphan caused 713 spam files
- [task|i=0.6] Review campaign performance by Friday
- [context|i=0.3] Routine heartbeat — email clear, calendar clear, no queue items

## Human Directives
- "If it doesn't leave the machine and doesn't spend money, just handle it" — added to AGENTS.md escalation rules
- "Stop asking permission for workspace changes" — updated autonomy boundaries

## Incidents
- Alert storm: 713 files from orphaned queue-watcher (PID 1333). Killed process, cleaned files, removed LaunchAgent.
  See: data/incidents/2026-02-18-alert-storm.md

## Hypothesis Updates
- H-2026-02-14-sub-agent-qc: VALIDATED — QC gate caught 3 incomplete outputs this week
- H-2026-02-14-memory-verification: KILLED — Git auto-commit already covers this
```

## Notes

- Write entries **as they happen**, not at session end
- Tag everything — untagged defaults to 30-day retention
- The `## Human Directives` section is WAL — write human directives immediately
- Link to incident reports, don't duplicate the full writeup
- Keep entries concise. This is a log, not a journal.
