#!/bin/bash
# A/B Test: Brave Search vs Tavily Search
# Tests identical queries on both providers, measures latency + rate limits
#
# Usage: bash search-ab-test.sh
# Requires: BRAVE_API_KEY and TAVILY_API_KEY environment variables
#
# Born from: Misdiagnosed Brave rate limits as auth failures.
# This script proves which provider handles rapid-fire queries.

set -euo pipefail

BRAVE_KEY="${BRAVE_API_KEY:?Set BRAVE_API_KEY}"
TAVILY_KEY="${TAVILY_API_KEY:?Set TAVILY_API_KEY}"

QUERIES=(
  "your search query 1"
  "your search query 2"
  "your search query 3"
)

echo "# Search A/B Test — $(date +%Y-%m-%d)"
echo ""
echo "| Query | Brave Time | Brave Status | Tavily Time | Tavily Status |"
echo "|-------|-----------|-------------|------------|--------------|"

for q in "${QUERIES[@]}"; do
  # Brave
  BRAVE_START=$(python3 -c "import time; print(time.time())")
  BRAVE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
    "https://api.search.brave.com/res/v1/web/search?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$q'))")&count=5" \
    -H "X-Subscription-Token: $BRAVE_KEY" -H "Accept: application/json")
  BRAVE_TIME=$(python3 -c "import time; print(f'{time.time() - $BRAVE_START:.2f}s')")
  
  sleep 2  # Respect Brave rate limit
  
  # Tavily
  TAVILY_START=$(python3 -c "import time; print(time.time())")
  TAVILY_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
    -X POST "https://api.tavily.com/search" \
    -H "Content-Type: application/json" \
    -d "{\"api_key\":\"$TAVILY_KEY\",\"query\":\"$q\",\"max_results\":5,\"search_depth\":\"basic\"}")
  TAVILY_TIME=$(python3 -c "import time; print(f'{time.time() - $TAVILY_START:.2f}s')")
  
  echo "| ${q:0:40} | $BRAVE_TIME | $BRAVE_CODE | $TAVILY_TIME | $TAVILY_CODE |"
  sleep 1
done

echo ""
echo "## Rapid-Fire Test (no spacing)"

for provider in "Brave" "Tavily"; do
  echo "### $provider"
  for i in 1 2 3; do
    if [ "$provider" = "Brave" ]; then
      CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "https://api.search.brave.com/res/v1/web/search?q=test+$i&count=1" \
        -H "X-Subscription-Token: $BRAVE_KEY" -H "Accept: application/json")
    else
      CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -X POST "https://api.tavily.com/search" \
        -H "Content-Type: application/json" \
        -d "{\"api_key\":\"$TAVILY_KEY\",\"query\":\"rapid test $i\",\"max_results\":1,\"search_depth\":\"basic\"}")
    fi
    echo "- Query $i: HTTP $CODE"
  done
done
