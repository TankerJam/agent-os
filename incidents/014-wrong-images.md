# Incident 014: The Wrong Images

**Date:** 2026-03-23 (discovered; live for ~3 weeks)  
**Severity:** HIGH — customer-facing, wrong product imagery on published content  
**Detected by:** Human (manual)

## What Happened

A blog image generation pipeline produced featured images for 20 posts. 8 of them showed the wrong product or no product at all — generic breadboards, wrong hardware, satellite illustrations instead of actual product photos.

These images were live on the company website for approximately 3 weeks before the human noticed.

A QC script existed (`image-qc.py`) but only checked for technical quality (resolution, aspect ratio) — not whether the image showed the correct product.

## Root Cause

1. **QC checked format, not content.** The script verified the image was the right size but not that it showed the right thing.
2. **No human review gate on customer-facing visual content.** Images went live without anyone looking at them.
3. **Batch generation without batch review.** 20 images generated and published in one pipeline run. Individual review at scale was skipped.

## The Fixes

1. **Product identity verification in QC script:** Must confirm the actual product is visible
2. **Visual review gate for customer-facing content:** Human or cross-model visual verification before publish
3. **Audit cadence:** Periodic review of all published visual content

## Lesson

Automated QC that checks form but not substance is worse than no QC — it creates false confidence. "The QC passed" meant "it's the right pixel dimensions" not "it's the right product." When content is customer-facing, the QC must verify what the customer actually sees.
