# SOP: Execution Lifecycle — From Plan to Recovery

**Owner:** Director (all agents inherit)
**Created:** 2026-02-12
**Supersedes:** execution-safety.md (phases 1-5), execution-recovery.md (crash recovery)
**Why:** Plan, execute, recover, and learn must be ONE loop — not three separate SOPs bolted together.

---

## The Loop

Every task that modifies state or takes more than one step follows this lifecycle:

```
PLAN → WRITE THE PLAN → DRY RUN → EXECUTE → TEST → [crash?] → RECOVER → ROOT CAUSE
  ↑                                                                          |
  └──────────────────────── lessons feed back ─────────────────────────────────┘
```

---

## Phase 1: PLAN

Before touching anything:
- **What** are you doing and **why**?
- **Who** is affected? (which agents, which stores, which customers)
- **What could go wrong?** Name the blast radius.
- **What's the rollback path?** Name it before acting. If you can't name it, you can't proceed.
- **What does "done" look like?** Define the test that proves success.
- **What if you crash mid-execution?** How does future-you pick this up?

## Phase 2: WRITE THE PLAN

Create a plan file at `data/execution-plans/{label}-{date}.md`:

```markdown
# Execution Plan: {description}
Created: {timestamp}
Status: IN_PROGRESS

## Objective
{What and why — one sentence}

## Steps
- [ ] Step 1 — {description} → {output file}
- [ ] Step 2 — {description} → {output file}
...

## Rollback
{How to undo each step if needed}

## Success Test
{How do we verify this worked?}

## Crash Recovery
{If session dies mid-execution, here's how to resume:}
1. Check {these files} for progress
2. Pick up at {this step}
3. Don't redo {these completed steps}

## Sub-Agents
| Label | Status | Output |
|-------|--------|--------|
```

**The plan file IS the state.** Not conversation. Not memory. The file.

## Phase 3: DRY RUN

Preview the change without applying it:
- **Files:** Show the diff, don't write it
- **API calls:** Log what WOULD be sent
- **PPC/ads:** Calculate projected impact
- **Listings:** Draft in a file, never edit live without staged draft
- **Config:** `config.get` before `config.patch`
- **If no dry run is possible:** Flag for human review. Do not proceed.

## Phase 4: EXECUTE

- Snapshot current state FIRST (backups before changes)
  - KB files: `.bak` copy
  - Listings: `data/listing-snapshots/`
  - WordPress: `data/wordpress-snapshots/`
  - Config: save current config
  - **If you can't snapshot it, you can't change it.**
- Apply the change
- Update plan file: check the box, note timestamp, note output path
- If using sub-agents: log their labels and session keys in the plan file

## Phase 5: TEST (Dual Verification)

- Verify the change took effect
- Check for unintended side effects
- Run the success test defined in Phase 1
- For multi-step work: test after EACH step, not just at the end
- **For sub-agents: NEVER trust self-reported success.** See `sops/sub-agent-qc.md`.
  1. Verify output files exist and are non-trivial (`ls -la`)
  2. Spot-check content (read first 20 lines)
  3. For browser tasks: verify external state actually changed
  4. For critical tasks: spawn a SEPARATE QC agent (execution ≠ verification)
- **If test fails:** rollback using the path defined in Phase 1, then go to Phase 7 (RCA)

## Phase 6: RECOVER (after crash/compaction/reset)

On every session start and every heartbeat:

1. `ls data/execution-plans/` — any IN_PROGRESS plans?
2. Read each plan file
3. Check which steps are completed (checkboxes + output files exist)
4. Check sub-agent status (labels in sessions_list)
5. Resume from last completed step — DO NOT restart from scratch
6. If plan is stale (>24h, no progress): clean up or escalate

**Key principle:** The plan file + output files must contain enough information to resume WITHOUT any conversation history. If they don't, the plan file was insufficient.

## Phase 7: ROOT CAUSE ANALYSIS (after any failure)

**RCA is autonomous. When you find a fault, you OWN the full loop: find → fix → verify → propagate → close. Do not stop at diagnosis. Do not report and wait. Complete the loop, then inform Prismo what you changed.**

After every failure, unexpected result, or Prismo correction:

