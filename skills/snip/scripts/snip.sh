#!/usr/bin/env bash
# snip.sh — native Snip skill for Paperclip companies.
#
# Capture, summarize, index, and retrieve reusable task outcomes per role.
# Independent of plugins and executor-specific tooling: only needs bash,
# sha256sum, date, ripgrep, jq, and (optionally) the snip CLI for output
# filtering.
#
# Layout (resolved from --company-dir or PAPERCLIP_COMPANY_DIR):
#   <company>/snips/
#     _index.jsonl            # one JSON record per snip (search index)
#     <role>/
#       YYYY/MM/<id>.md       # a single reusable task outcome
#
# Subcommands:
#   capture      write a new snip from stdin or --body
#   list         list recent snips (optionally filtered by role/tag/task)
#   search       ripgrep body + metadata search
#   get          print a single snip by id
#   digest       compact summary of the last N snips for a role
#   index        rebuild _index.jsonl from markdown files
#   gain         passthrough to the underlying `snip gain` dashboard
#   help         print usage
#
# The id is a short sha of role+timestamp+title; collision risk negligible.
set -euo pipefail

SNIP_SCRIPT_VERSION="1.0.0"

# ---------- helpers ----------

die() { echo "snip: $*" >&2; exit 1; }

log() { [[ "${SNIP_QUIET:-0}" = "1" ]] || echo "snip: $*" >&2; }

usage() {
  sed -n '2,30p' "$0"
}

# Resolve the company directory once per invocation.
resolve_company_dir() {
  if [[ -n "${COMPANY_DIR:-}" ]]; then
    printf '%s' "$COMPANY_DIR"; return
  fi
  if [[ -n "${PAPERCLIP_COMPANY_DIR:-}" ]]; then
    printf '%s' "$PAPERCLIP_COMPANY_DIR"; return
  fi
  # Climb from $PWD looking for a COMPANY.md beside a skills/ dir.
  local d="$PWD"
  while [[ "$d" != "/" ]]; do
    if [[ -f "$d/COMPANY.md" && -d "$d/skills" ]]; then
      printf '%s' "$d"; return
    fi
    d="$(dirname "$d")"
  done
  die "cannot resolve company dir — pass --company-dir or set PAPERCLIP_COMPANY_DIR"
}

slugify() {
  # lowercase, strip non-alphanum, collapse dashes
  tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

short_hash() {
  sha256sum | cut -c1-10
}

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"
}

# ---------- capture ----------
# Write a new snip. Body from stdin unless --body is passed.
cmd_capture() {
  local role="" title="" task_id="" project="" outcome="success"
  local tags_csv="" body="" use_stdin=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --role) role="$2"; shift 2;;
      --title) title="$2"; shift 2;;
      --task) task_id="$2"; shift 2;;
      --project) project="$2"; shift 2;;
      --outcome) outcome="$2"; shift 2;;
      --tags) tags_csv="$2"; shift 2;;
      --body) body="$2"; use_stdin=0; shift 2;;
      --company-dir) COMPANY_DIR="$2"; shift 2;;
      -h|--help) usage; return 0;;
      *) die "capture: unknown flag $1";;
    esac
  done

  [[ -n "$role" ]]  || die "capture: --role is required"
  [[ -n "$title" ]] || die "capture: --title is required"

  require_tool sha256sum
  require_tool jq

  local company_dir; company_dir="$(resolve_company_dir)"
  local role_slug; role_slug="$(printf '%s' "$role" | slugify)"
  local ts; ts="$(iso_now)"
  local ym; ym="$(date -u +%Y/%m)"

  if [[ $use_stdin -eq 1 ]]; then
    body="$(cat)"
  fi
  [[ -n "$body" ]] || die "capture: body is empty (pipe content in or pass --body)"

  local id_seed="${role_slug}|${ts}|${title}|${task_id}"
  local id; id="$(printf '%s' "$id_seed" | short_hash)"

  local out_dir="$company_dir/snips/$role_slug/$ym"
  mkdir -p "$out_dir"
  local out_file="$out_dir/$id.md"

  # Tags array as JSON for frontmatter-friendly storage.
  local tags_json="[]"
  if [[ -n "$tags_csv" ]]; then
    tags_json="$(printf '%s' "$tags_csv" \
      | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' \
      | jq -R . | jq -cs .)"
  fi

  # Compact summary: first paragraph, capped at 400 chars.
  local summary
  summary="$(printf '%s\n' "$body" | awk 'BEGIN{RS=""} {print; exit}' | head -c 400)"

  {
    printf -- '---\n'
    printf 'id: %s\n' "$id"
    printf 'role: %s\n' "$role_slug"
    printf 'title: %s\n' "$(jq -Rn --arg s "$title" '$s' )"
    printf 'task: %s\n' "${task_id:-\"\"}"
    printf 'project: %s\n' "${project:-\"\"}"
    printf 'outcome: %s\n' "$outcome"
    printf 'captured_at: %s\n' "$ts"
    printf 'tags: %s\n' "$tags_json"
    printf 'summary: %s\n' "$(jq -Rn --arg s "$summary" '$s')"
    printf -- '---\n\n'
    printf '# %s\n\n' "$title"
    printf '%s\n' "$body"
  } > "$out_file"

  # Append index entry.
  local idx="$company_dir/snips/_index.jsonl"
  local rel="${out_file#"$company_dir/"}"
  jq -cn \
    --arg id "$id" \
    --arg role "$role_slug" \
    --arg title "$title" \
    --arg task "$task_id" \
    --arg project "$project" \
    --arg outcome "$outcome" \
    --arg captured_at "$ts" \
    --argjson tags "$tags_json" \
    --arg summary "$summary" \
    --arg path "$rel" \
    '{id:$id, role:$role, title:$title, task:$task, project:$project, outcome:$outcome, captured_at:$captured_at, tags:$tags, summary:$summary, path:$path}' \
    >> "$idx"

  echo "$id  $rel"
}

