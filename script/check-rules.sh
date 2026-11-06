#!/usr/bin/env bash
# Compare the comprehensive rules Wizards publishes with docs/rules.txt and,
# when their effective dates differ, open an issue unless an open one already
# has the same title. Fails on a fetch or parse failure rather than passing
# silently. Needs curl, grep, GNU date and an authenticated gh.
# Usage:
#   script/check-rules.sh          # open the issue when the dates differ
#   script/check-rules.sh --dry-run
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

page_url=https://magic.wizards.com/en/rules
agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

page=$(curl --fail --silent --show-error --location --user-agent "$agent" "$page_url")

# The page links the text file by date, as MagicCompRules YYYYMMDD.txt (the
# name holds a space, sometimes encoded); take the newest linked.
published=$(grep -oE 'MagicCompRules(%20| )[0-9]{8}\.txt' <<<"$page" |
  grep -oE '[0-9]{8}' | sort -u | tail -n 1 || true)
if [[ -z $published ]]; then
  echo "no MagicCompRules link found on $page_url" >&2
  exit 1
fi
published=$(date --utc --date "$published" +%F)

ours=$(grep -m 1 -oP '^These rules are effective as of \K[A-Z][a-z]+ [0-9]{1,2}, [0-9]{4}(?=\.)' docs/rules.txt || true)
if [[ -z $ours ]]; then
  echo "no effective date found in docs/rules.txt" >&2
  exit 1
fi
ours=$(date --utc --date "$ours" +%F)

echo "published: $published; docs/rules.txt: $ours"
if [[ $published == "$ours" ]]; then
  exit 0
fi

title="Comprehensive rules updated, effective $published"
if [[ ${1:-} == --dry-run ]]; then
  echo "would open: $title"
  exit 0
fi
if gh issue list --state open --limit 1000 --json title --jq '.[].title' |
  grep -qxF "$title"; then
  echo "already open: $title"
  exit 0
fi
gh issue create --title "$title" --body "$page_url links rules effective $published; \`docs/rules.txt\` is effective $ours."
