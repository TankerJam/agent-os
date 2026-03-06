#!/bin/bash
# mycelium-relay.sh — Mechanized cross-agent substrate signaling
# The actual mycelium network: reads substrate files, routes domain signals
# Replaces aspirational "read other agents' files" instructions
# Cron: every 30 min via cron or LaunchAgent

set -euo pipefail

# Configure these for your setup
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace-main}"
SUBSTRATE="$WORKSPACE/data/substrate"
STATE_FILE="$WORKSPACE/data/mycelium-relay-state.json"
LOG="$WORKSPACE/logs/mycelium-relay.log"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$WORKSPACE/logs" "$WORKSPACE/data"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# Domain routing — customize keywords for your agent domains
route_domain() {
  local signal_lower="$1"
  local targets=()
  echo "$signal_lower" | grep -qiE "amazon|ppc|inventory|listing" && targets+=("workspace-operations")
  echo "$signal_lower" | grep -qiE "blog|tweet|content|seo|social" && targets+=("workspace-marketing")
  echo "$signal_lower" | grep -qiE "support|discord|customer" && targets+=("workspace-support")
  echo "$signal_lower" | grep -qiE "ticket|helpdesk" && targets+=("workspace-ticketing")
  echo "$signal_lower" | grep -qiE "reddit|competitor|research|intel" && targets+=("workspace-research")
  echo "$signal_lower" | grep -qiE "cron|gateway|script|config|infra" && targets+=("workspace-devops")
  [ ${#targets[@]} -gt 0 ] && printf '%s\n' "${targets[@]}" || true
}

# Load last-seen state
LAST_STATE="{}"
[ -f "$STATE_FILE" ] && LAST_STATE=$(cat "$STATE_FILE")

ROUTED=0

for substrate_file in "$SUBSTRATE/${TODAY}-"*.md; do
  [ -f "$substrate_file" ] || continue
  agent_name=$(basename "$substrate_file" .md | sed "s/${TODAY}-//")
  
  CURRENT_MTIME=$(stat -f %m "$substrate_file" 2>/dev/null || stat -c %Y "$substrate_file" 2>/dev/null || echo 0)
  LAST_MTIME=$(echo "$LAST_STATE" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print(d.get('$(basename "$substrate_file")', 0))
" 2>/dev/null || echo 0)
  
  [ "$CURRENT_MTIME" -le "$LAST_MTIME" ] && continue
  
  SIGNAL=$(awk '/^## Signal/{flag=1; next} /^##/{flag=0} flag' "$substrate_file" 2>/dev/null | \
    grep -v "NONE\|^$" | head -5)
  [ -z "$SIGNAL" ] && continue
  
  log "New signal from $agent_name: $SIGNAL"
  
  SIGNAL_LOWER=$(echo "$SIGNAL" | tr '[:upper:]' '[:lower:]')
  while IFS= read -r target_ws; do
    [ -z "$target_ws" ] && continue
    [ "$target_ws" = "workspace-${agent_name}" ] && continue
    
    WS_BASE=$(dirname "$WORKSPACE")
    TARGET_DIR="$WS_BASE/$target_ws"
    [ -d "$TARGET_DIR" ] || continue
    mkdir -p "$TARGET_DIR/queue/incoming"
    
    cat > "$TARGET_DIR/queue/incoming/mycelium-${agent_name}-$(date +%Y%m%d-%H%M).txt" << QEOF
FROM: Mycelium Relay (auto-routed from $agent_name substrate)
DATE: $(date '+%Y-%m-%d %H:%M')
SIGNAL: $SIGNAL
NOTE: Detected as relevant to your domain. Act directly — no Director routing needed.
QEOF
    ROUTED=$((ROUTED + 1))
    log "  → routed to $target_ws"
  done < <(route_domain "$SIGNAL_LOWER")
done

# Save state
python3 -c "
import json, os, glob
state = {}
for f in glob.glob('$SUBSTRATE/${TODAY}-*.md'):
    try: state[os.path.basename(f)] = int(os.path.getmtime(f))
    except: pass
print(json.dumps(state, indent=2))
" > "$STATE_FILE" 2>/dev/null || echo "{}" > "$STATE_FILE"

[ "$ROUTED" -gt 0 ] && log "Relayed $ROUTED signals" || log "No new signals"
exit 0
