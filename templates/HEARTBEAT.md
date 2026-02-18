# HEARTBEAT.md — Periodic Check-In Tasks

<!-- This runs every heartbeat interval (typically 15-60 min). -->
<!-- Start with 2-3 checks. Grow as needed. Don't overload. -->

## Checks

### 1. Queue Sweep
Check `queue/incoming/` for items from other agents or systems:
- Noise/duplicates → delete
- Things you can handle → do them, move to `queue/done/`
- Things needing your human → keep, mention in next report

### 2. [Your Check Here]
<!-- Examples: -->
<!-- - Check email for urgent messages -->
<!-- - Review upcoming calendar events -->
<!-- - Check GitHub issues for new tasks -->
<!-- - Monitor a service status -->

### 3. [Your Check Here]

## When to Stay Quiet
- Late night (23:00-08:00) unless urgent
- Human is clearly busy
- Nothing new since last check
- Last check was <30 minutes ago

Reply `HEARTBEAT_OK` when nothing needs attention.