### The Five Questions
1. **What happened?** (facts, not interpretation)
2. **How would I have known?** (what signal did I miss?)
3. **What assumption was wrong?** (find the bad mental model)
4. **What structural fix makes this class of error impossible?** (not "I'll try harder" — what SYSTEM change?)
   - **What category is your fix?** Cat 1 (automatic/cron)? Cat 2 (triggered)? Cat 3 (habit-based)? If Cat 3 → redesign. See `sops/systems-design-for-stateless-agents.md`.
5. **Where else could this assumption be wrong?** (propagate the fix)

### The Propagation Checklist
**Applies to EVERY insight, decision, fix, or new knowledge — not just failures.**
Director holds the big picture. If you learn it and don't push it, the insight dies in your workspace.

Before declaring any change, fix, or new idea complete:
- [ ] Which agents need this? (support, operations, marketing — think broadly)
- [ ] Which files were updated in EACH agent's workspace?
- [ ] Which agents were NOT updated and why? (justify the skip)
- [ ] Is there a recurring check that enforces this? (heartbeat/cron/board item)
- [ ] Is the lesson in MEMORY.md? (survives compaction)
- [ ] Is DOCTRINE.md updated if this is strategic? (read by all agents every session)

**Examples that require propagation:**
- New customer insight → all agents that create content or talk to customers
- Trademark/compliance rule → operations + marketing + support
- Product knowledge → support KB + marketing content + operations listings
- Process improvement → every agent that runs similar processes
- Prismo preference/correction → every agent that might repeat the mistake

### The RCA Loop Is Autonomous
When you observe a fault:
1. **Find** — identify what broke and why (Five Questions)
2. **Fix** — implement the structural change NOW, don't just document it
3. **Verify** — confirm the fix works (artifact check, test)
4. **Propagate** — push the lesson to all affected agents, SOPs, MEMORY.md
5. **Close** — mark the execution plan DONE, inform Prismo what changed

**Do NOT stop after step 1 and ask what to do.** You are the CEO. You found the fault, you fix it. Report after, not before. Prismo can revert if needed.

**Do NOT wait for permission between steps.** The entire loop — find through close — happens in one motion. If you identified a problem but haven't propagated the fix, the RCA is incomplete.

### Double-Loop Learning
Don't just fix the error — fix the system that allowed it.
"What structural change makes this class of error impossible?"
If the fix is "be more careful next time" — you haven't fixed anything.

---

## The Read-First Rule

Before stating any fact, number, count, or data point: **read the source file.** Not from memory, not from context — from the file.

- Support: read KB file before answering technical questions
- Operations: read data file before reporting numbers
- Marketing: read product use cases before writing copy
- Director: read output files before confirming sub-agent success

**"I remember" ≠ "I verified."** Files are truth, memory is cache, fabrication is failure.

## Anti-Patterns

- ❌ **"I'll remember"** — you won't after compaction
- ❌ **Starting from scratch** without checking what last attempt accomplished
- ❌ **Logging progress only in conversation** — dies with session
- ❌ **"Be more careful next time"** as an RCA conclusion — that's not a structural fix
- ❌ **Sub-agents that don't write progress files** — fire and forget = forget
- ❌ **Testing only at the end** — test each step
- ❌ **Skipping dry run because "it's simple"** — simple things break too
- ❌ **Planning in your head** — if the plan isn't in a file, it doesn't exist
- ❌ **Workarounds without cleanup tasks** — every workaround MUST have a "remove this by [date/condition]" note in MEMORY.md or the daily log. Temporary fixes that aren't tracked become permanent bugs
- ❌ **Executing without reading the relevant strategy doc** — if a strategy/best-practices doc exists for the domain you're changing (PPC, listings, content, agent config), READ IT before making changes. Writing a great plan then violating it is worse than having no plan. The pre-flight is: "What does our written strategy say about this?"

---

## Quick Reference

| Situation | Action |
|-----------|--------|
| New task (>1 step) | Create plan file → dry run → execute → test |
| Sub-agent spawn | Log label + session key in plan file |
| Sub-agent returns | Update plan file, QC output, check the box |
| Session starts | Check `data/execution-plans/` for IN_PROGRESS |
| Something breaks | Rollback → RCA → Five Questions → propagate fix |
| Prismo corrects you | RCA → structural fix → update all agents → MEMORY.md |
