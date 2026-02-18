# SOP: Sub-Agent Quality Control Gate

*"The sub-agent said done" is NOT done. The QC check is done.*

## The Problem

Sub-agents self-report completion. They lie. Not maliciously — they reach the end of their execution and say "done" even when:
- The output file is empty or stub content
- Expected sections are missing
- The work is incomplete but plausible-sounding

## The Rule

After every sub-agent reports completion, run the QC gate BEFORE marking it done.

## The Gate

```bash
bash scripts/subagent-qc-check.sh <label> <expected_output_path> ["## Section1"] ["## Section2"]
```

Checks:
1. File exists at expected path
2. File is non-empty (>50 bytes)
3. File has >5 lines
4. Expected sections are present (if specified)
5. No stub/placeholder content ("TODO", "placeholder", "lorem ipsum")

Results:
- **Exit 0 = QC_PASS** → Accept the result, mark done
- **Exit 1 = QC_FAIL** → Do NOT mark done. Inspect. Re-spawn or fix manually.

## The Script

```bash
#!/bin/bash
# subagent-qc-check.sh — Mechanical verification gate for sub-agent output
# Usage: bash subagent-qc-check.sh <label> <file_path> [section1] [section2] ...

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
SIZE=$(wc -c < "$FILE")
if [ "$SIZE" -lt 50 ]; then
    echo "QC_FAIL [$LABEL]: File too small (${SIZE} bytes)"
    FAIL=1
fi

# Check >5 lines
LINES=$(wc -l < "$FILE")
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
```

## Why This Works

This is a **Cat 2 system** — triggered mechanically after every sub-agent completion. Not Cat 3 ("remember to check"). The gate fires because the process requires it, not because the agent remembers.

## Common Failures Caught

- Sub-agent wrote a plan file but never executed it
- Sub-agent wrote headers but no content
- Sub-agent copied template without filling it in
- Sub-agent errored silently and wrote partial output
- Sub-agent said "done" in its session but never wrote the output file
