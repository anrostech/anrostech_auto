# QA Tools

## mempalace-employee (memory — read-only)
Use the `mempalace-employee` skill at the start of every heartbeat:
- `wakeup` to pull L0+L1 context
- `search` the palace for prior bugs, test plans, and known edge cases before testing
- If information is missing, surface it to the CEO via `paperclip` — never `mine`

## paperclip (primary)
Use the `paperclip` skill to:
- Pull tasks in `in_review` status for testing
- Post test results and bug reports as task comments
- Update task status: `done` (pass) or `todo` (fail with steps)

## Testing & inspection
- `Bash` — run test suites, scripts, and health checks
- `Read`, `Grep` — inspect code, logs, and configs for issues
- `WebFetch` — test live endpoints and page behavior
