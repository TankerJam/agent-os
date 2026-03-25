# Incident 014: The Content QC Gap

**Date:** Month 4 (discovered; content was live for ~3 weeks)  
**Severity:** HIGH — customer-facing, wrong content published  
**Detected by:** Human (manual)

## What Happened

An automated content generation pipeline produced output for ~20 items. Several of them had incorrect content — wrong references, wrong imagery, mismatched context. They were published and live for approximately 3 weeks before the human noticed.

An automated QC script existed but only checked technical quality (format, dimensions) — not whether the content was actually correct.

## Root Cause

1. **QC checked format, not substance.** The script verified technical specs but not content accuracy.
2. **No human review gate on customer-facing content.** Output went live without anyone looking at it.
3. **Batch generation without batch review.** Many items generated and published in one pipeline run. Individual review at scale was skipped.

## The Fixes

1. **Content-level verification in QC:** Must verify substance, not just format
2. **Review gate for customer-facing output:** Human or cross-model verification before publish
3. **Audit cadence:** Periodic review of all published content

## Lesson

Automated QC that checks form but not substance is worse than no QC — it creates false confidence. "QC passed" meant "it met technical specs" not "it's correct." When content is customer-facing, QC must verify what the customer actually sees.