# ---------- list ----------
cmd_list() {
  local role="" tag="" task_id="" limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --role) role="$(printf '%s' "$2" | slugify)"; shift 2;;
      --tag) tag="$2"; shift 2;;
      --task) task_id="$2"; shift 2;;
      --limit) limit="$2"; shift 2;;
      --company-dir) COMPANY_DIR="$2"; shift 2;;
      -h|--help) usage; return 0;;
      *) die "list: unknown flag $1";;
    esac
  done

  require_tool jq
  local company_dir; company_dir="$(resolve_company_dir)"
  local idx="$company_dir/snips/_index.jsonl"
  [[ -f "$idx" ]] || { log "no snips yet"; return 0; }

  local filter='.'
  [[ -n "$role" ]]    && filter="$filter | select(.role==\"$role\")"
  [[ -n "$task_id" ]] && filter="$filter | select(.task==\"$task_id\")"
  [[ -n "$tag" ]]     && filter="$filter | select(.tags | index(\"$tag\"))"

  # Newest first; tab-separated rows.
  tac "$idx" \
    | jq -r "$filter | [.captured_at, .role, .id, .outcome, .title] | @tsv" \
    | head -n "$limit"
}

# ---------- search ----------
cmd_search() {
  local query="" role="" limit=10 context=2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --role) role="$(printf '%s' "$2" | slugify)"; shift 2;;
      --limit) limit="$2"; shift 2;;
      --context) context="$2"; shift 2;;
      --company-dir) COMPANY_DIR="$2"; shift 2;;
      -h|--help) usage; return 0;;
      --) shift; query="$*"; break;;
      -*) die "search: unknown flag $1";;
      *)
        if [[ -z "$query" ]]; then query="$1"; else query="$query $1"; fi
        shift;;
    esac
  done

  [[ -n "$query" ]] || die "search: need a query string"
  require_tool rg

  local company_dir; company_dir="$(resolve_company_dir)"
  local root="$company_dir/snips"
  [[ -d "$root" ]] || { log "no snips yet"; return 0; }
  if [[ -n "$role" ]]; then root="$root/$role"; fi
  [[ -d "$root" ]] || { log "no snips for role: $role"; return 0; }

  rg --no-heading --line-number --smart-case \
     --color=never --max-count 3 --context "$context" \
     --glob '*.md' "$query" "$root" 2>/dev/null \
    | head -n "$((limit * (context * 2 + 3)))"
}

# ---------- get ----------
cmd_get() {
  local id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --company-dir) COMPANY_DIR="$2"; shift 2;;
      -h|--help) usage; return 0;;
      *) id="$1"; shift;;
    esac
  done
  [[ -n "$id" ]] || die "get: need an id"

  local company_dir; company_dir="$(resolve_company_dir)"
  local match
  match="$(find "$company_dir/snips" -name "$id.md" 2>/dev/null | head -n1)"
  [[ -n "$match" ]] || die "get: no snip with id $id"
  cat "$match"
}

