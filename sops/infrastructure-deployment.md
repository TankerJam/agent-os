# SOP: Infrastructure Deployment — Two-Person Rule

**When:** Any time an agent deploys scripts, cron jobs, config changes, or system-level infrastructure.

## The Problem

The agent that builds infrastructure is optimistic about its own work. It will "verify" its own deployment and miss the same things it missed while building. The Auth Break incident (009) proved this: the agent that deployed auth changes also "verified" them, and both steps had the same blind spot.

## The Rule

**Builder ≠ Validator.** The agent that creates infrastructure must hand it off to a different agent (or the human) for validation.

## Required Steps

### Before Deploy
- [ ] Write an execution plan to `data/execution-plans/`
- [ ] Identify the validator (different agent or human)
- [ ] Check if similar infrastructure already exists

### During Deploy
- [ ] Follow the execution plan
- [ ] Test each component individually

### After Deploy — Validation (by a DIFFERENT agent)
- [ ] **Smoke test:** Run each script, verify exit 0
- [ ] **Output validation:** Check output is correct, not just present
- [ ] **Security scan:** No secrets in output (`grep -iE "sk-|api.key|password|token"`)
- [ ] **Idempotency test:** Run twice, verify no duplication or corruption
- [ ] **Failure test:** What happens if a dependency is missing?

### Handoff
- [ ] Document in knowledge base
- [ ] Add health checks to validator's heartbeat
- [ ] Queue notification to validator

## Why This Matters

An agent reviewing its own work is a mirror checking itself for smudges. You need a window.
