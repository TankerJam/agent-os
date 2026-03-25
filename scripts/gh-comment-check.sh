#!/bin/bash
# GitHub Issue Comment Monitor — Cat 1 automation
# Tracks last-seen comment per issue, alerts on new ones
# Designed for cron: checks labeled issues for new human comments
#
# Usage: bash gh-comment-check.sh
# Requires: gh CLI authenticated, jq or python3
#
# Born from: Human approved a deploy via GitHub comment. Agent never saw it.
# No cron was reading GitHub comments despite claiming to "check every hour."

set -euo pipefail

# CONFIGURE THESE
REPO="${GH_REPO:-your-org/your-repo}"
LABEL="${GH_LABEL:-needs-prismo}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$(pwd)}"
STATE_FILE="$WORKSPACE/data/gh-comment-state.json"

[ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"

gh issue list --repo "$REPO" --label "$LABEL" --state open --json number,title | \
python3 -c "
import json, subprocess, sys

state_file = '$STATE_FILE'
repo = '$REPO'

with open(state_file) as f:
    state = json.load(f)

issues = json.load(sys.stdin)
alerts = []

for issue in issues:
    num = str(issue['number'])
    title = issue['title']
    
    result = subprocess.run(
        ['gh', 'api', f'repos/{repo}/issues/{num}/comments', '--jq', '.[].created_at'],
        capture_output=True, text=True, timeout=10
    )
    
    timestamps = result.stdout.strip().split('\n') if result.stdout.strip() else []
    latest_ts = timestamps[-1] if timestamps else ''
    
    if not latest_ts:
        continue
    
    last_seen = state.get(num, '')
    
    if latest_ts != last_seen:
        detail = subprocess.run(
            ['gh', 'api', f'repos/{repo}/issues/{num}/comments?per_page=1&sort=created&direction=desc',
             '--jq', '.[0] | (.user.login + \": \" + (.body | gsub(\"[\n\r]+\"; \" \") | .[0:200]))'],
            capture_output=True, text=True, timeout=10
        )
        body = detail.stdout.strip()
        alerts.append(f'🆕 #{num} ({title}): {body} [{latest_ts}]')
        state[num] = latest_ts

with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)

if alerts:
    print('=== NEW GITHUB COMMENTS ===')
    for a in alerts:
        print(a)
else:
    print('No new comments.')
"
