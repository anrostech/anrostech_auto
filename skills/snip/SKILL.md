---
name: "snip"
slug: "snip"
description: >
  Native Paperclip skill for capturing, summarizing, indexing, and retrieving
  reusable task outcomes per role — independent of plugins or executor-specific
  tooling. Every agent (CEO, engineer, QA, designer, marketer, reviewer,
  assistant, …) uses the same `snip.sh` CLI via Bash to build a durable,
  searchable log of what worked, what reproduced, and what should be reused
  next heartbeat.
triggers:
  - "capture this outcome as a snip"
  - "snip that"
  - "what did we do last time for …"
  - "recall prior snips on …"
  - "digest my recent snips"
---

# Snip — reusable task outcomes, per role, per company

Snip is a thin, executor-agnostic layer on top of the `snip` CLI
(github.com/anrostech/snip) + markdown files + a JSONL index. Its job is to
turn the end of a task into a **reusable outcome** that any future agent in
this company can find with a keyword search.

- **Native** — lives as a skill inside the company repo. No plugin install,
  no adapter glue, no runtime dependency beyond Bash.
- **Per role** — every agent role has its own namespaced directory, so the
  engineer's playbook does not drown in the marketer's snips.
- **Per company** — each company in `companies/<slug>/` gets its own snip
  store under `companies/<slug>/snips/`.
- **Portable** — the store is plain markdown + JSONL; any executor (Claude,
  Cursor, Gemini, Kilo, Antigravity, Copilot) can read and write it with
  Bash alone.

## When to use

At the **end** of any non-trivial task (a PR merged, a bug reproduced, a
design pattern chosen, a marketing variant that won, a customer answer that
reusable-ized an FAQ). Capture the outcome once, and every future heartbeat
can `search` the snip store before asking again.

At the **start** of a task, `search` or `digest` first. If a past snip
already answers the question, reuse it and skip the wheel-reinvention.

## Entry point

All commands route through one script — invoke it via Bash:

```sh
bash skills/snip/scripts/snip.sh <subcommand> [flags]
```

The script resolves the company dir from `$PAPERCLIP_COMPANY_DIR`, falls
back to `$COMPANY_DIR`, then walks up from `$PWD` looking for a dir that
contains both `COMPANY.md` and `skills/`. Pass `--company-dir <path>` to
override.

## Cycle discipline

### At the start of a task

```sh
# One-line digest of the last 10 outcomes for your role:
bash skills/snip/scripts/snip.sh digest --role engineer --limit 10

# Keyword search across all roles:
bash skills/snip/scripts/snip.sh search "stripe webhook retry"

# Scope search to a single role:
bash skills/snip/scripts/snip.sh search --role qa "flaky login test"
```

### At the end of a task

```sh
# Capture from a here-doc (body on stdin):
bash skills/snip/scripts/snip.sh capture \
    --role engineer \
    --title "Fixed Stripe webhook 409 on retry" \
    --task PAPERCLIP-482 \
    --project anrostech \
    --outcome success \
    --tags "stripe,webhook,idempotency" <<'EOF'
## Problem
Stripe retried the `payment_intent.succeeded` webhook and our handler threw
409 because the idempotency key was re-used against a finalised order.

## Fix
Moved the idempotency check above the order-finalise branch and added a
`SELECT ... FOR UPDATE` on the orders row.

## Reusable pattern
When Stripe retries, treat the retry as a lookup, not a write. Any write
that would flip state must be wrapped in row-level locking keyed by the
event id.
EOF
```

The script returns the snip id and its relative path. That id is the handle
for `get`, and it is stable across machines.

### Other commands

```sh
# List the last 20 snips newest-first (tab-separated):
bash skills/snip/scripts/snip.sh list --limit 20
bash skills/snip/scripts/snip.sh list --role marketer --tag launch

# Print a single snip by id:
bash skills/snip/scripts/snip.sh get <id>

# Rebuild the JSONL index from on-disk markdown (after manual edits):
bash skills/snip/scripts/snip.sh index

# Passthrough to the underlying `snip` CLI for token-saving dashboards:
bash skills/snip/scripts/snip.sh gain
bash skills/snip/scripts/snip.sh gain --weekly
```

## Storage layout

```
<company>/snips/
  _index.jsonl                     # one JSON record per snip
  engineer/2026/04/a1b2c3d4e5.md   # per-role, year/month sharded
  qa/2026/04/f6a7b8c9d0.md
  ceo/2026/04/…
```

Each markdown file has YAML frontmatter with `id`, `role`, `title`, `task`,
`project`, `outcome`, `captured_at`, `tags`, `summary`. The body below the
frontmatter is whatever the agent wrote — problem, fix, reusable pattern,
diff, commands, decision log.

## Sync ownership

Snips are **git content** owned by the company repo, not Paperclip runtime
state. Commit them in the same scope as agent files:

```
manifest: capture snips from YYYY-MM-DD heartbeat

Co-Authored-By: Paperclip <noreply@paperclip.ing>
```

Do **not** commit the operator's global `snip` tracking DB
(`~/.local/share/snip/tracking.db`) — it is machine-local.

## Required tools

`bash`, `jq`, `ripgrep`, `sha256sum`, `date`. The `snip` CLI is optional
(only the `gain` subcommand needs it). All of these are standard on every
Paperclip executor.

## Not allowed

- Do **not** edit `_index.jsonl` by hand. Re-run `snip.sh index` if you
  change markdown files directly.
- Do **not** capture session chatter as snips — that belongs in Paperclip
  comments. Snips are for **durable, reusable outcomes** only.
- Do **not** cross-write another role's directory. Capture under your own
  role; link to other roles' snips by id in the body if needed.

## Role mapping

Pass `--role` as the agent's slug (lowercase, dashes). Examples by company:

| Company          | Roles                                                      |
|------------------|------------------------------------------------------------|
| `ATA`            | `ceo`, `engineer1`, `uiuxdesigner`, `marketer`, `qa`, `reviewer` |
| `mark_assistant` | `my-assistant`                                             |

New agents added later inherit the skill automatically — just pass their
slug as `--role` and the directory is created on first capture.