# ---------- digest ----------
# Produce a compact summary of the last N snips for a role, run through
# `snip` to strip noise and save tokens if the CLI is installed.
cmd_digest() {
  local role="" limit=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --role) role="$(printf '%s' "$2" | slugify)"; shift 2;;
      --limit) limit="$2"; shift 2;;
      --company-dir) COMPANY_DIR="$2"; shift 2;;
      -h|--help) usage; return 0;;
      *) die "digest: unknown flag $1";;
    esac
  done
  [[ -n "$role" ]] || die "digest: --role is required"
  require_tool jq

  local company_dir; company_dir="$(resolve_company_dir)"
  local idx="$company_dir/snips/_index.jsonl"
  [[ -f "$idx" ]] || { log "no snips yet"; return 0; }

  local rendered
  rendered="$(tac "$idx" \
    | jq -r --arg role "$role" \
        'select(.role==$role)
         | "- [\(.captured_at)] \(.outcome | ascii_upcase) — \(.title)\n    id: \(.id)\n    tags: \(.tags | join(","))\n    summary: \(.summary)"' \
    | head -n "$((limit * 4))")"

  if [[ -z "$rendered" ]]; then
    echo "(no snips for role: $role)"
    return 0
  fi

  printf '# Snip digest — role: %s (last %s)\n\n' "$role" "$limit"
  printf '%s\n' "$rendered"
}

# ---------- index (rebuild) ----------
cmd_index() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --company-dir) COMPANY_DIR="$2"; shift 2;;
      -h|--help) usage; return 0;;
      *) die "index: unknown flag $1";;
    esac
  done
  require_tool jq
  local company_dir; company_dir="$(resolve_company_dir)"
  local root="$company_dir/snips"
  [[ -d "$root" ]] || { mkdir -p "$root"; }

  local idx="$root/_index.jsonl"
  : > "$idx"
  local count=0

  while IFS= read -r -d '' f; do
    # Parse frontmatter: read until the closing '---'.
    local fm body_start
    fm="$(awk '/^---$/{c++; if(c==2){exit} next} c==1{print}' "$f")"
    [[ -n "$fm" ]] || continue

    # Extract raw values (tags is JSON array, others are scalars).
    local id role title task project outcome captured_at tags summary
    id=$(         awk -F': ' '/^id: /{print $2; exit}'          <<<"$fm")
    role=$(       awk -F': ' '/^role: /{print $2; exit}'        <<<"$fm")
    title=$(      awk -F': ' '/^title: /{sub(/^title: /,""); print; exit}' <<<"$fm")
    task=$(       awk -F': ' '/^task: /{sub(/^task: /,""); print; exit}'   <<<"$fm")
    project=$(    awk -F': ' '/^project: /{sub(/^project: /,""); print; exit}' <<<"$fm")
    outcome=$(    awk -F': ' '/^outcome: /{print $2; exit}'     <<<"$fm")
    captured_at=$(awk -F': ' '/^captured_at: /{print $2; exit}' <<<"$fm")
    tags=$(       awk -F': ' '/^tags: /{sub(/^tags: /,""); print; exit}'   <<<"$fm")
    summary=$(    awk -F': ' '/^summary: /{sub(/^summary: /,""); print; exit}' <<<"$fm")

    # title/summary/task/project were written as JSON-quoted strings; unwrap.
    title=$(jq -r '.' <<<"$title" 2>/dev/null || printf '%s' "$title")
    summary=$(jq -r '.' <<<"$summary" 2>/dev/null || printf '%s' "$summary")
    task=$(jq -r '.' <<<"$task" 2>/dev/null || printf '%s' "$task")
    project=$(jq -r '.' <<<"$project" 2>/dev/null || printf '%s' "$project")
    [[ -z "$tags" ]] && tags="[]"

    local rel="${f#"$company_dir/"}"
    jq -cn \
      --arg id "$id" --arg role "$role" --arg title "$title" \
      --arg task "$task" --arg project "$project" --arg outcome "$outcome" \
      --arg captured_at "$captured_at" --argjson tags "$tags" \
      --arg summary "$summary" --arg path "$rel" \
      '{id:$id, role:$role, title:$title, task:$task, project:$project, outcome:$outcome, captured_at:$captured_at, tags:$tags, summary:$summary, path:$path}' \
      >> "$idx"
    count=$((count + 1))
  done < <(find "$root" -type f -name '*.md' -print0)

  echo "indexed $count snips → $idx"
}

# ---------- gain (passthrough) ----------
cmd_gain() {
  if command -v snip >/dev/null 2>&1; then
    snip gain "$@"
  else
    die "snip CLI not found — install from github.com/anrostech/snip"
  fi
}

# ---------- dispatch ----------
main() {
  local sub="${1:-help}"; shift || true
  case "$sub" in
    capture)  cmd_capture  "$@";;
    list)     cmd_list     "$@";;
    search)   cmd_search   "$@";;
    get)      cmd_get      "$@";;
    digest)   cmd_digest   "$@";;
    index)    cmd_index    "$@";;
    gain)     cmd_gain     "$@";;
    help|-h|--help) usage;;
    version|--version) echo "snip-skill $SNIP_SCRIPT_VERSION";;
    *) die "unknown subcommand: $sub (try: help)";;
  esac
}

main "$@"
