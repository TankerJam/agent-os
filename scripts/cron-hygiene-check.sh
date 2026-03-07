#!/bin/bash
# cron-hygiene-check.sh — Verify all OpenClaw crons follow hygiene standards
# Checks: --tz, --best-effort-deliver, --model explicit, --session isolated
# Run nightly or on DevOps heartbeat. Exit 0 = clean, Exit 1 = issues found.

set -euo pipefail

TMPJSON=$(mktemp)
trap "rm -f '$TMPJSON'" EXIT

if ! openclaw cron list --json > "$TMPJSON" 2>/dev/null; then
    echo "ERROR: Could not list crons (is the Gateway running?)"
    exit 1
fi

python3 - "$TMPJSON" << 'PYEOF'
import json, sys

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    jobs = data.get('jobs', [])
    issues = []
    stats = {'total': 0, 'no_tz': 0, 'no_model': 0, 'no_be': 0, 'not_isolated': 0}
    
    for job in jobs:
        if not job.get('enabled', True):
            continue
        stats['total'] += 1
        name = job.get('name', '')
        sched = job.get('schedule', {})
        payload = job.get('payload', {})
        delivery = job.get('delivery', {})
        
        if not sched.get('tz') and sched.get('kind') != 'at':
            issues.append(f'⚠️  {name}: missing --tz')
            stats['no_tz'] += 1
        if not payload.get('model'):
            issues.append(f'⚠️  {name}: no --model')
            stats['no_model'] += 1
        if not delivery.get('bestEffort', False):
            issues.append(f'⚠️  {name}: no --best-effort-deliver')
            stats['no_be'] += 1
        if job.get('sessionTarget') != 'isolated':
            issues.append(f'⚠️  {name}: not isolated')
            stats['not_isolated'] += 1
    
    if issues:
        print("Cron hygiene issues:")
        for i in issues[:20]:
            print(i)
        if len(issues) > 20:
            print(f"... +{len(issues)-20} more")
        total = stats['no_tz'] + stats['no_model'] + stats['no_be'] + stats['not_isolated']
        print(f"\n{total} issues in {stats['total']} crons")
        sys.exit(1)
    else:
        print(f"✅ All {stats['total']} crons pass hygiene")
        sys.exit(0)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
PYEOF
