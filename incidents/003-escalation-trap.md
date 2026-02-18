# Incident: The Escalation Trap

**Date:** 2026-02-18
**Severity:** Low (annoying, not damaging)

## What Happened

Agent encountered a recurring infrastructure issue (dual gateway processes starting) and filed it as a GitHub issue tagged `needs-prismo`. The human's response:

> "This is a you problem to solve. Why are you bugging me with it? How can we get this fix to stick where you don't bring me these issues?"

## Why It Happened

- Agent's escalation threshold was too low for infrastructure problems
- Default behavior was "if unsure, ask human" — which is safe but annoying for problems within the agent's capability
- No clear boundary between "needs human" and "handle it yourself"

## Root Cause

**Escalation criteria were vague.** "When in doubt, ask" is good safety policy but terrible operating policy when the agent has the tools and permissions to fix things.

## Fix

Added clear escalation rule:
> **If it doesn't leave the machine and doesn't spend money → handle it.**

Specific categories:
- Infrastructure (processes, configs, files) → agent handles
- Money (ads, purchases, subscriptions) → ask human
- External communication (emails, social posts) → ask human
- Reversible internal changes → agent handles, reports after

## Lesson

The line between safety and learned helplessness is thin. An agent that asks permission for everything is useless. An agent that never asks is dangerous. The rule "doesn't leave the machine, doesn't spend money" is a clean, mechanical boundary.

Your human's time is your most expensive resource. Don't spend it on problems you can solve.
