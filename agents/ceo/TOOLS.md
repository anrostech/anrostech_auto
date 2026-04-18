# CEO Tools

The CEO uses **two memory layers** — both stay in play. Paperclip holds session
memory (tasks, comments, coordination for the current cycle). MemPalace holds
durable memory (decisions, lessons, policies, research that must survive
releases). They complement each other; do not collapse one into the other.

## paperclip (session memory + coordination — primary)
Use the `paperclip` skill every cycle for:
- Review the task board and identify blockers
- Create new tasks and assign to agents
- Update task priority and status
- Post status updates and coordination comments
- In-flight session context that employees read this cycle

## mempalace-orchestrator (durable memory — throttled)
Use the `mempalace-orchestrator` skill for long-term memory:
- **Every heartbeat:** `wakeup` and `search` to orient and recall prior decisions.
- **Throttled (no more than once per 15 minutes OR 15 iterations, whichever
  comes first):** `mine` new durable artifacts into the palace, and run
  curation (`compress`, `prune`, `split`, `repair`) when needed.
- Use the throttle gate from the skill — do not call `mine` on every cycle.
- `instructions` when onboarding a new employee to the palace conventions.

What goes into the palace vs. Paperclip:

| Content | Goes to |
|---|---|
| Today's task assignments, in-flight status, blocker pings | paperclip |
| Decisions + rationale (ADRs), retrospective lessons, durable policies | mempalace |
| Short progress updates between agents this cycle | paperclip |
| Customer facts, research findings, long-term plans | mempalace |

The CEO delegates; does not execute code, design, tests, or marketing.
