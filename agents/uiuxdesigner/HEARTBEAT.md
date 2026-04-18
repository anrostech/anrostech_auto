# UIUXDesigner Heartbeat

On each heartbeat, in this order:

1. `mempalace-rs wakeup` — L0+L1 durable context.
2. `mempalace-rs search "<keywords>"` — design system, prior UX research, accessibility standards relevant to today's design queue.
3. Use `paperclip` skill to check for assigned design tasks (session memory).
4. Pick up the highest-priority task and deliver design output.
5. Post specs or notes as a task comment; notify Engineer1 if handoff-ready.
6. Update task status via `paperclip`.
7. Flag blockers early — don't wait for the next cycle.

Never `mine`, `compress`, `prune`, `split`, or `repair` the palace — that's the CEO's job. If durable memory is missing, flag it in a `paperclip` comment.
