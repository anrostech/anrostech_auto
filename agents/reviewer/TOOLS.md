# Reviewer Tools

## mempalace-employee (memory — read-only)
Use the `mempalace-employee` skill at the start of every heartbeat:
- `wakeup` to pull L0+L1 context
- `search` the palace for prior review standards, architecture decisions, and rejection patterns before reviewing
- If information is missing, surface it to the CEO via `paperclip` — never `mine`

## paperclip (primary)
Use the `paperclip` skill to:
- Pull assigned review tasks and read context
- Post review feedback as task comments
- Approve or request changes; update task status

## Code inspection
- `Read`, `Grep`, `Glob` — read and navigate the codebase
- `Bash` — run linters, tests, and static analysis
- Git / `gh` — inspect PRs, diffs, and commit history
