# Example: Execution Plan

```markdown
# Execution Plan: Migrate Support KB to New Format
Created: 2026-02-15 09:00 MST
Status: COMPLETE

## Objective
Restructure 47 knowledge base articles from flat files to categorized directories with metadata headers.

## Steps
- [x] Step 1 — Inventory current KB articles → data/kb-inventory.md
- [x] Step 2 — Define category taxonomy → data/kb-categories.md  
- [x] Step 3 — Create directory structure → kb/{category}/
- [x] Step 4 — Migrate articles (batch of 10) → kb/getting-started/
- [x] Step 5 — Migrate articles (batch of 10) → kb/troubleshooting/
- [x] Step 6 — Migrate articles (batch of 10) → kb/hardware/
- [x] Step 7 — Migrate remaining 17 → kb/advanced/, kb/faq/
- [x] Step 8 — Update all internal links
- [x] Step 9 — Verify no broken references

## Rollback
Git revert — all changes in a single commit. Old structure preserved in git history.

## Success Test
- All 47 articles accessible in new paths
- No broken internal links (grep for old paths returns 0)
- Support agent can find articles by category

## Crash Recovery
1. Check kb/ directories for migrated articles (count files)
2. Check data/kb-inventory.md for migration status markers
3. Resume from first unchecked step
4. Steps 1-3 are idempotent — safe to re-run

## Sub-Agents
| Label | Status | Output |
|-------|--------|--------|
| kb-migrate-batch1 | COMPLETE | kb/getting-started/ (10 articles) |
| kb-migrate-batch2 | COMPLETE | kb/troubleshooting/ (10 articles) |
| kb-migrate-batch3 | COMPLETE | kb/hardware/ (10 articles) |
```

## Notes

- Every multi-step task gets a plan file. No exceptions.
- Update checkboxes AS you complete steps, not after.
- The plan file IS the state. If conversation dies, this is how you resume.
- Sub-agent labels go in the plan so you can check their status.
