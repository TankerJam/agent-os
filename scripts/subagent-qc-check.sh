#!/bin/bash
# subagent-qc-check.sh — Mechanical verification gate for sub-agent output
# Usage: bash subagent-qc-check.sh <label> <file_path> [section1] [section2] ...
#
# Exit 0 = QC_PASS — accept the result
# Exit 1 = QC_FAIL — do NOT mark done; inspect and re-spawn or fix

LABEL="$1"
FILE="$2"
shift 2
SECTIONS=("$@")

FAIL=0

# Check file exists
if [ ! -f "$FILE" ]; then
    echo "QC_FAIL [$LABEL]: File not found: $FILE"
    exit 1
fi

# Check non-empty (>50 bytes)
SIZE=$(wc -c < "$FILE" | tr -d ' ')
if [ "$SIZE" -lt 50 ]; then
    echo "QC_FAIL [$LABEL]: File too small (${SIZE} bytes)"
    FAIL=1
fi

# Check >5 lines
LINES=$(wc -l < "$FILE" | tr -d ' ')
if [ "$LINES" -lt 5 ]; then
    echo "QC_FAIL [$LABEL]: Too few lines (${LINES})"
    FAIL=1
fi

# Check for stub content
if grep -qiE '(TODO|placeholder|lorem ipsum|FIXME|TBD)' "$FILE"; then
    echo "QC_FAIL [$LABEL]: Stub content detected"
    FAIL=1
fi

# Check expected sections
for SECTION in "${SECTIONS[@]}"; do
    if ! grep -qF "$SECTION" "$FILE"; then
        echo "QC_FAIL [$LABEL]: Missing section: $SECTION"
        FAIL=1
    fi
done

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "QC_PASS [$LABEL]: All checks passed (${SIZE}B, ${LINES}L)"
exit 0
