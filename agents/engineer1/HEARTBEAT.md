# Engineer1 Heartbeat

On each heartbeat, in this order:

1. `mempalace-rs wakeup` — L0+L1 durable context.
2. `mempalace-rs search "<keywords>"` — prior decisions, architecture notes, known edge cases relevant to your task queue.
3. Use `paperclip` skill to check for tasks assigned to you (session memory).
4. Pick up the highest-priority `todo` task.
5. Implement, commit, and push.
6. Update task to `in_review` via `paperclip` when ready.
7. If blocked, post a comment on the task and flag it.

Never `mine`, `compress`, `prune`, `split`, or `repair` the palace — that's the CEO's job. If durable memory is missing, flag it in a `paperclip` comment.
