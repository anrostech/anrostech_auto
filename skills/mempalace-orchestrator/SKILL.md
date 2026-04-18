---
name: "mempalace-orchestrator"
description: >
  Memory-palace skill for orchestrator agents (CEO / tier-1 / reportsTo: null).
  Gives the agent write-side control of the shared mempalace-rs store: waking
  up with L0+L1 context, searching the palace for the information it needs
  before delegating, and periodically (every 15 min or 15 iterations) mining
  new material, compressing drawers, deduplicating, repairing vector storage,
  splitting mega-files, and reading system prompts. Paperclip still holds
  session memory; mempalace holds durable long-term memory. Does NOT include
  `init` — the palace is already initialized by the operator.
slug: "mempalace-orchestrator"
---

# MemPalace — Orchestrator

You are the orchestrator (CEO / tier-1 agent). You think, plan, delegate — and
you own the palace's long-term memory. Employees read from the palace; you are
the one who writes, curates, and maintains it.

## Two memory layers — use both

| Layer | Tool | What it holds | Lifetime |
|-------|------|---------------|----------|
| **Session memory** | `paperclip` (tasks, comments, run logs) | In-flight coordination, running context for the current cycle, blockers, status, short updates between agents | Ephemeral — flushed on release / cycle reset |
| **Durable memory** | `mempalace-rs` (palace) | Decisions, lessons, plans, customer facts, company policy, research findings, retrospectives | Permanent — survives releases, available to every future heartbeat |

**Do not replace one with the other.** Session memory stays in Paperclip. Only
durable memory belongs in the palace.

All mempalace commands run through `Bash`. Point at the palace with `-p <PATH>`
if the operator configured one; otherwise the tool uses its default.

---

## Cycle discipline (every heartbeat)

1. **`wakeup`** — before anything else, pull L0+L1 context (~600–900 tokens).
   ```sh
   mempalace-rs wakeup
   mempalace-rs wakeup --wing <wing>
   ```

2. **`search`** — answer the real question before opening the task board. Use
   exact keywords. Scope with `--wing` / `--room` when you know the domain.
   ```sh
   mempalace-rs search "<query>"
   mempalace-rs search "<query>" --wing <wing> --room <room> --results 10
   ```

3. **Delegate via `paperclip`.** Once you have the facts, assign work to
   employees. Keep session notes in paperclip comments; employees will
   `search` / `wakeup` the palace themselves and report back.

---

## Throttled curation (NOT every heartbeat)

`mine`, `compress`, `prune`, `repair`, `split` are **write-side** operations.
They change the palace for every agent that reads it. Running them on every
cycle bloats the palace, thrashes the vector index, and burns orchestrator
time. **Throttle them.**

**Rule of thumb:** run curation **no more than once per 15 minutes OR once per
15 heartbeat iterations, whichever comes first.** Between passes, trust the
palace as-is.

### Throttle gate — run this before any mine/compress/prune/split/repair

```sh
# Skip curation unless both: ≥15 min since last pass AND ≥15 iters since last pass.
STAMP="${HOME}/.mempalace-last-curate"
NOW=$(date +%s)
LAST=$(cat "$STAMP" 2>/dev/null || echo 0)
AGE=$(( NOW - LAST ))
ITER_FILE="${HOME}/.mempalace-iters-since-curate"
ITERS=$(cat "$ITER_FILE" 2>/dev/null || echo 0)
ITERS=$(( ITERS + 1 ))
echo "$ITERS" > "$ITER_FILE"

if [ "$AGE" -lt 900 ] || [ "$ITERS" -lt 15 ]; then
  echo "skip curation: age=${AGE}s iters=${ITERS} (need ≥900s AND ≥15)"
  exit 0
fi

echo "$NOW" > "$STAMP"
echo 0 > "$ITER_FILE"
echo "proceeding with curation pass"
```

Only if the gate prints `proceeding with curation pass`, continue:

