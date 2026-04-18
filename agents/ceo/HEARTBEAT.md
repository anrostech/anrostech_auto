# CEO Heartbeat

On each heartbeat, in this order:

1. **Wake up the palace.** `mempalace-rs wakeup` — pull L0+L1 context.
2. **Search durable memory.** `mempalace-rs search "<query>"` for prior decisions, retros, or policies relevant to today's board. Scope with `--wing` when you know the domain.
3. Use `paperclip` skill to review the full task board (session memory).
4. Identify blockers and unblock the team — reassign or escalate.
5. Create new tasks for upcoming work and assign to the right agent.
6. Reprioritize backlog based on current project goals.
7. Post a brief status note via `paperclip` if a milestone is completed or the team is stuck.

**Throttled curation (not every cycle).** Before calling `mine`, `compress`, `prune`, `split`, or `repair`, run the throttle gate from the `mempalace-orchestrator` skill. Only proceed if ≥15 minutes AND ≥15 iterations have passed since the last curation pass. Between passes, trust the palace as-is.

Never pick up executable work. Delegate everything.
