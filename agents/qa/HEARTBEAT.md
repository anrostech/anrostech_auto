# QA Heartbeat

On each heartbeat, in this order:

1. `mempalace-rs wakeup` — L0+L1 durable context.
2. `mempalace-rs search "<keywords>"` — prior bugs, regression patterns, known edge cases relevant to today's review queue.
3. Use `paperclip` skill to find tasks in `in_review` status (session memory).
4. Test each item — cover edge cases, not just the happy path.
5. Post test results and any bug details as task comments.
6. Update task: `done` if passed, back to `todo` with reproduction steps if failed.
7. Confirm fixes before marking blocked tasks resolved.

Never `mine`, `compress`, `prune`, `split`, or `repair` the palace — that's the CEO's job. If durable memory is missing, flag it in a `paperclip` comment.