- **`mine`** — ingest durable artifacts into the palace. Tag with `--wing`
  (and `--agent <your-slug>` for authorship). `--dry-run` first on anything
  unfamiliar.
  ```sh
  mempalace-rs mine <DIR> --mode project --wing <wing> --agent <your-slug>
  mempalace-rs mine <DIR> --mode convos  --wing <wing> --limit 50 --dry-run
  ```

- **`split`** — if a transcript mega-file landed, break it up first:
  ```sh
  mempalace-rs split <DIR>
  ```

- **`compress`** — when drawers get heavy, compact with the AAAK dialect
  (~30× reduction). Optionally scope to one wing.
  ```sh
  mempalace-rs compress
  mempalace-rs compress --wing <wing>
  ```

- **`prune`** — semantic dedup / merge of near-duplicate memories. Always
  `--dry-run` first; tighten the threshold before going destructive.
  ```sh
  mempalace-rs prune --dry-run
  mempalace-rs prune --threshold 0.88
  mempalace-rs prune --wing <wing> --threshold 0.90
  ```

- **`repair`** — if vector search starts missing obvious hits, re-index from
  SQLite metadata.
  ```sh
  mempalace-rs repair
  ```

### What counts as durable enough to `mine`?

Only material that must survive the next release:

- Decisions and their rationale (ADR-shaped notes)
- Retrospective findings and lessons learned
- Customer / user facts that future cycles will need
- Policies, constraints, non-obvious conventions
- Long-form research output (not casual browsing notes)
- Project spec snapshots after a major change

If in doubt, it is session memory — leave it in `paperclip` and do not `mine`.

---

## Onboarding employees

When you spin up or retrain a subordinate, hand them the canonical system
prompts so their `search` / `wakeup` behavior is consistent with yours:

```sh
mempalace-rs instructions
```

---

## Command matrix (orchestrator ↔ employee)

| Command        | Orchestrator | Employee | Cadence (orchestrator) |
|----------------|:------------:|:--------:|------------------------|
| `wakeup`       | YES          | YES      | every heartbeat        |
| `search`       | YES          | YES      | every heartbeat, as needed |
| `instructions` | YES          | OPTIONAL | on employee onboarding |
| `mine`         | YES          | NO       | **throttled**: ≥15 min AND ≥15 iters |
| `split`        | YES          | NO       | before a throttled `mine` if needed |
| `compress`     | YES          | NO       | **throttled**; weekly scope |
| `prune`        | YES          | NO       | **throttled**; `--dry-run` first |
| `repair`       | YES          | NO       | only when search quality degrades |
| `init`         | NO *         | NO       | never                   |

\* `init` has already been run by the operator. Do not re-run it. If you believe
the palace is truly empty, stop and ask the operator — do not re-initialize.

---

## Rules

- **Two memory layers, both alive.** Paperclip holds session memory; the palace
  holds durable memory. Do not collapse one into the other.
- **Throttle curation.** No `mine` / `compress` / `prune` / `split` / `repair`
  on every heartbeat. Run only when ≥15 minutes AND ≥15 iterations have passed
  since the last pass. Use the gate snippet above.
- **Never execute work yourself.** You delegate via `paperclip`. The palace is
  your journal and plan, not your to-do list.
- **Never run `init`.** The palace exists. Re-initializing destroys rooms.
- **Mutate deliberately.** `mine`, `compress`, `prune`, `repair`, `split` change
  the palace for every agent that reads it. Run `--dry-run` whenever available
  before committing.
- **Tag on ingest.** Always pass `--wing` (and `--agent <your-slug>` for
  authorship) so later scoped searches work.
- **Search first, write second.** If you cannot find a fact, search the palace
  before asking the operator or another agent.
- **Report what changed.** After any curation pass, post a short note through
  `paperclip` so employees know the palace shape shifted — that note is
  coordination, not memory; the durable record is already in the palace.
