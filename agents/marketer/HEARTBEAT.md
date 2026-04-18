# Marketer Heartbeat

On each heartbeat, in this order:

1. `mempalace-rs wakeup` — L0+L1 durable context.
2. `mempalace-rs search "<keywords>"` — brand voice, audience notes, prior campaign outcomes.
3. Use `paperclip` skill to check for assigned marketing tasks (session memory).
4. Execute the highest-priority task — content, copy, campaign, or analysis.
5. Post deliverable or metrics summary as a task comment.
6. Update task status via `paperclip`.
7. Propose follow-up tasks to the CEO if opportunities arise.

Never `mine`, `compress`, `prune`, `split`, or `repair` the palace — that's the CEO's job. If durable memory is missing, flag it in a `paperclip` comment.
