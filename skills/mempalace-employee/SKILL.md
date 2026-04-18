---
name: "mempalace-employee"
description: >
  Memory-palace skill for employee/executor agents (engineers, QA, reviewers,
  designers, marketers, assistants). Read-only surface over the shared
  mempalace-rs store: wake up with L0+L1 context and search the palace for
  facts before acting. Employees never mine, compress, prune, repair, split, or
  init — that is orchestrator territory.
slug: "mempalace-employee"
---

# MemPalace — Employee

You are an executor. Your job is to deliver on assigned tasks. The palace is
read-only for you — the orchestrator owns ingestion and curation. Use the
palace to orient yourself and recover context that predates this heartbeat.

All commands are invoked via the `mempalace-rs` CLI. Run them through `Bash`.
Point at the palace with `-p <PATH>` if the operator has configured one.

---

## Cycle discipline

At the top of every heartbeat, in this order:

1. **`wakeup`** — pull L0+L1 context (~600–900 tokens) so you resume with the
   palace's current frame of mind. Scope with `--wing` if you know your domain.
   ```sh
   mempalace-rs wakeup
   mempalace-rs wakeup --wing <your-wing>
   ```

2. **`search`** — before you ask another agent or the operator, search the
   palace. Use exact keywords. Narrow with `--wing` / `--room` and widen
   `--results` when you need more signal.
   ```sh
   mempalace-rs search "<query>"
   mempalace-rs search "<query>" --wing <wing> --room <room>
   mempalace-rs search "<query>" --results 10
   ```

3. **Act.** With palace context in hand, execute the assigned task via your
   normal tools (`paperclip`, code tools, etc.).

---

## Optional

- **`instructions`** — if you are unsure how to phrase a memory query or when
  to call `search`, read the canonical system prompts:
  ```sh
  mempalace-rs instructions
  ```

---

## Not allowed

You are an employee. Do **not** run:

- `mine` — ingestion is the orchestrator's job.
- `compress`, `prune`, `repair`, `split` — curation is the orchestrator's job.
- `init` — the palace is already initialized. Re-running destroys rooms.

If you think the palace is missing information, **surface it to the
orchestrator through `paperclip`** (comment or task). Do not try to fix the
palace yourself.

---

## Command matrix

| Command        | Employee |
|----------------|:--------:|
| `search`       | YES      |
| `wakeup`       | YES      |
| `instructions` | OPTIONAL |
| `mine`         | NO       |
| `compress`     | NO       |
| `prune`        | NO       |
| `repair`       | NO       |
| `split`        | NO       |
| `init`         | NO       |

---

## Rules

- **Wakeup first, then search, then act.** No exceptions.
- **Exact keywords** beat flowery phrasing. The palace is a temporal knowledge
  graph over text — say the noun.
- **Never mutate.** If `search` returns stale or missing data, report it
  upstream; do not try to `mine` or `prune` your way out.
- **Respect the wing.** If the task is scoped to a wing, scope your queries
  there first before widening.
