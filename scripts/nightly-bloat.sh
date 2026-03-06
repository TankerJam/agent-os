#!/bin/bash
# nightly-bloat.sh — Master self-healing health check
# Runs nightly, aggregates sub-checks, alerts on failures
# Cron: daily at 6:00 AM (after any dream/reflection cycles, before agent wakeup)

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace-main}"
HC="$WORKSPACE/scripts/health-checks"
LOG="$WORKSPACE/logs/nightly-bloat-$(date +%Y-%m-%d).log"
COOLDOWN_FILE="$WORKSPACE/logs/bloat-discord-last-sent.txt"
FAILED=0
FIXED=0
REPORT=""

mkdir -p "$WORKSPACE/logs"
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

run_check() {
  local name="$1"
  local script="$2"
  [ -f "$script" ] || return 0
  log "Running: $name"
  OUTPUT=$(bash "$script" 2>&1) && STATUS=0 || STATUS=$?
  if [ "$STATUS" -ne 0 ]; then
    FAILED=$((FAILED + 1))
    REPORT="${REPORT}\n**${name}** ❌\n${OUTPUT}\n"
    log "FAILED: $name"
  else
    if echo "$OUTPUT" | grep -qi "auto-fix\|auto-trim\|auto-purge"; then
      FIXED=$((FIXED + 1))
    fi
    log "PASSED: $name"
  fi
}

log "=== NIGHTLY BLOAT CHECK START ==="

# Run all health-check scripts in the health-checks directory
for script in "$HC"/*.sh; do
  [ -f "$script" ] || continue
  [ "$(basename "$script")" = "nightly-bloat.sh" ] && continue  # don't recurse
  run_check "$(basename "$script" .sh)" "$script"
done

log "=== SUMMARY: $FAILED failed, $FIXED auto-fixed ==="

# Alert with cooldown (4 hours between alerts)
if [ "$FAILED" -gt 0 ]; then
  LAST_SENT=0
  [ -f "$COOLDOWN_FILE" ] && LAST_SENT=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  ELAPSED=$(( $(date +%s) - LAST_SENT ))
  
  if [ "$ELAPSED" -gt 14400 ]; then
    echo "$(date +%s)" > "$COOLDOWN_FILE"
    # Adapt this to your alert method:
    # - Write to queue for agent to pick up
    # - Use a webhook to post to Discord/Slack
    # - Create a GH issue (with dedup!)
    cat > "$WORKSPACE/queue/incoming/bloat-alert-$(date +%Y%m%d).txt" << EOF
FROM: nightly-bloat.sh
DATE: $(date '+%Y-%m-%d %H:%M')
FAILED: $FAILED checks
FIXED: $FIXED auto-fixed
$(printf '%b' "$REPORT")
EOF
    log "Alert written to queue"
  fi
fi

[ "$FAILED" -gt 0 ] && exit 1 || exit 0
