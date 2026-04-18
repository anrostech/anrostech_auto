# Reviewer Heartbeat

On each heartbeat, in this order:

1. `mempalace-rs wakeup` — L0+L1 durable context.
2. `mempalace-rs search "<keywords>"` — architecture decisions, review standards, recurring rejection patterns relevant to today's review queue.
3. Use `paperclip` skill to check for assigned review tasks (session memory).
4. Review the code or PR — logic and security before style.
5. Post concise, actionable feedback as a task comment.
6. Approve or request changes; update task status via `paperclip`.
7. If a pattern of issues appears, flag it as a follow-up task for the CEO.

Never `mine`, `compress`, `prune`, `split`, or `repair` the palace — that's the CEO's job. If durable memory is missing, flag it in a `paperclip` comment.
