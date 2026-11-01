#!/usr/bin/env bash
# Measure what agent sessions cost, from their transcripts. Usage:
#   script/session-tokens.sh TRANSCRIPT.jsonl...
# A transcript is the JSONL file Claude Code writes per session (a subagent's
# lives under ~/.claude/projects/<project>/<session>/subagents/). Prints one
# line per file and a total: assistant turns, cache reads, cache writes,
# uncached input, output, and peak context. Cache reads dominate: every turn
# re-reads the whole context, so cost grows with turns times context size.
# A session's "subagent tokens" figure is roughly its peak context, not this.
# A transcript writes one line per content block, each repeating its API
# call's usage, so lines are grouped by message id and the last one counted.
set -euo pipefail
[ "$#" -gt 0 ] || { echo "usage: $0 TRANSCRIPT.jsonl..." >&2; exit 1; }
for f in "$@"; do
  jq -rn --arg f "$(basename "$f")" '
    [inputs | select(.type == "assistant" and .message.usage != null)]
    | group_by(.message.id // .uuid) | map(.[-1].message.usage)
    | { turns: length,
        read: (map(.cache_read_input_tokens // 0) | add // 0),
        write: (map(.cache_creation_input_tokens // 0) | add // 0),
        input: (map(.input_tokens // 0) | add // 0),
        output: (map(.output_tokens // 0) | add // 0),
        peak: (map((.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.input_tokens // 0)) | max // 0) }
    | [$f, .turns, .read, .write, .input, .output, .peak] | @tsv' "$f"
done | awk -F'\t' '
  BEGIN { printf "%-40s %6s %10s %9s %7s %8s %7s\n", "file", "turns", "read", "write", "input", "output", "peak" }
  { printf "%-40s %6d %9.1fM %8.2fM %6.0fk %7.0fk %6.0fk\n", $1, $2, $3/1e6, $4/1e6, $5/1e3, $6/1e3, $7/1e3
    t += $2; r += $3; w += $4; i += $5; o += $6 }
  END { printf "%-40s %6d %9.1fM %8.2fM %6.0fk %7.0fk\n", "total", t, r/1e6, w/1e6, i/1e3, o/1e3 }'
